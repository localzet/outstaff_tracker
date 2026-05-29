import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/settings/data/settings_repository.dart';
import '../storage/secure_token_storage.dart';
import 'kimai_api_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage(const FlutterSecureStorage());
});

final kimaiApiClientProvider = FutureProvider<KimaiApiClient>((ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).loadSettings();

  return KimaiApiClient(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
    baseUrl: settings.baseUrl,
  );
});
