const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {createHash} = require("node:crypto");
const {isValidSharedPost} = require("./content_moderation");

initializeApp();
const db = getFirestore();
const reportReasons = new Set([
  "harassment",
  "hate",
  "violence",
  "sexual",
  "personal_information",
  "illegal",
  "spam",
  "other",
  "legacy_unspecified",
]);
const reportLimitPerHour = 10;
const reportDeadlineMilliseconds = 24 * 60 * 60 * 1000;

function reportDocumentId(postId, reporterId) {
  const reporterHash = createHash("sha256").update(reporterId).digest("hex");
  return `${postId}_${reporterHash}`;
}

function reporterHash(reporterId) {
  return createHash("sha256").update(reporterId).digest("hex");
}

async function resetPrivateRecordSharing(transaction, ownerId, postId) {
  const recordRef = db.collection("users").doc(ownerId)
      .collection("records").doc(postId);
  const record = await transaction.get(recordRef);
  if (record.exists) transaction.update(recordRef, {shared: false});
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

exports.reportSharedPost = onCall({region: "asia-northeast3"}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
  }
  const postId = request.data && request.data.postId;
  if (typeof postId !== "string" ||
      postId.length === 0 ||
      postId.length > 128 ||
      postId.includes("/")) {
    throw new HttpsError("invalid-argument", "신고할 사연을 확인할 수 없습니다.");
  }
  const requestedReason = request.data && request.data.reason;
  const reason = requestedReason == null ? "legacy_unspecified" : requestedReason;
  if (!reportReasons.has(reason)) {
    throw new HttpsError("invalid-argument", "신고 사유가 올바르지 않습니다.");
  }
  const uid = request.auth.uid;
  const postRef = db.collection("sharedPosts").doc(postId);
  const reportRef = db.collection("contentReports")
      .doc(reportDocumentId(postId, uid));
  const rateLimitRef = db.collection("reportRateLimits").doc(uid);
  const now = Timestamp.now();
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(postRef);
    if (!snapshot.exists) {
      return {
        reportCount: 5,
        removed: true,
        alreadyReported: false,
        queued: false,
      };
    }
    const data = snapshot.data();
    if (data.ownerId === uid) {
      throw new HttpsError("failed-precondition", "내 사연은 신고할 수 없습니다.");
    }
    const existingReport = await transaction.get(reportRef);
    if (existingReport.exists) {
      return {
        reportCount: Number(data.reportCount) || 0,
        removed: false,
        alreadyReported: true,
        queued: false,
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
    if (reportCount >= 5) {
      await resetPrivateRecordSharing(
          transaction,
          String(data.ownerId),
          postId,
      );
    }
    transaction.create(reportRef, {
      postId,
      ownerId: String(data.ownerId),
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
    transaction.set(rateLimitRef, {
      windowStart: sameWindow ? currentWindowStart : now,
      count: currentCount + 1,
      updatedAt: now,
    });
    if (reportCount >= 5) {
      transaction.delete(postRef);
      return {
        reportCount,
        removed: true,
        alreadyReported: false,
        queued: true,
      };
    }
    transaction.update(postRef, {reportCount});
    return {
      reportCount,
      removed: false,
      alreadyReported: false,
      queued: true,
    };
  });
  if (result.queued) {
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

exports.moderateCreatedSharedPost = onDocumentCreated(
    {document: "sharedPosts/{postId}", region: "asia-northeast3"},
    async (event) => {
      const snapshot = event.data;
      if (!snapshot || isValidSharedPost(snapshot.data())) return;
      await db.runTransaction(async (transaction) => {
        const current = await transaction.get(snapshot.ref);
        if (!current.exists) return;
        const ownerId = current.data().ownerId;
        if (typeof ownerId === "string") {
          await resetPrivateRecordSharing(
              transaction,
              ownerId,
              event.params.postId,
          );
        }
        transaction.delete(snapshot.ref);
      });
      logger.error("invalid_shared_post_removed", {
        postId: event.params.postId,
      });
    },
);

exports.monitorPendingContentReports = onSchedule(
    {schedule: "every 60 minutes", region: "asia-northeast3"},
    async () => {
      const now = Timestamp.now();
      const approaching = Timestamp.fromMillis(
          now.toMillis() + 4 * 60 * 60 * 1000,
      );
      const reports = await db.collection("contentReports")
          .where("deadlineAt", "<=", approaching)
          .get();
      for (const report of reports.docs) {
        const data = report.data();
        if (data.status !== "pending" || !(data.deadlineAt instanceof Timestamp)) {
          continue;
        }
        const overdue = data.deadlineAt.toMillis() <= now.toMillis();
        logger.error(
            overdue ? "deadline_overdue" : "deadline_approaching",
            {
              reportId: report.id,
              postId: data.postId,
              deadlineAt: data.deadlineAt.toMillis(),
            },
        );
      }
    },
);

async function deleteAccountData(uid) {
  const userRef = db.collection("users").doc(uid);
  const userSnapshot = await userRef.get();
  const nickname = userSnapshot.data() && userSnapshot.data().nickname;
  const sharedSnapshot = await db.collection("sharedPosts")
      .where("ownerId", "==", uid).get();
  const writer = db.bulkWriter();
  for (const shared of sharedSnapshot.docs) writer.delete(shared.ref);
  if (typeof nickname === "string" && nickname.trim()) {
    const nicknameRef = db.collection("nicknames").doc(nickname.trim().toLowerCase());
    const nicknameSnapshot = await nicknameRef.get();
    if (nicknameSnapshot.data() && nicknameSnapshot.data().ownerId === uid) {
      writer.delete(nicknameRef);
    }
  }
  await writer.close();
  await db.recursiveDelete(userRef);
  await getAuth().deleteUser(uid);
}

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

  await deleteAccountData(uid);
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

  await deleteAccountData(uid);
  return {deleted: true};
});
