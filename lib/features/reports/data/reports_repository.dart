import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/kimai_api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/utils/tags.dart';
import '../../settings/data/settings_repository.dart';

enum AppMode {
  performer,
  pmAdmin;

  String get label => switch (this) {
        AppMode.performer => 'Исполнитель',
        AppMode.pmAdmin => 'PM/Admin',
      };
}

enum ReportSortField {
  user,
  project,
  activity,
  duration,
  minutes,
  amount,
  date,
  entriesCount;
}

class ReportProjectOption {
  const ReportProjectOption({
    required this.id,
    required this.name,
  });

  final int? id;
  final String name;
}

class ReportUserOption {
  const ReportUserOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

class ReportAccessInfo {
  const ReportAccessInfo({
    required this.mode,
    required this.detectedAdminCapability,
    required this.currentUserName,
    this.warning,
  });

  final AppMode mode;
  final bool detectedAdminCapability;
  final String currentUserName;
  final String? warning;

  bool get canRequestOtherUsers =>
      mode == AppMode.pmAdmin || detectedAdminCapability;
}

class ReportQuery {
  const ReportQuery({
    required this.begin,
    required this.end,
    this.projectId,
    this.userId,
    this.activity,
    this.tag,
    this.searchText,
    this.sortField = ReportSortField.user,
    this.sortAscending = true,
  });

  final int? projectId;
  final DateTime begin;
  final DateTime end;
  final int? userId;
  final String? activity;
  final String? tag;
  final String? searchText;
  final ReportSortField sortField;
  final bool sortAscending;
}

class ReportTimesheetEntry {
  const ReportTimesheetEntry({
    required this.userId,
    required this.userName,
    required this.projectId,
    required this.projectName,
    required this.activity,
    required this.tags,
    required this.description,
    required this.begin,
    required this.end,
    required this.durationSeconds,
    required this.durationHuman,
    required this.rateMinor,
    required this.amountMinor,
  });

  final int? userId;
  final String userName;
  final int? projectId;
  final String projectName;
  final String activity;
  final String tags;
  final String description;
  final DateTime begin;
  final DateTime? end;
  final int durationSeconds;
  final String durationHuman;
  final int? rateMinor;
  final int? amountMinor;

  int get durationMinutes => (durationSeconds / 60).round();
}

class UserReportSummary {
  const UserReportSummary({
    required this.userName,
    required this.projectNames,
    required this.totalDurationSeconds,
    required this.totalAmountMinor,
    required this.entriesCount,
  });

  final String userName;
  final List<String> projectNames;
  final int totalDurationSeconds;
  final int totalAmountMinor;
  final int entriesCount;

  int get totalMinutes => (totalDurationSeconds / 60).round();
}

class ProjectReportSummary {
  const ProjectReportSummary({
    required this.projectName,
    required this.userCount,
    required this.totalDurationSeconds,
    required this.totalAmountMinor,
    required this.entriesCount,
  });

  final String projectName;
  final int userCount;
  final int totalDurationSeconds;
  final int totalAmountMinor;
  final int entriesCount;

  int get totalMinutes => (totalDurationSeconds / 60).round();
}

class ReportResult {
  const ReportResult({
    required this.entries,
    required this.userSummaries,
    required this.projectSummaries,
    required this.warnings,
    required this.diagnostics,
  });

  final List<ReportTimesheetEntry> entries;
  final List<UserReportSummary> userSummaries;
  final List<ProjectReportSummary> projectSummaries;
  final List<String> warnings;
  final String diagnostics;
}

class ReportsRepository {
  ReportsRepository({
    required AppDatabase database,
    required KimaiApiClient apiClient,
  })  : _database = database,
        _apiClient = apiClient;

  final AppDatabase _database;
  final KimaiApiClient _apiClient;

