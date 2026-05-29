import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';

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
      path: '/api/version',
      method: 'GET',
    );

    return response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;
  }

  Future<List<KimaiProjectDto>> fetchProjects() async {
    final response = await _request<List<dynamic>>(
      path: '/api/projects',
      method: 'GET',
      queryParameters: const {'visible': 3},
    );

    final data = response.data ?? const [];
    return data
        .whereType<Map<String, Object?>>()
        .map(KimaiProjectDto.fromJson)
        .toList(growable: false);
  }

  Future<List<KimaiTimesheetDto>> fetchTimesheets(
    DateTime begin,
    DateTime end,
  ) async {
    final response = await _request<List<dynamic>>(
      path: '/api/timesheets',
      method: 'GET',
      queryParameters: {
        // TODO: Confirm date filter names against the target Kimai version.
        'begin': begin.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
      },
    );

    final data = response.data ?? const [];
    return data
        .whereType<Map<String, Object?>>()
        .map(KimaiTimesheetDto.fromJson)
        .toList(growable: false);
  }

  Future<Response<T>> _request<T>({
    required String path,
    required String method,
    Map<String, Object?>? queryParameters,
  }) async {
    final token = await _tokenStorage.readKimaiToken();
    if (token == null || token.trim().isEmpty) {
      throw KimaiAuthenticationException('Kimai API token is not configured.');
    }

    final baseUri = Uri.parse(_baseUrl);
    final endpoint = baseUri.resolve(path);

    return _dio.request<T>(
      endpoint.toString(),
      options: Options(
        method: method,
        headers: {
          Headers.acceptHeader: Headers.jsonContentType,
          'Authorization': 'Bearer $token',
        },
      ),
      queryParameters: queryParameters,
    );
  }
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

class KimaiTimesheetDto {
  const KimaiTimesheetDto({
    required this.id,
    required this.beginAt,
    required this.durationSeconds,
    this.projectId,
    this.activityName,
    this.description,
    this.endAt,
    this.rate,
    this.currency,
    this.exported = false,
    this.tags,
    this.updatedAt,
  });

  final int id;
  final int? projectId;
  final String? activityName;
  final String? description;
  final DateTime beginAt;
  final DateTime? endAt;
  final int durationSeconds;
  final double? rate;
  final String? currency;
  final bool exported;
  final String? tags;
  final DateTime? updatedAt;

  factory KimaiTimesheetDto.fromJson(Map<String, Object?> json) {
    final project = json['project'];
    final activity = json['activity'];

    return KimaiTimesheetDto(
      id: _readInt(json['id']),
      projectId: project is Map<String, Object?>
          ? _readNullableInt(project['id'])
          : _readNullableInt(json['project']),
      activityName: activity is Map<String, Object?>
          ? _readString(activity['name'])
          : _readString(json['activityName']),
      description: _readString(json['description']),
      beginAt: _readDateTime(json['begin']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endAt: _readDateTime(json['end']),
      durationSeconds: _readInt(json['duration'], fallback: 0),
      rate: _readDouble(json['rate']),
      currency: _readString(json['currency']),
      exported: _readBool(json['exported']),
      tags: _readTags(json['tags']),
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

String? _readTags(Object? value) {
  if (value is List) {
    return value.whereType<Object>().map((item) => item.toString()).join(',');
  }

  return _readString(value);
}
