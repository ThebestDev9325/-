const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {deleteAccountData} = require("./account_deletion");
const {isValidSharedPost} = require("./content_moderation");
const {
  legacyReportDocumentId,
  reportDocumentId,
} = require("./content_report_identity");

initializeApp();
const db = getFirestore();
const reportReasons = new Set([
  "harassment",
  "hate",
  "violence",
  "self_harm",
  "sexual",
  "personal_information",
  "illegal",
  "spam",
  "other",
  "legacy_unspecified",
]);
const reportDeadlineMilliseconds = 24 * 60 * 60 * 1000;

function validDocumentId(value) {
  return typeof value === "string" &&
    value.length > 0 &&
    value.length <= 128 &&
    !value.includes("/");
}

async function requireConnectedAccount(request) {
  const uid = request.auth.uid;
  const isKakaoAccount = uid.startsWith("kakao:") &&
    request.auth.token.provider === "kakao";
  if (isKakaoAccount) return;
  const user = await getAuth().getUser(uid);
  const hasAppleProvider = user.providerData.some(
      (provider) => provider.providerId === "apple.com",
  );
  if (!hasAppleProvider) {
    throw new HttpsError(
        "permission-denied",
        "공유하려면 카카오 또는 Apple 계정 연결이 필요합니다.",
    );
  }
}

async function kakaoUserId(accessToken) {
  if (typeof accessToken !== "string" || accessToken.length < 20) {
    throw new HttpsError("invalid-argument", "카카오 로그인 정보가 올바르지 않습니다.");
  }
  const response = await fetch("https://kapi.kakao.com/v1/user/access_token_info", {
    headers: {Authorization: `Bearer ${accessToken}`},
  });
  if (!response.ok) {
    throw new HttpsError("unauthenticated", "카카오 로그인이 만료되었거나 유효하지 않습니다.");
  }
  const kakao = await response.json();
  if (!kakao.id) {
    throw new HttpsError("unauthenticated", "카카오 사용자를 확인할 수 없습니다.");
  }
  return String(kakao.id);
}

exports.signInWithKakao = onCall({region: "asia-northeast3"}, async (request) => {
  const accessToken = request.data && request.data.accessToken;
  const uid = `kakao:${await kakaoUserId(accessToken)}`;
  const customToken = await getAuth().createCustomToken(uid, {provider: "kakao"});
  return {customToken};
});

exports.publishSharedRecord = onCall(
    {region: "asia-northeast3"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
      }
      await requireConnectedAccount(request);
      const recordId = request.data && request.data.recordId;
      if (!validDocumentId(recordId)) {
        throw new HttpsError(
            "invalid-argument",
            "공유할 마음 기록을 확인할 수 없습니다.",
        );
      }
      const uid = request.auth.uid;
      const recordRef = db.collection("users").doc(uid)
          .collection("records").doc(recordId);
      const postRef = db.collection("sharedPosts").doc(recordId);
      const suspensionRef = db.collection("moderationSuspensions").doc(uid);
      await db.runTransaction(async (transaction) => {
        const [record, existingPost, suspension] = await transaction.getAll(
            recordRef,
            postRef,
            suspensionRef,
        );
        if (suspension.exists) {
          throw new HttpsError(
              "permission-denied",
              "정지된 계정은 사연을 공유할 수 없습니다.",
          );
        }
        if (!record.exists) {
          throw new HttpsError("not-found", "공유할 마음 기록이 없습니다.");
        }
        if (existingPost.exists) {
          if (existingPost.data().ownerId !== uid) {
            throw new HttpsError(
                "already-exists",
                "같은 식별자의 공유 글이 이미 존재합니다.",
            );
          }
          transaction.update(recordRef, {shared: true});
          return;
        }
        const data = record.data();
        const post = {
          ownerId: uid,
          createdAt: data.createdAt,
          category: data.category,
          moodEmoji: data.moodEmoji,
          moodLabel: data.moodLabel,
          text: data.text,
          storyId: data.storyId,
          shared: true,
          reactions: [0, 0, 0],
          reactedBy: [],
          reportCount: 0,
        };
        if (!isValidSharedPost(post)) {
          throw new HttpsError(
              "invalid-argument",
              "공유할 수 없는 내용이 포함되어 있습니다.",
          );
        }
        transaction.set(postRef, post);
        transaction.update(recordRef, {shared: true});
      });
      return {published: true};
    },
);

