import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._database);

  static const baseUrlKey = 'settings.kimai.base_url';
  static const currencyKey = 'settings.currency';
  static const localeKey = 'settings.locale';
  static const onboardingCompleteKey = 'settings.onboarding.complete';

  final AppDatabase _database;

  Future<AppSettings> loadSettings() async {
    final rows = await _database.select(_database.syncState).get();
    final values = {
      for (final row in rows) row.key: row.value,
    };

    return AppSettings(
      baseUrl: values[baseUrlKey] ?? AppSettings.defaults.baseUrl,
      currency: values[currencyKey] ?? AppSettings.defaults.currency,
      locale: values[localeKey] ?? AppSettings.defaults.locale,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _database.transaction(() async {
      await _upsertValue(baseUrlKey, settings.baseUrl);
      await _upsertValue(currencyKey, settings.currency);
      await _upsertValue(localeKey, settings.locale);
    });
  }

  Future<bool> isOnboardingComplete() async {
    final row = await (_database.select(_database.syncState)
          ..where((table) => table.key.equals(onboardingCompleteKey)))
        .getSingleOrNull();

    return row?.value == 'true';
  }

  Future<void> setOnboardingComplete(bool complete) {
    return _upsertValue(onboardingCompleteKey, complete.toString());
  }

  Future<Map<String, String?>> exportSettingsBackup() async {
    final rows = await _database.select(_database.syncState).get();
    final allowed = {baseUrlKey, currencyKey, localeKey, onboardingCompleteKey};

    return {
      for (final row in rows)
        if (allowed.contains(row.key)) row.key: row.value,
    };
  }

  Future<void> importSettingsBackup(Map<String, Object?> values) async {
    final allowed = {baseUrlKey, currencyKey, localeKey, onboardingCompleteKey};
    await _database.transaction(() async {
      for (final entry in values.entries) {
        if (allowed.contains(entry.key) && entry.value is String) {
          await _upsertValue(entry.key, entry.value! as String);
        }
      }
    });
  }

  Future<void> clearLocalSettings() async {
    await (_database.delete(_database.syncState)
          ..where((table) => table.key.like('settings.%')))
        .go();
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
