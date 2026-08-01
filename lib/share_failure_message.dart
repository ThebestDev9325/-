import 'package:firebase_core/firebase_core.dart';

const _networkMessage = '공유하지 못했습니다. 인터넷 연결을 확인하고 다시 시도해주세요.';
const _authenticationMessage = '로그인이 만료되었습니다. 다시 로그인한 뒤 시도해주세요.';
const _permissionMessage = '이 계정으로는 공유할 수 없습니다. 계정 연결 상태를 확인해주세요.';
const _genericMessage = '공유하지 못했습니다. 잠시 후 다시 시도해주세요.';

const _networkCodes = {
  'unavailable',
  'deadline-exceeded',
  'network-request-failed',
};
const _actionableFunctionCodes = {
  'permission-denied',
  'invalid-argument',
  'failed-precondition',
  'not-found',
  'already-exists',
  'resource-exhausted',
};

bool isIndeterminateShareError(Object error) =>
    error is FirebaseException && _networkCodes.contains(error.code);

String shareFailureMessage(Object error) {
  if (error is! FirebaseException) return _genericMessage;
  if (_networkCodes.contains(error.code)) return _networkMessage;
  if (error.code == 'unauthenticated') return _authenticationMessage;
  final message = error.message?.trim();
  if (error.plugin == 'firebase_functions' &&
      _actionableFunctionCodes.contains(error.code) &&
      message != null &&
      message.isNotEmpty) {
    return message;
  }
  if (error.code == 'permission-denied') return _permissionMessage;
  return _genericMessage;
}
