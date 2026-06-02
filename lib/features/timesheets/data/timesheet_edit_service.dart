import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/kimai_api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/tags.dart';
import 'timesheets_repository.dart';

class TimesheetEditException implements Exception {
  const TimesheetEditException(this.message, [this.details]);

  final String message;
  final Object? details;

  @override
  String toString() {
    if (details == null) {
      return message;
    }

    return '$message\n$details';
  }
}

class TimesheetEditService {
  TimesheetEditService(this._ref);

  final Ref _ref;

  Future<void> save(TimesheetEditInput input) async {
    _validate(input);
    final kimaiTimesheetId = input.kimaiTimesheetId;

    if (kimaiTimesheetId == null) {
      await _ref.read(timesheetsRepositoryProvider).updateLocalTimesheet(input);
      return;
    }

    final repository = _ref.read(timesheetsRepositoryProvider);
    try {
      final client = await _ref.read(kimaiApiClientProvider.future);
      final remote = await client.updateTimesheet(
        kimaiTimesheetId: kimaiTimesheetId,
        projectId: input.kimaiProjectId,
        activityId: input.activityId,
        beginAt: input.beginAt.toUtc(),
        endAt: _normalizedEndAt(input.beginAt, input.endAt),
        description: input.description ?? '',
        tags: formatTags(parseTags(input.tags)),
      );
      await repository.applyRemoteEdit(remote);
    } catch (error) {
      if (input.entryId.startsWith('local_')) {
        await repository.markLocalEditFailed(
          input.entryId,
          _diagnosticError(error),
        );
      }
      throw TimesheetEditException(_messageFor(error), _diagnosticError(error));
    }
  }

  Future<void> delete(TimesheetEntry entry) async {
    final repository = _ref.read(timesheetsRepositoryProvider);
    final kimaiTimesheetId = entry.kimaiTimesheetId;

    if (kimaiTimesheetId == null) {
      await repository.deleteLocalTimeEntry(entry.id);
      return;
    }

    try {
      final client = await _ref.read(kimaiApiClientProvider.future);
      await client.deleteTimesheet(kimaiTimesheetId);
      if (entry.isLocal) {
        await repository.deleteLocalTimeEntry(entry.id);
      }
      await repository.deleteRemoteTimesheet(kimaiTimesheetId);
    } catch (error) {
      if (_isAlreadyDeleted(error)) {
        if (entry.isLocal) {
          await repository.deleteLocalTimeEntry(entry.id);
        }
        await repository.deleteRemoteTimesheet(kimaiTimesheetId);
        return;
      }
      throw TimesheetEditException(
        'Не удалось удалить запись в Kimai. Локальные данные не изменены.',
        _diagnosticError(error),
      );
    }
  }

  void _validate(TimesheetEditInput input) {
    if (!input.endAt.isAfter(input.beginAt)) {
      throw const TimesheetEditException('Окончание должно быть позже начала.');
    }
  }

  DateTime _normalizedEndAt(DateTime beginAt, DateTime endAt) {
    final begin = beginAt.toUtc();
    final end = endAt.toUtc();
    final minimumEnd = begin.add(const Duration(minutes: 1));

    return end.isBefore(minimumEnd) ? minimumEnd : end;
  }

  String _messageFor(Object error) {
    if (error is KimaiApiException) {
      final statusCode = error.details.statusCode;
      if (statusCode == 400 || statusCode == 403 || statusCode == 422) {
        return 'Kimai не разрешил изменить эту запись. Вероятно, истёк лимит редактирования.';
      }
    }

    return 'Не удалось изменить запись в Kimai. Локальные данные не изменены.';
  }

  bool _isAlreadyDeleted(Object error) {
    if (error is KimaiApiException) {
      return error.details.statusCode == 404 || error.details.statusCode == 410;
    }

    return false;
  }

  Object _diagnosticError(Object error) {
    if (error is KimaiApiException) {
      return error.details.toDiagnosticString(syncType: 'timesheet_edit');
    }
    if (error is DioException) {
      return error.message ?? error.toString();
    }

    return error;
  }
}

final timesheetEditServiceProvider =
    Provider<TimesheetEditService>(TimesheetEditService.new);
