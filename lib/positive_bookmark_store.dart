import 'package:shared_preferences/shared_preferences.dart';

class PositiveBookmarkState {
  final Set<int> positiveIndexes;
  final Set<int> quoteIndexes;

  const PositiveBookmarkState({
    this.positiveIndexes = const <int>{},
    this.quoteIndexes = const <int>{},
  });
}

abstract interface class PositiveBookmarkStore {
  Future<PositiveBookmarkState> load();
  Future<void> save(PositiveBookmarkState state);
}

class SharedPreferencesPositiveBookmarkStore implements PositiveBookmarkStore {
  static const _positiveIndexesKey = 'positive_bookmark_story_indexes_v1';
  static const _quoteIndexesKey = 'positive_bookmark_quote_indexes_v1';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesPositiveBookmarkStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<PositiveBookmarkState> load() async {
    final positiveIndexes =
        await _prefs.getStringList(_positiveIndexesKey) ?? const <String>[];
    final quoteIndexes =
        await _prefs.getStringList(_quoteIndexesKey) ?? const <String>[];
    return PositiveBookmarkState(
      positiveIndexes: positiveIndexes
          .map(int.tryParse)
          .whereType<int>()
          .toSet(),
      quoteIndexes: quoteIndexes.map(int.tryParse).whereType<int>().toSet(),
    );
  }

  @override
  Future<void> save(PositiveBookmarkState state) async {
    final positiveIndexes = state.positiveIndexes.toList()..sort();
    final quoteIndexes = state.quoteIndexes.toList()..sort();
    await _prefs.setStringList(
      _positiveIndexesKey,
      positiveIndexes.map((index) => '$index').toList(growable: false),
    );
    await _prefs.setStringList(
      _quoteIndexesKey,
      quoteIndexes.map((index) => '$index').toList(growable: false),
    );
  }
}