exports.reportSharedPost = onCall({region: "asia-northeast3"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
  }
  const postId = request.data && request.data.postId;
  if (!validDocumentId(postId)) {
    throw new HttpsError("invalid-argument", "신고할 사연을 확인할 수 없습니다.");
  }
  const requestedReason = request.data && request.data.reason;
  const reason = requestedReason == null ? "legacy_unspecified" : requestedReason;
  if (!reportReasons.has(reason)) {
    throw new HttpsError("invalid-argument", "신고 사유가 올바르지 않습니다.");
  }
  const requestedDetail = request.data && request.data.detail;
  const detail = typeof requestedDetail === "string" ?
    requestedDetail.trim() : "";
  if (reason === "other" && (detail.length === 0 || detail.length > 300)) {
    throw new HttpsError(
        "invalid-argument",
        "신고 사유를 300자 이내로 입력해 주세요.",
    );
  }
  const expectedOwnerId = request.data && request.data.ownerId;
  if (expectedOwnerId != null && !validDocumentId(expectedOwnerId)) {
    throw new HttpsError(
        "invalid-argument",
        "신고 대상 사연의 소유자가 올바르지 않습니다.",
    );
  }
  const uid = request.auth.uid;
  const postRef = db.collection("sharedPosts").doc(postId);
  const suspensionRef = db.collection("moderationSuspensions").doc(uid);
  const now = Timestamp.now();
  const result = await db.runTransaction(async (transaction) => {
    const [snapshot, suspension] = await transaction.getAll(
        postRef,
        suspensionRef,
    );
    if (suspension.exists) {
      throw new HttpsError(
          "permission-denied",
          "정지된 계정은 신고할 수 없습니다.",
      );
    }
    if (!snapshot.exists) {
      return {
        reportCount: 5,
        removed: true,
        alreadyReported: false,
        recorded: false,
      };
    }
    const data = snapshot.data();
    const ownerId = data.ownerId;
    if (!validDocumentId(ownerId)) {
      throw new HttpsError(
          "failed-precondition",
          "신고 대상 사연의 소유자를 확인할 수 없습니다.",
      );
    }
    if (ownerId === uid) {
      throw new HttpsError("failed-precondition", "내 사연은 신고할 수 없습니다.");
    }
    if (expectedOwnerId != null && expectedOwnerId !== ownerId) {
      return {
        reportCount: Number(data.reportCount) || 0,
        removed: true,
        alreadyReported: false,
        recorded: false,
      };
    }
    const reportRef = db.collection("contentReports")
        .doc(reportDocumentId(postId, ownerId, uid));
    const legacyReportRef = db.collection("contentReports")
        .doc(legacyReportDocumentId(postId, uid));
    const [existingReport, legacyReport] = await transaction.getAll(
        reportRef,
        legacyReportRef,
    );
    const hasMatchingLegacyReport = legacyReport.exists &&
      legacyReport.data().ownerId === ownerId;
    if (existingReport.exists || hasMatchingLegacyReport) {
      return {
        reportCount: Number(data.reportCount) || 0,
        removed: false,
        alreadyReported: true,
        recorded: false,
      };
    }
    const legacyReporters = Array.isArray(data.reportedBy) ?
      data.reportedBy.filter((value) => typeof value === "string") :
      [];
    if (legacyReporters.includes(uid)) {
      transaction.create(reportRef, {
        postId,
        ownerId,
        reporterId: uid,
        reason: "legacy_unspecified",
        status: "pending",
        createdAt: now,
        deadlineAt: Timestamp.fromMillis(
            now.toMillis() + reportDeadlineMilliseconds,
        ),
        snapshot: {
          category: String(data.category || ""),
          text: String(data.text || "").slice(0, 2000),
          createdAt: data.createdAt || now,
        },
        migratedAt: now,
      });
      transaction.update(postRef, {
        reportedBy: legacyReporters.filter((reporterId) => reporterId !== uid),
      });
      return {
        reportCount: Number(data.reportCount) || legacyReporters.length,
        removed: false,
        alreadyReported: true,
        recorded: true,
      };
    }

    const reportCount = (Number(data.reportCount) || 0) + 1;
    transaction.create(reportRef, {
      postId,
      ownerId,
      reporterId: uid,
      reason,
      ...(detail ? {detail} : {}),
      status: "pending",
      createdAt: now,
      deadlineAt: Timestamp.fromMillis(
          now.toMillis() + reportDeadlineMilliseconds,
      ),
      snapshot: {
        category: String(data.category || ""),
        text: String(data.text || "").slice(0, 2000),
        createdAt: data.createdAt || now,
      },
    });
    transaction.update(postRef, {
      reportCount,
    });
    return {
      reportCount,
      removed: false,
      alreadyReported: false,
      recorded: true,
    };
  });
  if (result.recorded) {
    logger.warn("content_report_received", {
      postId,
      deadlineAt: now.toMillis() + reportDeadlineMilliseconds,
    });
  }
  return {
    reportCount: result.reportCount,
    removed: result.removed,
    alreadyReported: result.alreadyReported,
  };
});

exports.deleteKakaoAccount = onCall({region: "asia-northeast3"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
  }
  const accessToken = request.data && request.data.accessToken;
  const uid = request.auth.uid;
  const verifiedUid = `kakao:${await kakaoUserId(accessToken)}`;
  if (verifiedUid !== uid) {
    throw new HttpsError("permission-denied", "현재 로그인한 카카오 계정과 일치하지 않습니다.");
  }

  await deleteAccountData({
    database: db,
    authentication: getAuth(),
    uid,
  });
  return {deleted: true};
});

exports.deleteAppleAccount = onCall({region: "asia-northeast3"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
  }
  const uid = request.auth.uid;
  const user = await getAuth().getUser(uid);
  const hasAppleProvider = user.providerData.some(
      (provider) => provider.providerId === "apple.com",
  );
  if (!hasAppleProvider) {
    throw new HttpsError("permission-denied", "Apple 계정 연결을 확인할 수 없습니다.");
  }

  await deleteAccountData({
    database: db,
    authentication: getAuth(),
    uid,
  });
  return {deleted: true};
});
