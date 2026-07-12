const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");

initializeApp();

exports.signInWithKakao = onCall({region: "asia-northeast3"}, async (request) => {
  const accessToken = request.data && request.data.accessToken;
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

  const uid = `kakao:${kakao.id}`;
  const customToken = await getAuth().createCustomToken(uid, {provider: "kakao"});
  return {customToken};
});