  Future<List<ReportProjectOption>> getProjects() async {
    final rows = await (_database.select(_database.kimaiProjects)
          ..orderBy([
            (table) => OrderingTerm.asc(table.customerName),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();

    return [
      const ReportProjectOption(id: null, name: 'Все проекты'),
      for (final row in rows)
        ReportProjectOption(
          id: row.id,
          name: row.customerName == null
              ? row.name
              : '${row.customerName} / ${row.name}',
        ),
    ];
  }

  Future<ReportAccessInfo> getAccessInfo() async {
    final settings = await _databaseSettingMode();
    try {
      final currentUser = await _apiClient.fetchCurrentUser();
      final detected = currentUser.hasAdminReportingCapability;

      return ReportAccessInfo(
        mode: settings ? AppMode.pmAdmin : AppMode.performer,
        detectedAdminCapability: detected,
        currentUserName: currentUser.displayName,
      );
    } on Object catch (error) {
      return ReportAccessInfo(
        mode: settings ? AppMode.pmAdmin : AppMode.performer,
        detectedAdminCapability: false,
        currentUserName: '',
        warning: 'Не удалось определить роли Kimai: $error',
      );
    }
  }

  Future<List<ReportUserOption>> getUsers() async {
    try {
      final users = await _apiClient.fetchUsers();
      return [
        for (final user in users)
          ReportUserOption(id: user.id, name: user.displayName),
      ]..sort((a, b) => a.name.compareTo(b.name));
    } on KimaiApiException catch (error) {
      final status = error.details.statusCode;
      if (status == 403 || status == 404 || status == 405) {
        return const [];
      }
      rethrow;
    }
  }

  Future<ReportResult> buildReport(ReportQuery query) async {
    try {
      final result = await _apiClient.fetchTimesheetsForReport(
        projectId: query.projectId,
        begin: query.begin,
        end: query.end,
        userId: query.userId,
      );
      final entries = result.entries
          .map((item) => _mapEntry(item, fallbackProjectId: query.projectId))
          .where((item) => _matchesActivity(item, query.activity))
          .where((item) => _matchesTag(item, query.tag))
          .where((item) => _matchesSearch(item, query.searchText))
          .toList(growable: false);
      final sortedEntries = _sortEntries(entries, query);
      final userSummaries = _sortUserSummaries(
        _userSummaries(sortedEntries),
        query,
      );
      final projectSummaries = _sortProjectSummaries(
        _projectSummaries(sortedEntries),
        query,
      );
      final missingAmounts = sortedEntries
          .where(
            (entry) => entry.durationSeconds > 0 && entry.amountMinor == null,
          )
          .length;
      final missingNames = result.entries.where(_hasMissingName).length;

      return ReportResult(
        entries: sortedEntries,
        userSummaries: userSummaries,
        projectSummaries: projectSummaries,
        warnings: [
          if (missingAmounts > 0)
            'Для $missingAmounts записей Kimai не вернул сумму. Ставки пользователей не подставлялись.',
          if (missingNames > 0)
            'Для $missingNames записей Kimai не вернул полные имена. Диагностика содержит ключи ответа без чувствительных данных.',
        ],
        diagnostics: [
          result.toDiagnosticString(),
          _missingNameDiagnostics(result.entries),
        ].where((value) => value.isNotEmpty).join('\n'),
      );
    } on KimaiApiException catch (error) {
      if (error.details.statusCode == 403) {
        throw const ReportPermissionException(
          'Недостаточно прав для отчёта по людям',
        );
      }
      rethrow;
    }
  }

  Future<bool> _databaseSettingMode() async {
    final row = await (_database.select(_database.syncState)
          ..where(
            (table) => table.key.equals(SettingsRepository.pmAdminModeKey),
          ))
        .getSingleOrNull();

    return row?.value == 'true';
  }

  ReportTimesheetEntry _mapEntry(
    KimaiTimesheetDto item, {
    required int? fallbackProjectId,
  }) {
    final userName = item.userAlias ??
        item.userDisplayName ??
        item.userName ??
        item.userTitle ??
        (item.userId == null
            ? 'Неизвестный пользователь'
            : 'Пользователь #${item.userId}');
    final projectId = item.projectId ?? fallbackProjectId;
    final amountMinor = _moneyToMinor(item.rate);

    return ReportTimesheetEntry(
      userId: item.userId,
      userName: userName,
      projectId: projectId,
      projectName: _projectName(item, projectId),
      activity: item.activityName ??
          (item.activityId == null
              ? 'Без активности'
              : 'Активность #${item.activityId}'),
      tags: item.tags ?? '',
      description: item.description ?? '',
      begin: item.beginAt,
      end: item.endAt,
      durationSeconds: item.durationSeconds,
      durationHuman: formatDurationSeconds(item.durationSeconds),
      rateMinor: _moneyToMinor(item.hourlyRate),
      amountMinor: amountMinor,
    );
  }

  String _projectName(KimaiTimesheetDto item, int? projectId) {
    final projectName = item.projectName;
    if (projectName != null && projectName.trim().isNotEmpty) {
      final customer = item.projectCustomerName;
      return customer == null || customer.trim().isEmpty
          ? projectName
          : '$customer / $projectName';
    }

    return projectId == null ? 'Неизвестный проект' : 'Проект #$projectId';
  }

  bool _matchesActivity(ReportTimesheetEntry item, String? activity) {
    final value = activity?.trim();
    if (value == null || value.isEmpty) {
      return true;
    }

    return item.activity.toLowerCase().contains(value.toLowerCase());
  }

  bool _matchesTag(ReportTimesheetEntry item, String? tag) {
    final value = tag?.trim();
    if (value == null || value.isEmpty) {
      return true;
    }

    return tagsContain(item.tags, value);
  }

  bool _matchesSearch(ReportTimesheetEntry item, String? searchText) {
    final value = searchText?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return true;
    }

    return [
      item.userName,
      item.projectName,
      item.activity,
      item.tags,
      item.description,
    ].any((field) => field.toLowerCase().contains(value));
  }

  List<UserReportSummary> _userSummaries(List<ReportTimesheetEntry> entries) {
    final grouped = <String, List<ReportTimesheetEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.userName, () => []).add(entry);
    }

    return [
      for (final entry in grouped.entries)
        UserReportSummary(
          userName: entry.key,
          projectNames:
              entry.value.map((item) => item.projectName).toSet().toList()
                ..sort(),
          totalDurationSeconds: entry.value.fold(
            0,
            (sum, item) => sum + item.durationSeconds,
          ),
          totalAmountMinor: entry.value.fold(
            0,
            (sum, item) => sum + (item.amountMinor ?? 0),
          ),
          entriesCount: entry.value.length,
        ),
    ];
  }

