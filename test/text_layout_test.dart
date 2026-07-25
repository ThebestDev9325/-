import 'package:chameulin/text_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('한글 단어는 음절 중간에서 줄바꿈되지 않도록 연결한다', () {
    expect(
      preventKoreanWordSplits('사실인 것은 아닙니다.'),
      '사\u2060실\u2060인 것\u2060은 아\u2060닙\u2060니\u2060다.',
    );
  });

  test('이야기 본문은 문장과 쉼표 뒤에서 줄을 바꾼다', () {
    expect(
      formatStoryBodyForReadability(
        '첫 문장입니다. 다음 문장은 길어서, 잠시 나누어 읽습니다.',
      ),
      '첫 문장입니다.\n다음 문장은 길어서,\n잠시 나누어 읽습니다.',
    );
  });
}
