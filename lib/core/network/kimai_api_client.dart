import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_token_storage.dart';
import '../utils/tags.dart';
import 'kimai_url.dart';

class KimaiApiClient {
  KimaiApiClient({
    required Dio dio,
    required SecureTokenStorage tokenStorage,
    required String baseUrl,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _baseUrl = baseUrl;

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;
  final String _baseUrl;

  Future<bool> checkConnection() async {
    final response = await _request<Map<String, Object?>>(
      path: 'version',
      method: 'GET',
    );

    return response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;
  }

  Future<List<KimaiProjectDto>> fetchProjects() async {
    final response = await _request<List<dynamic>>(
      path: 'projects',
      method: 'GET',
      queryParameters: const {'visible': 3},
    );

    final data = response.data ?? const [];
    return data
        .whereType<Map<String, Object?>>()
        .map(KimaiProjectDto.fromJson)
        .toList(growable: false);
  }

  Future<List<KimaiActivityDto>> fetchActivities({int? projectId}) async {
    final response = await _request<List<dynamic>>(
      path: 'activities',
      method: 'GET',
      queryParameters: {
        'visible': 3,
        if (projectId != null) 'project': projectId,
      },
    );

    final data = response.data ?? const [];
    return data
        .whereType<Map<String, Object?>>()
        .map(KimaiActivityDto.fromJson)
        .toList(growable: false);
  }

  Future<List<KimaiTagDto>> fetchTags() async {
    try {
      final response = await _request<Object?>(
        path: 'tags/find',
        method: 'GET',
      );

      return _readResponseList(response.data)
          .map(KimaiTagDto.fromJson)
          .where((tag) => tag.name.isNotEmpty)
          .toList(growable: false);
    } on KimaiApiException catch (error) {
      final statusCode = error.details.statusCode;
      if (statusCode != 404 && statusCode != 405) {
        rethrow;
      }
    }

    final response = await _request<Object?>(
      path: 'tags',
      method: 'GET',
    );

    return _readResponseList(response.data)
        .map(KimaiTagDto.fromJson)
        .where((tag) => tag.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<KimaiCurrentUserDto> fetchCurrentUser() async {
    final response = await _request<Map<String, Object?>>(
      path: 'users/me',
      method: 'GET',
    );

    return KimaiCurrentUserDto.fromJson(response.data ?? const {});
  }

  Future<List<KimaiUserDto>> fetchUsers() async {
    final response = await _request<Object?>(
      path: 'users',
      method: 'GET',
      queryParameters: const {'visible': 3},
    );

    return _readResponseList(response.data)
        .whereType<Map<String, Object?>>()
        .map(KimaiUserDto.fromJson)
        .toList(growable: false);
  }

  Future<List<KimaiTimesheetDto>> fetchTimesheets(
    DateTime begin,
    DateTime end, {
    int? projectId,
  }) async {
    final result = await fetchTimesheetsDetailed(
      begin,
      end,
      projectId: projectId,
    );

    return result.entries;
  }

  Future<KimaiTimesheetFetchResult> fetchTimesheetsDetailed(
    DateTime begin,
    DateTime end, {
    int? projectId,
  }) {
    return fetchKimaiTimesheetPages(
      begin: begin,
      end: end,
      projectId: projectId,
      requestPage: (queryParameters) => _request<Object?>(
        path: 'timesheets',
        method: 'GET',
        queryParameters: queryParameters,
      ),
    );
  }

  Future<KimaiTimesheetFetchResult> fetchTimesheetsForReport({
    int? projectId,
    required DateTime begin,
    required DateTime end,
    int? userId,
  }) {
    return fetchKimaiTimesheetPages(
      begin: begin,
      end: end,
      projectId: projectId,
      userId: userId,
      requestPage: (queryParameters) => _request<Object?>(
        path: 'timesheets',
        method: 'GET',
        queryParameters: queryParameters,
      ),
    );
  }

  Future<KimaiTimesheetDto> createTimesheet({
    required int projectId,
    required DateTime beginAt,
    required DateTime endAt,
    required String description,
    int? activityId,
    String? tags,
  }) async {
    final response = await _request<Map<String, Object?>>(
      path: 'timesheets',
      method: 'POST',
      data: {
        'project': projectId,
        if (activityId != null) 'activity': activityId,
        'begin': formatKimaiDateTime(beginAt),
        'end': formatKimaiDateTime(endAt),
        if (description.trim().isNotEmpty) 'description': description.trim(),
        if (tags != null && tags.trim().isNotEmpty) 'tags': _splitTags(tags),
      },
    );

    return KimaiTimesheetDto.fromJson(response.data ?? const {});
  }

  Future<KimaiTimesheetDto> startTimesheet({
    required int projectId,
    required DateTime beginAt,
    required String description,
    int? activityId,
    String? tags,
  }) async {
    final response = await _request<Map<String, Object?>>(
      path: 'timesheets',
      method: 'POST',
      data: _timesheetPayload(
        projectId: projectId,
        activityId: activityId,
        beginAt: beginAt,
        description: description,
        tags: tags,
      ),
    );

    return KimaiTimesheetDto.fromJson(response.data ?? const {});
  }

  Future<KimaiTimesheetDto> stopTimesheet({
    required int kimaiTimesheetId,
    required DateTime endAt,
  }) async {
    final response = await _request<Map<String, Object?>>(
      path: 'timesheets/$kimaiTimesheetId/stop',
      method: 'PATCH',
      data: {'end': formatKimaiDateTime(endAt)},
    );

    return KimaiTimesheetDto.fromJson(response.data ?? const {});
  }

  Future<KimaiTimesheetDto> updateTimesheet({
    required int kimaiTimesheetId,
    required int projectId,
    required DateTime beginAt,
    required DateTime endAt,
    required String description,
    int? activityId,
    String? tags,
  }) async {
    final response = await _request<Map<String, Object?>>(
      path: 'timesheets/$kimaiTimesheetId',
      method: 'PATCH',
      data: _timesheetPayload(
        projectId: projectId,
        activityId: activityId,
        beginAt: beginAt,
        endAt: endAt,
        description: description,
        tags: tags,
      ),
    );

    return KimaiTimesheetDto.fromJson(response.data ?? const {});
  }

  Future<void> deleteTimesheet(int kimaiTimesheetId) async {
    await _request<Object?>(
      path: 'timesheets/$kimaiTimesheetId',
      method: 'DELETE',
    );
  }

  Future<Response<T>> _request<T>({
    required String path,
    required String method,
    Map<String, Object?>? queryParameters,
    Object? data,
  }) async {
    final token = await _tokenStorage.readKimaiToken();
    if (token == null || token.trim().isEmpty) {
      throw KimaiAuthenticationException('Kimai API token is not configured.');
    }

    final normalizedBaseUrl = normalizeKimaiBaseUrl(_baseUrl);
    final endpoint = _buildEndpoint(normalizedBaseUrl, path);
    final sanitizedQuery = _sanitizeQuery(queryParameters);

    if (kDebugMode) {
      debugPrint(
        'Kimai request $method $endpoint query=$sanitizedQuery',
      );
    }

    try {
      final response = await _dio.request<T>(
        endpoint.toString(),
        options: Options(
          method: method,
          headers: {
            Headers.acceptHeader: Headers.jsonContentType,
            Headers.contentTypeHeader: Headers.jsonContentType,
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: sanitizedQuery,
        data: data,
      );

      return response;
    } on DioException catch (error) {
      final detail = KimaiRequestErrorDetails.fromDioException(
        error,
        baseUrl: normalizedBaseUrl,
        method: method,
        path: _formatDiagnosticPath(path),
        queryParameters: sanitizedQuery,
      );

      if (kDebugMode) {
        debugPrint(
          'Kimai error status=${detail.statusCode} body=${detail.responseBody}',
        );
      }

      throw KimaiApiException(detail, error);
    }
  }
}

Map<String, Object> _timesheetPayload({
  required int projectId,
  required DateTime beginAt,
  required String description,
  DateTime? endAt,
  int? activityId,
  String? tags,
}) {
  return {
    'project': projectId,
    if (activityId != null) 'activity': activityId,
    'begin': formatKimaiDateTime(beginAt),
    if (endAt != null) 'end': formatKimaiDateTime(endAt),
    if (description.trim().isNotEmpty) 'description': description.trim(),
    if (tags != null && tags.trim().isNotEmpty) 'tags': _splitTags(tags),
  };
}

List<String> _splitTags(String value) {
  return value
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}

const kimaiDefaultPageSize = 50;
const kimaiMaxPages = 1000;

typedef KimaiTimesheetPageRequester = Future<Response<Object?>> Function(
  Map<String, Object> queryParameters,
);

Future<KimaiTimesheetFetchResult> fetchKimaiTimesheetPages({
  required DateTime begin,
  required DateTime end,
  required KimaiTimesheetPageRequester requestPage,
  int? projectId,
  int? userId,
}) async {
  final entries = <KimaiTimesheetDto>[];
  final requests = <KimaiTimesheetRequestSummary>[];
  final seenIds = <int>{};

  Future<TimesheetPageReadResult> loadPage(int? page) async {
    final queryParameters = buildTimesheetQueryParams(
      begin: begin,
      end: end,
      projectId: projectId,
      userId: userId,
      page: page,
    );
    final response = await requestPage(queryParameters);
    final readResult = readTimesheetPage(response);
    requests.add(
      KimaiTimesheetRequestSummary(
        projectId: projectId,
        page: page,
        queryParameters: queryParameters,
        statusCode: response.statusCode,
        responseShape: readResult.responseShape,
        entriesReceived: readResult.entries.length,
        currentPage: readResult.currentPage,
        totalPages: readResult.totalPages,
      ),
    );

    return readResult;
  }

  void addUniqueEntries(List<KimaiTimesheetDto> pageEntries) {
    for (final entry in pageEntries) {
      if (seenIds.add(entry.id)) {
        entries.add(entry);
      }
    }
  }

  final firstPage = await loadPage(null);
  addUniqueEntries(firstPage.entries);
  if (firstPage.entries.isEmpty) {
    return KimaiTimesheetFetchResult(entries: entries, requests: requests);
  }

  final totalPages = firstPage.totalPages;
  if (totalPages != null) {
    if (totalPages > kimaiMaxPages) {
      throw StateError('Kimai pagination exceeded safety cap: $totalPages');
    }
    for (var page = (firstPage.currentPage ?? 1) + 1;
        page <= totalPages;
        page++) {
      final nextPage = await loadPage(page);
      addUniqueEntries(nextPage.entries);
    }

    return KimaiTimesheetFetchResult(entries: entries, requests: requests);
  }

  if (firstPage.entries.length < kimaiDefaultPageSize) {
    return KimaiTimesheetFetchResult(entries: entries, requests: requests);
  }

  for (var page = 2; page <= kimaiMaxPages; page++) {
    final nextPage = await loadPage(page);
    if (nextPage.entries.isEmpty) {
      break;
    }

    final before = seenIds.length;
    addUniqueEntries(nextPage.entries);
    if (seenIds.length == before) {
      break;
    }

    final nextTotalPages = nextPage.totalPages;
    if (nextTotalPages != null && page >= nextTotalPages) {
      break;
    }
    if (nextPage.entries.length < kimaiDefaultPageSize) {
      break;
    }
    if (page == kimaiMaxPages) {
      throw StateError('Kimai pagination reached safety cap: $kimaiMaxPages');
    }
  }

  return KimaiTimesheetFetchResult(entries: entries, requests: requests);
}

Map<String, Object> buildTimesheetQueryParams({
  required DateTime begin,
  required DateTime end,
  int? projectId,
  int? userId,
  int? page,
}) {
  return {
    // TODO: Confirm date filter names against the target Kimai version.
    'begin': formatKimaiDateTime(begin),
    'end': formatKimaiDateTime(end),
    // TODO: Confirm project filter name for the target Kimai version.
    if (projectId != null) 'project': projectId,
    if (userId != null) 'user': userId,
    if (page != null) 'page': page,
  };
}

KimaiSyncRange buildFullYearSyncRange([DateTime? now]) {
  final localNow = now ?? DateTime.now();
  final today = DateTime(localNow.year, localNow.month, localNow.day);

  return KimaiSyncRange(
    begin: today.subtract(const Duration(days: 365)),
    end:
        today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
  );
}

KimaiSyncRange buildLast7DaysSyncRange([DateTime? now]) {
  final localNow = now ?? DateTime.now();
  final today = DateTime(localNow.year, localNow.month, localNow.day);

  return KimaiSyncRange(
    begin: today.subtract(const Duration(days: 7)),
    end:
        today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
  );
}

String formatKimaiDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');

  return '${local.year.toString().padLeft(4, '0')}-'
      '${two(local.month)}-'
      '${two(local.day)}T'
      '${two(local.hour)}:'
      '${two(local.minute)}:'
      '${two(local.second)}';
}

Uri _buildEndpoint(String baseUrl, String path) {
  final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
  final relativePath = path.replaceFirst(RegExp(r'^/+'), '');

  return base.resolve(relativePath);
}

Map<String, Object> _sanitizeQuery(Map<String, Object?>? queryParameters) {
  return {
    for (final entry in (queryParameters ?? const <String, Object?>{}).entries)
      if (entry.value != null) entry.key: entry.value!,
  };
}

class KimaiApiException implements Exception {
  const KimaiApiException(this.details, this.source);

  final KimaiRequestErrorDetails details;
  final DioException source;

  @override
  String toString() => details.toDiagnosticString();
}

class KimaiRequestErrorDetails {
  const KimaiRequestErrorDetails({
    required this.timestamp,
    required this.baseUrl,
    required this.method,
    required this.path,
    required this.queryParameters,
    this.requestBody,
    required this.statusCode,
    required this.responseBody,
  });

  factory KimaiRequestErrorDetails.fromDioException(
    DioException error, {
    required String baseUrl,
    required String method,
    required String path,
    required Map<String, Object> queryParameters,
  }) {
    return KimaiRequestErrorDetails(
      timestamp: DateTime.now().toUtc(),
      baseUrl: baseUrl,
      method: method,
      path: path,
      queryParameters: queryParameters,
      requestBody: sanitizeKimaiRequestBody(error.requestOptions.data),
      statusCode: error.response?.statusCode,
      responseBody: stringifyKimaiResponseData(error.response?.data),
    );
  }

  final DateTime timestamp;
  final String baseUrl;
  final String method;
  final String path;
  final Map<String, Object> queryParameters;
  final Object? requestBody;
  final int? statusCode;
  final String responseBody;

  String toDiagnosticString({
    int? projectId,
    String? syncType,
  }) {
    return [
      'timestamp=${timestamp.toIso8601String()}',
      if (syncType != null) 'sync_type=$syncType',
      if (projectId != null) 'project_id=$projectId',
      'base_url=$baseUrl',
      'method=$method',
      'path=$path',
      'query_parameters=$queryParameters',
      if (requestBody != null) 'request_body=$requestBody',
      'status_code=${statusCode ?? 'unknown'}',
      'response_body=$responseBody',
    ].join('\n');
  }
}

Object? sanitizeKimaiRequestBody(Object? data) {
  const sensitiveKeys = {
    'token',
    'apiToken',
    'password',
    'Authorization',
    'authorization',
  };

  Object? sanitize(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): sensitiveKeys.contains(entry.key.toString())
              ? '<redacted>'
              : sanitize(entry.value),
      };
    }
    if (value is List) {
      return value.map(sanitize).toList(growable: false);
    }

    return value;
  }

  return sanitize(data);
}

String stringifyKimaiResponseData(Object? data) {
  if (data == null) {
    return '';
  }

  try {
    return jsonEncode(data);
  } catch (_) {
    return data.toString();
  }
}

String _formatDiagnosticPath(String path) {
  final normalized = path.replaceFirst(RegExp(r'^/+'), '');

  return '/$normalized';
}

TimesheetPageReadResult readTimesheetPage(Response<Object?> response) {
  final entries = _mapTimesheetResponse(response.data);

  return TimesheetPageReadResult(
    entries: entries,
    responseShape: describeKimaiResponseShape(response.data),
    currentPage: _readPaginationHeader(response, 'x-page') ??
        _readIntField(response.data, const ['currentPage', 'page']),
    totalPages: _readPaginationHeader(response, 'x-total-pages') ??
        _readIntField(response.data, const ['totalPages', 'pages']),
  );
}

String describeKimaiResponseShape(Object? data) {
  if (data is List) {
    return 'list(length=${data.length})';
  }

  if (data is Map<String, Object?>) {
    final keys = data.keys.join(',');
    for (final key in const ['data', 'items', 'results']) {
      final value = data[key];
      if (value is List) {
        return 'map(keys=$keys,$key.length=${value.length})';
      }
    }

    return 'map(keys=$keys)';
  }

  return data == null ? 'null' : data.runtimeType.toString();
}

int? _readPaginationHeader(Response<Object?> response, String name) {
  final value = response.headers.value(name);

  return value == null ? null : int.tryParse(value);
}

int? _readIntField(Object? data, List<String> keys) {
  if (data is! Map<String, Object?>) {
    return null;
  }

  for (final key in keys) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

List<KimaiTimesheetDto> _mapTimesheetResponse(Object? data) {
  return _readResponseList(data)
      .whereType<Map<String, Object?>>()
      .map(KimaiTimesheetDto.fromJson)
      .toList(growable: false);
}

class KimaiTimesheetFetchResult {
  const KimaiTimesheetFetchResult({
    required this.entries,
    required this.requests,
  });

  final List<KimaiTimesheetDto> entries;
  final List<KimaiTimesheetRequestSummary> requests;

  String toDiagnosticString() {
    return [
      'pages_requested=${requests.length}',
      'entries_received=${entries.length}',
      for (final request in requests) request.toDiagnosticString(),
    ].join('\n');
  }
}

class KimaiTimesheetRequestSummary {
  const KimaiTimesheetRequestSummary({
    required this.projectId,
    required this.page,
    required this.queryParameters,
    required this.statusCode,
    required this.responseShape,
    required this.entriesReceived,
    this.currentPage,
    this.totalPages,
  });

  final int? projectId;
  final int? page;
  final Map<String, Object> queryParameters;
  final int? statusCode;
  final String responseShape;
  final int entriesReceived;
  final int? currentPage;
  final int? totalPages;

  String toDiagnosticString() {
    return [
      'request=GET /api/timesheets',
      if (projectId != null) 'project_id=$projectId',
      'page=${page ?? 'initial'}',
      'query_parameters=$queryParameters',
      'status_code=${statusCode ?? 'unknown'}',
      'response_shape=$responseShape',
      'entries_received=$entriesReceived',
      if (currentPage != null) 'current_page=$currentPage',
      if (totalPages != null) 'total_pages=$totalPages',
    ].join('\n');
  }
}

class TimesheetPageReadResult {
  const TimesheetPageReadResult({
    required this.entries,
    required this.responseShape,
    this.currentPage,
    this.totalPages,
  });

  final List<KimaiTimesheetDto> entries;
  final String responseShape;
  final int? currentPage;
  final int? totalPages;
}

class KimaiSyncRange {
  const KimaiSyncRange({required this.begin, required this.end});

  final DateTime begin;
  final DateTime end;
}

List<Object?> _readResponseList(Object? data) {
  if (data is List) {
    return data;
  }

  if (data is Map<String, Object?>) {
    for (final key in const ['data', 'items', 'results']) {
      final value = data[key];
      if (value is List) {
        return value;
      }
    }
  }

  return const [];
}

class KimaiAuthenticationException implements Exception {
  KimaiAuthenticationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class KimaiProjectDto {
  const KimaiProjectDto({
    required this.id,
    required this.name,
    required this.visible,
    required this.billable,
    this.customerName,
    this.color,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? customerName;
  final bool visible;
  final bool billable;
  final String? color;
  final DateTime? updatedAt;

  factory KimaiProjectDto.fromJson(Map<String, Object?> json) {
    final customer = json['customer'];

    return KimaiProjectDto(
      id: _readInt(json['id']),
      name: _readString(json['name']) ?? 'Untitled project',
      customerName: customer is Map<String, Object?>
          ? _readString(customer['name'])
          : _readString(json['customerName']),
      visible: _readBool(json['visible'], fallback: true),
      billable: _readBool(json['billable'], fallback: true),
      color: _readString(json['color']),
      // TODO: Confirm project update field for the target Kimai version.
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

class KimaiActivityDto {
  const KimaiActivityDto({
    required this.id,
    required this.name,
    required this.visible,
    this.projectId,
  });

  final int id;
  final int? projectId;
  final String name;
  final bool visible;

  factory KimaiActivityDto.fromJson(Map<String, Object?> json) {
    final project = json['project'];

    return KimaiActivityDto(
      id: _readInt(json['id']),
      projectId: project is Map<String, Object?>
          ? _readNullableInt(project['id'])
          : _readNullableInt(json['project']),
      name: _readString(json['name']) ?? 'Untitled activity',
      visible: _readBool(json['visible'], fallback: true),
    );
  }
}

class KimaiTagDto {
  const KimaiTagDto({
    required this.id,
    required this.name,
    this.color,
  });

  final String id;
  final String name;
  final String? color;

  factory KimaiTagDto.fromJson(Object? value) {
    if (value is String) {
      final name = value.trim();
      return KimaiTagDto(id: name, name: name);
    }

    if (value is Map<String, Object?>) {
      final name = _readString(value['name']) ??
          _readString(value['label']) ??
          _readString(value['id']) ??
          '';
      final id = _readString(value['id']) ?? name;

      return KimaiTagDto(
        id: id,
        name: name.trim(),
        color: _readString(value['color']),
      );
    }

    return const KimaiTagDto(id: '', name: '');
  }
}

class KimaiCurrentUserDto {
  const KimaiCurrentUserDto({
    required this.id,
    required this.username,
    required this.displayName,
    required this.roles,
  });

  final int id;
  final String username;
  final String displayName;
  final List<String> roles;

  bool get hasAdminReportingCapability {
    return roles.any(
      (role) =>
          role == 'ROLE_ADMIN' ||
          role == 'ROLE_SUPER_ADMIN' ||
          role == 'ROLE_TEAMLEAD' ||
          role == 'view_all_data',
    );
  }

  factory KimaiCurrentUserDto.fromJson(Map<String, Object?> json) {
    return KimaiCurrentUserDto(
      id: _readInt(json['id']),
      username: _readString(json['username']) ?? '',
      displayName: _readDisplayName(json),
      roles: _readStringList(json['roles']),
    );
  }
}

class KimaiUserDto {
  const KimaiUserDto({
    required this.id,
    required this.userName,
    this.alias,
    this.title,
  });

  final int id;
  final String userName;
  final String? alias;
  final String? title;

  String get displayName => alias ?? title ?? userName;

  factory KimaiUserDto.fromJson(Map<String, Object?> json) {
    return KimaiUserDto(
      id: _readInt(json['id']),
      userName: _readString(json['username']) ??
          _readString(json['name']) ??
          'Пользователь #${_readInt(json['id'])}',
      alias: _readString(json['alias']),
      title: _readString(json['title']),
    );
  }
}

class KimaiTimesheetDto {
  const KimaiTimesheetDto({
    required this.id,
    required this.beginAt,
    required this.durationSeconds,
    this.projectId,
    this.projectName,
    this.projectCustomerName,
    this.userId,
    this.userName,
    this.userAlias,
    this.userDisplayName,
    this.userTitle,
    this.activityId,
    this.activityName,
    this.description,
    this.endAt,
    this.rate,
    this.hourlyRate,
    this.currency,
    this.exported = false,
    this.tags,
    this.rawKeys = const [],
    this.tagSourceKeys = const [],
    this.unknownTagShape,
    this.updatedAt,
  });

  final int id;
  final int? projectId;
  final String? projectName;
  final String? projectCustomerName;
  final int? userId;
  final String? userName;
  final String? userAlias;
  final String? userDisplayName;
  final String? userTitle;
  final int? activityId;
  final String? activityName;
  final String? description;
  final DateTime beginAt;
  final DateTime? endAt;
  final int durationSeconds;
  final double? rate;
  final double? hourlyRate;
  final String? currency;
  final bool exported;
  final String? tags;
  final List<String> rawKeys;
  final List<String> tagSourceKeys;
  final String? unknownTagShape;
  final DateTime? updatedAt;

  factory KimaiTimesheetDto.fromJson(Map<String, Object?> json) {
    final project = json['project'];
    final activity = json['activity'];
    final user = json['user'];
    final tags = _readTimesheetTags(json);

    return KimaiTimesheetDto(
      id: _readInt(json['id']),
      projectId: project is Map<String, Object?>
          ? _readNullableInt(project['id'])
          : _readNullableInt(json['project']),
      projectName: project is Map<String, Object?>
          ? _readString(project['name'])
          : _readString(json['projectName']),
      projectCustomerName: project is Map<String, Object?>
          ? _readNestedString(project['customer'], const ['name'])
          : _readString(json['customerName']),
      userId: user is Map<String, Object?>
          ? _readNullableInt(user['id'])
          : _readNullableInt(json['user']),
      userName: user is Map<String, Object?>
          ? _readString(user['username']) ?? _readString(user['name'])
          : _readString(json['userName']) ?? _readString(json['username']),
      userAlias:
          user is Map<String, Object?> ? _readString(user['alias']) : null,
      userDisplayName: user is Map<String, Object?>
          ? _readString(user['displayName'])
          : _readString(json['displayName']),
      userTitle:
          user is Map<String, Object?> ? _readString(user['title']) : null,
      activityId: activity is Map<String, Object?>
          ? _readNullableInt(activity['id'])
          : _readNullableInt(json['activity']),
      activityName: activity is Map<String, Object?>
          ? _readString(activity['name'])
          : _readString(json['activityName']),
      description: _readString(json['description']),
      beginAt: _readDateTime(json['begin']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endAt: _readDateTime(json['end']),
      durationSeconds: _readInt(json['duration'], fallback: 0),
      rate: _readDouble(json['rate']),
      hourlyRate: _readDouble(json['hourlyRate']),
      currency: _readString(json['currency']),
      exported: _readBool(json['exported']),
      tags: tags.tags,
      rawKeys: _sanitizedKeys(json),
      tagSourceKeys: tags.sourceKeys,
      unknownTagShape: tags.unknownShape,
      // TODO: Confirm timesheet update field for the target Kimai version.
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

int _readInt(Object? value, {int fallback = 0}) {
  return _readNullableInt(value) ?? fallback;
}

int? _readNullableInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

String? _readString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  return null;
}

String? _readNestedString(Object? value, List<String> keys) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  for (final key in keys) {
    final result = _readString(value[key]);
    if (result != null) {
      return result;
    }
  }

  return null;
}

String _readDisplayName(Map<String, Object?> json) {
  return _readString(json['alias']) ??
      _readString(json['title']) ??
      _readString(json['username']) ??
      _readString(json['name']) ??
      'Пользователь #${_readInt(json['id'])}';
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList(growable: false);
  }

  return const [];
}

bool _readBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  return fallback;
}

DateTime? _readDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}

({String? tags, List<String> sourceKeys, String? unknownShape})
    _readTimesheetTags(
  Map<String, Object?> json,
) {
  final sourceKeys = <String>[];
  final tags = <String>[];
  String? unknownShape;

  void readKey(String key) {
    if (!json.containsKey(key)) {
      return;
    }
    sourceKeys.add(key);
    final value = json[key];
    final parsed = parseTags(value);
    tags.addAll(parsed);
    if (parsed.isEmpty && value != null) {
      unknownShape ??= '$key=${describeKimaiResponseShape(value)}';
    }
  }

  for (final key in const ['tags', 'tagNames', 'tag', 'meta']) {
    readKey(key);
  }

  return (
    tags: formatTags(tags),
    sourceKeys: sourceKeys,
    unknownShape: unknownShape,
  );
}

List<String> _sanitizedKeys(Map<String, Object?> json) {
  const sensitive = {
    'token',
    'apiToken',
    'password',
    'Authorization',
    'authorization',
  };

  return [
    for (final key in json.keys)
      if (!sensitive.contains(key)) key,
  ]..sort();
}
