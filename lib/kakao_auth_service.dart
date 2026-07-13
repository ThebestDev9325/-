import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuthService {
  KakaoAuthService._();
  static final instance = KakaoAuthService._();

  Future<UserCredential> signIn() async {
    final kakaoToken = await _loginWithKakao();
    return _signInToFirebase(kakaoToken.accessToken);
  }

  Future<void> deleteAccount() async {
    final kakaoToken = await _loginWithKakao();
    final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3')
        .httpsCallable('deleteKakaoAccount');
    await callable.call(<String, dynamic>{
      'accessToken': kakaoToken.accessToken,
    });
    try {
      await UserApi.instance.unlink();
    } catch (_) {
      // Firebase 탈퇴는 완료됐으므로 카카오 연결 해제 실패가 탈퇴를 되돌리지는 않는다.
    } finally {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<OAuthToken> _loginWithKakao() async {
    final OAuthToken kakaoToken;
    if (await isKakaoTalkInstalled()) {
      kakaoToken = await UserApi.instance.loginWithKakaoTalk();
    } else {
      kakaoToken = await UserApi.instance.loginWithKakaoAccount();
    }
    return kakaoToken;
  }

  Future<UserCredential> _signInToFirebase(String accessToken) async {
    final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3')
        .httpsCallable('signInWithKakao');
    final result = await callable.call(<String, dynamic>{
      'accessToken': accessToken,
    });
    final customToken = (result.data as Map)['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw StateError('Firebase 로그인 토큰을 받지 못했습니다.');
    }
    return FirebaseAuth.instance.signInWithCustomToken(customToken);
  }

  Future<void> unlink() async {
    try {
      await UserApi.instance.unlink();
    } finally {
      await FirebaseAuth.instance.signOut();
    }
  }
}
