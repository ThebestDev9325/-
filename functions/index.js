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
  reportRequestDocumentId,
  reporterHash,
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
const reportLimitPerHour = 10;
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
      await db.runTransaction(async (transaction) => {
        const [record, existingPost] = await transaction.getAll(
            recordRef,
            postRef,
        );
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
  const expectedOwnerId = request.data && request.data.ownerId;
  if (expectedOwnerId != null && !validDocumentId(expectedOwnerId)) {
    throw new HttpsError(
        "invalid-argument",
        "신고 대상 사연의 소유자가 올바르지 않습니다.",
    );
  }
  const requestId = request.data && request.data.requestId;
  if (requestId != null &&
      (typeof requestId !== "string" ||
       !/^[0-9a-f]{32}$/.test(requestId))) {
    throw new HttpsError(
        "invalid-argument",
        "신고 요청 식별자가 올바르지 않습니다.",
    );
  }
  const uid = request.auth.uid;
  const postRef = db.collection("sharedPosts").doc(postId);
  const rateLimitRef = db.collection("reportRateLimits").doc(uid);
  const requestRef = requestId == null ?
    null :
    db.collection("contentReportRequests")
        .doc(reportRequestDocumentId(requestId));
  const now = Timestamp.now();
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(postRef);
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
    const references = [reportRef, legacyReportRef];
    if (requestRef != null) references.push(requestRef);
    const [existingReport, legacyReport, existingRequest] =
      await transaction.getAll(...references);
    if (existingRequest && existingRequest.exists) {
      const previousRequest = existingRequest.data();
      if (previousRequest.postId !== postId ||
          previousRequest.ownerId !== ownerId) {
        throw new HttpsError(
            "already-exists",
            "이미 다른 신고에 사용된 요청 식별자입니다.",
        );
      }
      return {
        reportCount: Number(data.reportCount) || 0,
        removed: false,
        alreadyReported: true,
        recorded: false,
      };
    }
    const recordRequest = (targetReportRef) => {
      if (requestRef == null) return;
      transaction.create(requestRef, {
        postId,
        ownerId,
        reportId: targetReportRef.id,
        reporterId: uid,
        createdAt: now,
      });
    };
    const hasMatchingLegacyReport = legacyReport.exists &&
      legacyReport.data().ownerId === ownerId;
    if (existingReport.exists || hasMatchingLegacyReport) {
      recordRequest(existingReport.exists ? reportRef : legacyReportRef);
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
      recordRequest(reportRef);
      return {
        reportCount: Number(data.reportCount) || legacyReporters.length,
        removed: false,
        alreadyReported: true,
        recorded: true,
      };
    }
    const rateLimit = await transaction.get(rateLimitRef);
    const rateData = rateLimit.data();
    const currentWindowStart = rateData && rateData.windowStart;
    const sameWindow = currentWindowStart instanceof Timestamp &&
      now.toMillis() - currentWindowStart.toMillis() < 60 * 60 * 1000;
    const currentCount = sameWindow ? Number(rateData.count) || 0 : 0;
    if (currentCount >= reportLimitPerHour) {
      throw new HttpsError(
          "resource-exhausted",
          "신고 요청이 너무 많습니다. 잠시 후 다시 시도해주세요.",
      );
    }

    const reportCount = (Number(data.reportCount) || 0) + 1;
    transaction.create(reportRef, {
      postId,
      ownerId,
      reporterId: uid,
      reason,
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
    recordRequest(reportRef);
    transaction.set(rateLimitRef, {
      windowStart: sameWindow ? currentWindowStart : now,
      count: currentCount + 1,
      updatedAt: now,
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
      reporterHash: reporterHash(uid),
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
