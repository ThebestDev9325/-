const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

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
  if (typeof postId !== "string" || postId.length === 0) {
    throw new HttpsError("invalid-argument", "신고할 사연을 확인할 수 없습니다.");
  }
  const uid = request.auth.uid;
  const ref = db.collection("sharedPosts").doc(postId);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      return {reportCount: 5, removed: true, alreadyReported: false};
    }
    const data = snapshot.data();
    if (data.ownerId === uid) {
      throw new HttpsError("failed-precondition", "내 사연은 신고할 수 없습니다.");
    }
    const reportedBy = Array.isArray(data.reportedBy) ? data.reportedBy : [];
    if (reportedBy.includes(uid)) {
      return {
        reportCount: Number(data.reportCount) || reportedBy.length,
        removed: false,
        alreadyReported: true,
      };
    }
    const nextReportedBy = [...reportedBy, uid];
    const reportCount = nextReportedBy.length;
    if (reportCount >= 5) {
      transaction.delete(ref);
      return {reportCount, removed: true, alreadyReported: false};
    }
    transaction.update(ref, {reportedBy: nextReportedBy, reportCount});
    return {reportCount, removed: false, alreadyReported: false};
  });
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
  return {deleted: true};
});
