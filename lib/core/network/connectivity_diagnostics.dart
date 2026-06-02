import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_repository.dart';
import 'host_resolver.dart';
import 'kimai_url.dart';
import 'network_providers.dart';

class ConnectivityDiagnosticResult {
  const ConnectivityDiagnosticResult({
    required this.baseUrl,
    required this.host,
    required this.hostResolution,
    required this.reachable,
    required this.summary,
    this.statusCode,
    this.error,
  });

  final String baseUrl;
  final String host;
  final String hostResolution;
  final bool reachable;
  final int? statusCode;
  final String summary;
  final String? error;

  String toReport() {
    return [
      'connectivity_diagnostics',
      'kimai_base_url=$baseUrl',
      'host=$host',
      'host_resolution=$hostResolution',
      'reachable=$reachable',
      if (statusCode != null) 'status_code=$statusCode',
      'summary=$summary',
      if (error != null) 'error=$error',
    ].join('\n');
  }
}

class ConnectivityDiagnosticsService {
  ConnectivityDiagnosticsService({
    required Dio dio,
    required SettingsRepository settingsRepository,
  })  : _dio = dio,
        _settingsRepository = settingsRepository;

  final Dio _dio;
  final SettingsRepository _settingsRepository;

  Future<ConnectivityDiagnosticResult> checkKimai() async {
    final settings = await _settingsRepository.loadSettings();
    final baseUrl = normalizeKimaiBaseUrl(
      settings.baseUrl,
      allowInsecureHttp: settings.allowInsecureKimaiHttp,
    );
    final uri = Uri.parse(baseUrl);
    final versionUri = Uri.parse(
      baseUrl.endsWith('/') ? '${baseUrl}version' : '$baseUrl/version',
    );
    var hostResolution = 'Не проверено';
    try {
      hostResolution = await resolveHostForDiagnostics(uri.host);
    } catch (error) {
      hostResolution = 'Ошибка DNS: $error';
    }

    try {
      final response = await _dio.getUri<Object?>(
        versionUri,
        options: Options(
          headers: const {'Accept': 'application/json'},
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return ConnectivityDiagnosticResult(
        baseUrl: baseUrl,
        host: uri.host,
        hostResolution: hostResolution,
        reachable: true,
        statusCode: response.statusCode,
        summary:
            'Kimai version endpoint отвечает. HTTP ${response.statusCode ?? 'без кода'}.',
      );
    } on DioException catch (error) {
      return ConnectivityDiagnosticResult(
        baseUrl: baseUrl,
        host: uri.host,
        hostResolution: hostResolution,
        reachable: false,
        statusCode: error.response?.statusCode,
        summary: _classifyDioError(error),
        error: _sanitizeDioError(error),
      );
    } catch (error) {
      return ConnectivityDiagnosticResult(
        baseUrl: baseUrl,
        host: uri.host,
        hostResolution: hostResolution,
        reachable: false,
        summary: 'Не удалось проверить подключение.',
        error: error.toString(),
      );
    }
  }

  String _classifyDioError(DioException error) {
    final message = error.message ?? '';
    final lower = message.toLowerCase();
    if (lower.contains('cleartext') ||
        lower.contains('cleartext communication')) {
      return 'HTTP без шифрования заблокирован Android.';
    }
    if (lower.contains('handshake') ||
        lower.contains('certificate') ||
        lower.contains('tls')) {
      return 'Ошибка TLS или сертификата.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Нет соединения с Kimai или сеть недоступна.';
    }
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return 'Kimai вернул HTTP $statusCode.';
    }

    return 'Ошибка подключения к Kimai.';
  }

  String _sanitizeDioError(DioException error) {
    final request = error.requestOptions;
    return [
      'method=${request.method}',
      'url=${request.uri}',
      if (request.queryParameters.isNotEmpty)
        'query=${request.queryParameters}',
      if (error.response?.statusCode != null)
        'status_code=${error.response!.statusCode}',
      if (error.message != null) 'message=${error.message}',
      if (error.response?.data != null) 'response=${error.response!.data}',
    ].join('\n');
  }
}

final connectivityDiagnosticsServiceProvider =
    Provider<ConnectivityDiagnosticsService>((ref) {
  return ConnectivityDiagnosticsService(
    dio: ref.watch(dioProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});
