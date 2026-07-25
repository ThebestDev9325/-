final _adjacentKoreanSyllables = RegExp(r'([가-힣])(?=[가-힣])');

/// Keeps Flutter from wrapping a Korean word between individual syllables.
/// Spaces and punctuation remain valid line-break positions.
String preventKoreanWordSplits(String text) {
  return text.replaceAllMapped(
    _adjacentKoreanSyllables,
    (match) => '${match.group(1)}\u2060',
  );
}

/// Starts each sentence or comma-separated clause on a new visual line.
String formatStoryBodyForReadability(String text) {
  return text
      .trim()
      .replaceAllMapped(
        RegExp(r'([.!?])\s+'),
        (match) => '${match.group(1)}\n',
      )
      .replaceAll(RegExp(r',\s+'), ',\n');
}
