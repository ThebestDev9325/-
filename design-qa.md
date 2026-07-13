# Design QA — v27 홈 쓰기 카드

- Source visual truth: `C:\Users\user\Desktop\수정하기.jpg`
- Implementation screenshot: `docs/design-qa/home-v27-complete.png`
- Comparison image: `docs/design-qa/home-v27-comparison.png`
- Viewport: 419 × 760 logical pixels (상단 앱 콘텐츠 영역)
- State: light theme, Monday flower, completed fifth growth stage

## Full-view comparison evidence

`home-v27-comparison.png`은 사용자가 그림판으로 수정한 상단 콘텐츠를
왼쪽에, 같은 비율로 렌더링한 Flutter 구현을 오른쪽에 배치한다. 기기 상태
표시줄, 하단 내비게이션, 광고 영역은 이번 변경 범위 밖이므로 상단 앱 콘텐츠
영역만 같은 폭으로 정규화했다.

## Focused region comparison evidence

- 앱 이름, 두 줄 문구, 꽃이 하나의 210px 상단 영역에 함께 배치된다.
- 꽃은 제목 옆에서 시작하고 안내 문구는 화분 바로 아래에 유지된다.
- 쓰기 카드는 상단 약 264px 지점에서 시작해 400px 이상 높이를 확보한다.
- 시작 버튼은 카드 아래에 완전히 노출되며 카드나 화면 가장자리와 겹치지 않는다.

별도의 확대 비교가 필요하지 않을 정도로 주요 변경 요소가 전체 비교 이미지에서
명확하게 읽힌다.

## Required fidelity surfaces

- Fonts and typography: Malgun Gothic으로 캡처했다. 앱 이름과 두 줄 문구의
  위계, 줄바꿈, 굵기, 자간이 유지되고 잘림이 없다.
- Spacing and layout rhythm: 이전의 분리된 앱 이름 행을 상단 스택에 통합해
  쓰기 카드에 50px 이상의 세로 공간을 돌려줬다. 카드와 버튼 간격도 일정하다.
- Colors and visual tokens: 기존 연녹색 배경, 흰색 카드, 진녹색 글자와 버튼을
  그대로 사용해 참을인 디자인 체계를 유지했다.
- Image quality and asset fidelity: 기존 투명 PNG 꽃을 그대로 사용하며 꽃과
  화분이 잘리거나 늘어나지 않는다.
- Copy and content: `참을인`, `내 마음을 위해`, `참을인 하나`,
  `터치해보세요`, `참을 인을 써봅시다`, `시작하기`가 정확히 표시된다.

## Interaction verification

- 꽃을 다섯 번 터치하면 다음 성장 단계로 전환된다.
- 설정의 `내 데이터 삭제` 확인 시 저장된 화분 진행도가 삭제된다.
- 삭제 직후 홈의 화분이 첫 단계로 다시 렌더링된다.

## Comparison history

1. v26은 앱 이름과 꽃·문구 행이 각각 높이를 차지해 쓰기 카드가 작아졌다.
2. v27에서 앱 이름, 문구, 꽃을 같은 상단 스택에 배치하고 카드 상단 여백을
   16px에서 8px로 줄였다.
3. 같은 상태로 다시 캡처해 카드 높이, 꽃 위치, 버튼 노출을 확인했다.

## Findings

변경 영역에 남아 있는 P0, P1, P2 문제는 없다.

## Follow-up polish

없음.

final result: passed
