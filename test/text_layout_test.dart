import 'package:chameulin/text_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('한글 단어는 음절 중간에서 줄바꿈되지 않도록 연결한다', () {
    expect(
      preventKoreanWordSplits('사실인 것은 아닙니다.'),
      '사\u2060실\u2060인 것\u2060은 아\u2060닙\u2060니\u2060다.',
    );
  });
}