  List<ProjectReportSummary> _projectSummaries(
    List<ReportTimesheetEntry> entries,
  ) {
    final grouped = <String, List<ReportTimesheetEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.projectName, () => []).add(entry);
    }

    return [
      for (final entry in grouped.entries)
        ProjectReportSummary(
          projectName: entry.key,
          userCount: entry.value.map((item) => item.userName).toSet().length,
          totalDurationSeconds: entry.value.fold(
            0,
            (sum, item) => sum + item.durationSeconds,
          ),
          totalAmountMinor: entry.value.fold(
            0,
            (sum, item) => sum + (item.amountMinor ?? 0),
          ),
          entriesCount: entry.value.length,
        ),
    ];
  }

  List<ReportTimesheetEntry> _sortEntries(
    List<ReportTimesheetEntry> entries,
    ReportQuery query,
  ) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      final result = switch (query.sortField) {
        ReportSortField.user => a.userName.compareTo(b.userName),
        ReportSortField.project => a.projectName.compareTo(b.projectName),
        ReportSortField.activity => a.activity.compareTo(b.activity),
        ReportSortField.duration =>
          a.durationSeconds.compareTo(b.durationSeconds),
        ReportSortField.minutes =>
          a.durationMinutes.compareTo(b.durationMinutes),
        ReportSortField.amount =>
          (a.amountMinor ?? 0).compareTo(b.amountMinor ?? 0),
        ReportSortField.date => a.begin.compareTo(b.begin),
        ReportSortField.entriesCount => a.userName.compareTo(b.userName),
      };

      return query.sortAscending ? result : -result;
    });

    return sorted;
  }

  List<UserReportSummary> _sortUserSummaries(
    List<UserReportSummary> summaries,
    ReportQuery query,
  ) {
    final sorted = [...summaries];
    sorted.sort((a, b) {
      final result = switch (query.sortField) {
        ReportSortField.user ||
        ReportSortField.project ||
        ReportSortField.activity ||
        ReportSortField.date =>
          a.userName.compareTo(b.userName),
        ReportSortField.duration =>
          a.totalDurationSeconds.compareTo(b.totalDurationSeconds),
        ReportSortField.minutes => a.totalMinutes.compareTo(b.totalMinutes),
        ReportSortField.amount =>
          a.totalAmountMinor.compareTo(b.totalAmountMinor),
        ReportSortField.entriesCount =>
          a.entriesCount.compareTo(b.entriesCount),
      };

      return query.sortAscending ? result : -result;
    });

    return sorted;
  }

  List<ProjectReportSummary> _sortProjectSummaries(
    List<ProjectReportSummary> summaries,
    ReportQuery query,
  ) {
    final sorted = [...summaries];
    sorted.sort((a, b) {
      final result = switch (query.sortField) {
        ReportSortField.project ||
        ReportSortField.user ||
        ReportSortField.activity ||
        ReportSortField.date =>
          a.projectName.compareTo(b.projectName),
        ReportSortField.duration =>
          a.totalDurationSeconds.compareTo(b.totalDurationSeconds),
        ReportSortField.minutes => a.totalMinutes.compareTo(b.totalMinutes),
        ReportSortField.amount =>
          a.totalAmountMinor.compareTo(b.totalAmountMinor),
        ReportSortField.entriesCount =>
          a.entriesCount.compareTo(b.entriesCount),
      };

      return query.sortAscending ? result : -result;
    });

    return sorted;
  }

  bool _hasMissingName(KimaiTimesheetDto item) {
    return item.projectName == null ||
        (item.userAlias == null &&
            item.userDisplayName == null &&
            item.userName == null &&
            item.userTitle == null) ||
        item.activityName == null ||
        item.unknownTagShape != null;
  }

  String _missingNameDiagnostics(List<KimaiTimesheetDto> entries) {
    final lines = <String>[];
    for (final entry in entries.where(_hasMissingName).take(20)) {
      lines.add(
        [
          'timesheet_id=${entry.id}',
          'keys=${entry.rawKeys.join(',')}',
          if (entry.tagSourceKeys.isNotEmpty)
            'tag_keys=${entry.tagSourceKeys.join(',')}',
          if (entry.unknownTagShape != null)
            'unknown_tag_shape=${entry.unknownTagShape}',
        ].join(' '),
      );
    }

    return lines.isEmpty
        ? ''
        : ['missing_name_diagnostics', ...lines].join('\n');
  }
}

class ReportPermissionException implements Exception {
  const ReportPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

final reportsRepositoryProvider =
    FutureProvider<ReportsRepository>((ref) async {
  final apiClient = await ref.watch(kimaiApiClientProvider.future);

  return ReportsRepository(
    database: ref.watch(appDatabaseProvider),
    apiClient: apiClient,
  );
});

final reportProjectsProvider =
    FutureProvider.autoDispose<List<ReportProjectOption>>((ref) async {
  final repository = await ref.watch(reportsRepositoryProvider.future);

  return repository.getProjects();
});

final reportUsersProvider =
    FutureProvider.autoDispose<List<ReportUserOption>>((ref) async {
  final repository = await ref.watch(reportsRepositoryProvider.future);

  return repository.getUsers();
});

final reportAccessInfoProvider =
    FutureProvider.autoDispose<ReportAccessInfo>((ref) async {
  final repository = await ref.watch(reportsRepositoryProvider.future);

  return repository.getAccessInfo();
});

int? _moneyToMinor(double? value) {
  if (value == null) {
    return null;
  }

  return (value * 100).round();
}
