import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._database);

  static const _baseUrlKey = 'settings.kimai.base_url';
  static const _currencyKey = 'settings.currency';
  static const _localeKey = 'settings.locale';

  final AppDatabase _database;

  Future<AppSettings> loadSettings() async {
    final rows = await _database.select(_database.syncState).get();
    final values = {
      for (final row in rows) row.key: row.value,
    };

    return AppSettings(
      baseUrl: values[_baseUrlKey] ?? AppSettings.defaults.baseUrl,
      currency: values[_currencyKey] ?? AppSettings.defaults.currency,
      locale: values[_localeKey] ?? AppSettings.defaults.locale,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _database.transaction(() async {
      await _upsertValue(_baseUrlKey, settings.baseUrl);
      await _upsertValue(_currencyKey, settings.currency);
      await _upsertValue(_localeKey, settings.locale);
    });
  }

  Future<void> _upsertValue(String key, String value) {
    final now = DateTime.now().toUtc();

    return _database.into(_database.syncState).insertOnConflictUpdate(
          SyncStateCompanion(
            key: Value(key),
            value: Value(value),
            updatedAt: Value(now),
          ),
        );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final appSettingsProvider = FutureProvider<AppSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).loadSettings();
});
