import 'package:chameulin/share_failure_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('네트워크 오류만 연결 확인 메시지로 안내한다', () {
    expect(
      shareFailureMessage(
        FirebaseFunctionsException(code: 'unavailable', message: 'offline'),
      ),
      contains('인터넷 연결'),
    );
    expect(
      shareFailureMessage(
        FirebaseException(
            plugin: 'firebase_auth', code: 'network-request-failed'),
      ),
      contains('인터넷 연결'),
    );
    expect(
      shareFailureMessage(
        FirebaseFunctionsException(
          code: 'deadline-exceeded',
          message: 'timeout',
        ),
      ),
      contains('인터넷 연결'),
    );
  });

  test('응답 유실 가능성이 있는 오류만 게시 결과 불명확으로 분류한다', () {
    expect(
      isIndeterminateShareError(
        FirebaseFunctionsException(code: 'unavailable', message: 'offline'),
      ),
      isTrue,
    );
    expect(
      isIndeterminateShareError(
        FirebaseFunctionsException(
          code: 'deadline-exceeded',
          message: 'timeout',
        ),
      ),
      isTrue,
    );
    expect(
      isIndeterminateShareError(
        FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'denied',
        ),
      ),
      isFalse,
    );
    expect(isIndeterminateShareError(StateError('failure')), isFalse);
  });

  test('Functions의 사용자 조치 가능 메시지는 유지한다', () {
    expect(
      shareFailureMessage(
        FirebaseFunctionsException(
          code: 'permission-denied',
          message: '정지된 계정은 사연을 공유할 수 없습니다.',
        ),
      ),
      '정지된 계정은 사연을 공유할 수 없습니다.',
    );
  });

  test('인증과 Firestore 권한 오류는 내부 문구 없이 안내한다', () {
    expect(
      shareFailureMessage(
        FirebaseFunctionsException(code: 'unauthenticated', message: 'token'),
      ),
      contains('다시 로그인'),
    );
    expect(
      shareFailureMessage(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'internal rules details',
        ),
      ),
      isNot(contains('internal rules details')),
    );
  });

  test('일반 예외는 인터넷 문제로 단정하거나 내부 내용을 노출하지 않는다', () {
    final message = shareFailureMessage(StateError('secret internal state'));
    expect(message, isNot(contains('secret internal state')));
    expect(message, isNot(contains('인터넷')));
    expect(message, contains('다시 시도'));
  });
}
