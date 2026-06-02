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
    required this.category,
    required this.summary,
    this.statusCode,
    this.error,
  });

  final String baseUrl;
  final String host;
  final String hostResolution;
  final bool reachable;
  final ConnectivityDiagnosticCategory category;
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
      'category=${category.name}',
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
    if (baseUrl.isEmpty) {
      return const ConnectivityDiagnosticResult(
        baseUrl: '',
        host: '',
        hostResolution: 'Не проверено',
        reachable: false,
        category: ConnectivityDiagnosticCategory.notConfigured,
        summary: 'Адрес Kimai не настроен.',
      );
    }

    final uri = Uri.parse(baseUrl);
    final versionUri = Uri.parse(
      baseUrl.endsWith('/') ? '${baseUrl}version' : '$baseUrl/version',
    );
    var hostResolution = 'Не проверено';
    Object? dnsError;
    try {
      hostResolution = await resolveHostForDiagnostics(uri.host);
    } catch (error) {
      dnsError = error;
      hostResolution = 'Ошибка DNS: $error';
    }

    try {
      final response = await _dio.getUri<Object?>(
        versionUri,
        options: Options(
          headers: const {'Accept': 'application/json'},
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final statusCode = response.statusCode;
      final classification = _classifyHttpStatus(statusCode);
      return ConnectivityDiagnosticResult(
        baseUrl: baseUrl,
        host: uri.host,
        hostResolution: hostResolution,
        reachable:
            classification.category == ConnectivityDiagnosticCategory.none,
        category: classification.category,
        statusCode: statusCode,
        summary: classification.summary,
      );
    } on DioException catch (error) {
      final classification = _classifyDioError(error, dnsError: dnsError);
      return ConnectivityDiagnosticResult(
        baseUrl: baseUrl,
        host: uri.host,
        hostResolution: hostResolution,
        reachable: false,
        category: classification.category,
        statusCode: error.response?.statusCode,
        summary: classification.summary,
        error: _sanitizeDioError(error),
      );
    } catch (error) {
      return ConnectivityDiagnosticResult(
        baseUrl: baseUrl,
        host: uri.host,
        hostResolution: hostResolution,
        reachable: false,
        category: ConnectivityDiagnosticCategory.unknown,
        summary: 'Не удалось проверить подключение.',
        error: error.toString(),
      );
    }
  }

  _ConnectivityClassification _classifyHttpStatus(int? statusCode) {
    if (statusCode == null) {
      return const _ConnectivityClassification(
        ConnectivityDiagnosticCategory.unknown,
        'Kimai ответил без HTTP-кода.',
      );
    }
    if (statusCode >= 200 && statusCode < 300) {
      return _ConnectivityClassification(
        ConnectivityDiagnosticCategory.none,
        'Kimai отвечает. HTTP $statusCode.',
      );
    }
    if (statusCode == 401 || statusCode == 403) {
      return _ConnectivityClassification(
        ConnectivityDiagnosticCategory.auth,
        'Kimai доступен, но API-ключ не принят. HTTP $statusCode.',
      );
    }
    if (statusCode >= 500) {
      return _ConnectivityClassification(
        ConnectivityDiagnosticCategory.kimaiUnavailable,
        'Kimai недоступен или вернул серверную ошибку. HTTP $statusCode.',
      );
    }

    return _ConnectivityClassification(
      ConnectivityDiagnosticCategory.httpError,
      'Kimai вернул HTTP $statusCode.',
    );
  }

  _ConnectivityClassification _classifyDioError(
    DioException error, {
    Object? dnsError,
  }) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return _classifyHttpStatus(statusCode);
    }

    final message = error.message ?? '';
    final lower = message.toLowerCase();
    if (dnsError != null ||
        lower.contains('failed host lookup') ||
        lower.contains('name resolution') ||
        lower.contains('nodename nor servname')) {
      return const _ConnectivityClassification(
        ConnectivityDiagnosticCategory.dns,
        'DNS не смог разрешить хост Kimai.',
      );
    }
    if (lower.contains('cleartext') ||
        lower.contains('cleartext communication')) {
      return const _ConnectivityClassification(
        ConnectivityDiagnosticCategory.cleartextBlocked,
        'HTTP без шифрования заблокирован Android.',
      );
    }
    if (lower.contains('handshake') ||
        lower.contains('certificate') ||
        lower.contains('tls')) {
      return const _ConnectivityClassification(
        ConnectivityDiagnosticCategory.tls,
        'Ошибка TLS или сертификата.',
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const _ConnectivityClassification(
        ConnectivityDiagnosticCategory.noNetwork,
        'Нет соединения с Kimai или сеть недоступна.',
      );
    }

    return const _ConnectivityClassification(
      ConnectivityDiagnosticCategory.unknown,
      'Ошибка подключения к Kimai.',
    );
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

enum ConnectivityDiagnosticCategory {
  none,
  notConfigured,
  noNetwork,
  dns,
  tls,
  cleartextBlocked,
  auth,
  kimaiUnavailable,
  httpError,
  unknown,
}

class _ConnectivityClassification {
  const _ConnectivityClassification(this.category, this.summary);

  final ConnectivityDiagnosticCategory category;
  final String summary;
}
