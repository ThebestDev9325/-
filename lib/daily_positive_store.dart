import 'package:shared_preferences/shared_preferences.dart';

class DailyPositivePair {
  final int positiveIndex;
  final int quoteIndex;

  const DailyPositivePair({
    required this.positiveIndex,
    required this.quoteIndex,
  });

  String get encoded => '$positiveIndex:$quoteIndex';

  static DailyPositivePair? decode(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final positiveIndex = int.tryParse(parts[0]);
    final quoteIndex = int.tryParse(parts[1]);
    if (positiveIndex == null || quoteIndex == null) return null;
    return DailyPositivePair(
      positiveIndex: positiveIndex,
      quoteIndex: quoteIndex,
    );
  }
}

class DailyPositiveState {
  final String dateKey;
  final List<DailyPositivePair> pairs;

  const DailyPositiveState({required this.dateKey, required this.pairs});
}

abstract interface class DailyPositiveStore {
  Future<DailyPositiveState?> load();
  Future<void> save(DailyPositiveState state);
}

class SharedPreferencesDailyPositiveStore implements DailyPositiveStore {
  static const _dateKey = 'daily_positive_date_v1';
  static const _pairsKey = 'daily_positive_pairs_v1';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesDailyPositiveStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<DailyPositiveState?> load() async {
    final date = await _prefs.getString(_dateKey);
    if (date == null) return null;
    final encodedPairs =
        await _prefs.getStringList(_pairsKey) ?? const <String>[];
    final pairs = encodedPairs
        .map(DailyPositivePair.decode)
        .whereType<DailyPositivePair>()
        .toList(growable: false);
    return DailyPositiveState(dateKey: date, pairs: pairs);
  }

  @override
  Future<void> save(DailyPositiveState state) async {
    await _prefs.setString(_dateKey, state.dateKey);
    await _prefs.setStringList(
      _pairsKey,
      state.pairs.map((pair) => pair.encoded).toList(growable: false),
    );
  }
}

String localDateKey(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
