import 'package:shared_preferences/shared_preferences.dart';

class PlantProgress {
  final String dateKey;
  final int tapCount;

  const PlantProgress({required this.dateKey, required this.tapCount});
}

abstract interface class PlantProgressStore {
  Future<PlantProgress?> load();
  Future<void> save(PlantProgress progress);
}

class SharedPreferencesPlantProgressStore implements PlantProgressStore {
  static const _dateKey = 'home_plant_date_v1';
  static const _tapCountKey = 'home_plant_taps_v1';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<PlantProgress?> load() async {
    final date = await _prefs.getString(_dateKey);
    if (date == null) return null;
    return PlantProgress(
      dateKey: date,
      tapCount: await _prefs.getInt(_tapCountKey) ?? 0,
    );
  }

  @override
  Future<void> save(PlantProgress progress) async {
    await _prefs.setString(_dateKey, progress.dateKey);
    await _prefs.setInt(_tapCountKey, progress.tapCount);
  }
}
