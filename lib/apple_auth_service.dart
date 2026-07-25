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
    final authorizationCode = credential.additionalUserInfo?.authorizationCode;
    if (authorizationCode == null || authorizationCode.isEmpty) {
      throw StateError('Apple 계정 확인 코드를 받지 못했습니다.');
    }

    await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(
      authorizationCode,
    );
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-northeast3',
    ).httpsCallable('deleteAppleAccount');
    await callable.call<void>();
    await FirebaseAuth.instance.signOut();
  }
}
