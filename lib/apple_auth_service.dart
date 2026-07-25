import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppleAuthService {
  AppleAuthService._();

  static final instance = AppleAuthService._();

  Future<UserCredential> signIn() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      return currentUser.linkWithProvider(provider);
    }
    return FirebaseAuth.instance.signInWithProvider(provider);
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final credential = await user.reauthenticateWithProvider(
      AppleAuthProvider(),
    );
    // Ensure the callable receives an ID token carrying the fresh auth_time.
    await user.getIdToken(true);
    final authorizationCode = credential.additionalUserInfo?.authorizationCode;
    if (authorizationCode != null && authorizationCode.isNotEmpty) {
      try {
        await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(
          authorizationCode,
        );
      } catch (_) {
        // Apple 토큰 폐기가 실패해도 Firebase 계정과 서비스 데이터는 삭제한다.
      }
    }
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-northeast3',
    ).httpsCallable('deleteAppleAccount');
    await callable.call<void>();
    await FirebaseAuth.instance.signOut();
  }
}
