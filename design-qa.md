# Design QA — v26 홈 꽃·긍정 화면

- Source visual truth: `C:\Users\user\Desktop\KakaoTalk_20260713_194120291.jpg`
- Implementation screenshot: `docs/design-qa/home-v26-complete.png`
- Positive screenshot: `docs/design-qa/positive-v26.png`
- Quote screenshot: `docs/design-qa/quote-v26.png`
- Comparison image: `docs/design-qa/home-v26-comparison.png`
- Viewport: 419 × 1024 logical pixels
- State: light theme, Monday flower, completed fifth growth stage

## Full-view comparison evidence

The home implementation was rendered at the normalized logical viewport. The
source includes device chrome, navigation, and ads that are outside this
change's scope; the comparison therefore normalizes the upper home-content
region where the requested changes occur. Existing navigation and ad widgets
remain unchanged.

## Focused region comparison evidence

`docs/design-qa/home-v26-comparison.png` places the source home header on the
left and the revised implementation on the right. It confirms that:

- the slogan stays on exactly two lines;
- the comma and period are removed;
- the completed flower extends upward alongside the first slogan line;
- the new `터치해보세요` hint sits immediately below the pot;
- the flower does not cover either slogan line or the main writing card.

The positive and quote captures confirm distinct yellow and light-green
surfaces. The quote body uses a visibly larger type size than v25.

## Required fidelity surfaces

- Fonts and typography: Malgun Gothic was loaded for the capture. Slogan line
  breaks, Korean glyphs, heading weight, quote size, and attribution hierarchy
  are clear with no clipping or truncation.
- Spacing and layout rhythm: the 206-pixel header feature area preserves the
  main card and start button. Flower, hint, and slogan have separate readable
  zones.
- Colors and visual tokens: positive uses soft yellow (`#FFF7D9` card,
  `#FFECA8` heading); quote uses light green (`#F0F7E5` card, `#E3F1CF`
  heading). Both retain sufficient dark text contrast in light mode, with
  dedicated dark-mode colors in code.
- Image quality and asset fidelity: the existing transparent weekday flower
  asset remains sharp. `BoxFit.cover` removes excess transparent side space
  without cropping the flower or pot.
- Copy and content: `내 마음을 위해`, `참을인 하나`, and `터치해보세요`
  match the requested wording exactly.

## Comparison history

1. Initial implementation used `BoxFit.contain`; the flower remained too short
   because the square asset's transparent side space constrained its scale.
2. Changed the plant image to `BoxFit.cover`, recaptured at the same viewport,
   and verified that the flower now reaches the first slogan line without
   clipping.

## Findings

No actionable P0, P1, or P2 visual differences remain in the changed regions.

## Follow-up polish

No P3 item is required for this handoff.

final result: passed
