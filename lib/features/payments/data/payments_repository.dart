import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../local_tracking/data/local_tracking_repository.dart';
import '../../projects/data/projects_repository.dart';
import '../../settings/data/settings_repository.dart';

enum PaymentStatus {
  expected,
  overdue,
  paid,
  assumedPaid,
  skipped,
  disputed;

  String get storageValue => switch (this) {
        PaymentStatus.expected => 'expected',
        PaymentStatus.overdue => 'overdue',
        PaymentStatus.paid => 'paid',
        PaymentStatus.assumedPaid => 'assumed_paid',
        PaymentStatus.skipped => 'skipped',
        PaymentStatus.disputed => 'disputed',
      };

  String get label => switch (this) {
        PaymentStatus.expected => 'Ожидается',
        PaymentStatus.overdue => 'Просрочено',
        PaymentStatus.paid => 'Оплачено',
        PaymentStatus.assumedPaid => 'Предположительно оплачено',
        PaymentStatus.skipped => 'Пропущено',
        PaymentStatus.disputed => 'Спорно',
      };

  static PaymentStatus fromStorage(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => PaymentStatus.expected,
    );
  }
}

class PaymentItem {
  const PaymentItem({
    required this.id,
    required this.kimaiProjectId,
    required this.projectName,
    required this.color,
    required this.payoutDate,
    required this.periodStart,
    required this.periodEnd,
    required this.expectedAmountMinor,
    required this.trackedSeconds,
    required this.requiredSeconds,
    required this.status,
    required this.isActivePeriod,
    this.actualAmountMinor,
    this.paidAt,
    this.note,
  });

  final String id;
  final int kimaiProjectId;
  final String projectName;
  final String? color;
  final DateTime payoutDate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int expectedAmountMinor;
  final int trackedSeconds;
  final int requiredSeconds;
  final PaymentStatus status;
  final bool isActivePeriod;
  final int? actualAmountMinor;
  final DateTime? paidAt;
  final String? note;

  int get balanceSeconds => trackedSeconds - requiredSeconds;

  bool get isMeaningfulUpcoming {
    return (status == PaymentStatus.expected ||
            status == PaymentStatus.overdue) &&
        (expectedAmountMinor > 0 || isActivePeriod);
  }
}

class PaymentPeriodProgress {
  const PaymentPeriodProgress({
    required this.projectName,
    required this.color,
    required this.periodStart,
    required this.periodEnd,
    required this.payoutDate,
    required this.requiredSeconds,
    required this.trackedSeconds,
    required this.expectedAmountMinor,
  });

  final String projectName;
  final String? color;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime payoutDate;
  final int requiredSeconds;
  final int trackedSeconds;
  final int expectedAmountMinor;

  int get balanceSeconds => trackedSeconds - requiredSeconds;
}

class PaymentsSnapshot {
  const PaymentsSnapshot({
    required this.all,
    required this.expected,
    required this.overdue,
    required this.paid,
    required this.assumedPaid,
    required this.problematic,
    required this.periodProgress,
  });

  final List<PaymentItem> all;
  final List<PaymentItem> expected;
  final List<PaymentItem> overdue;
  final List<PaymentItem> paid;
  final List<PaymentItem> assumedPaid;
  final List<PaymentItem> problematic;
  final List<PaymentPeriodProgress> periodProgress;

  List<PaymentItem> get nextExpected {
    final items = [...overdue, ...expected]
      ..sort((a, b) => a.payoutDate.compareTo(b.payoutDate));

    return items.where((item) => item.isMeaningfulUpcoming).take(3).toList();
  }
}

class PaymentPeriod {
  const PaymentPeriod({
    required this.start,
    required this.end,
    required this.payoutDate,
  });

  final DateTime start;
  final DateTime end;
  final DateTime payoutDate;

  bool contains(DateTime day) {
    final value = _dateOnly(day);
    return !value.isBefore(start) && value.isBefore(end);
  }
}

class PaymentsRepository {
  PaymentsRepository(
    this._database, {
    SettingsRepository? settingsRepository,
  }) : _settingsRepository = settingsRepository;

  final AppDatabase _database;
  final SettingsRepository? _settingsRepository;

  Stream<PaymentsSnapshot> watchPayments() {
    return _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM app_projects '
          'UNION ALL SELECT COUNT(*) FROM payout_dates '
          'UNION ALL SELECT COUNT(*) FROM timesheets '
          'UNION ALL SELECT COUNT(*) FROM local_time_entries '
          'UNION ALL SELECT COUNT(*) FROM payments '
          'UNION ALL SELECT COUNT(*) FROM sync_state',
          readsFrom: {
            _database.appProjects,
            _database.payoutDates,
            _database.timesheets,
            _database.localTimeEntries,
            _database.payments,
            _database.syncState,
          },
        )
        .watch()
        .asyncMap((_) => getPayments());
  }

  Future<PaymentsSnapshot> getPayments() async {
    final generated = await _generatePayments();
    final stored = await _storedPaymentItems();
    final byId = {for (final item in generated.items) item.id: item};

    for (final item in stored) {
      byId[item.id] = _mergeStoredWithGenerated(
        stored: item,
        generated: byId[item.id],
      );
    }

    final all = byId.values.toList()
      ..sort((a, b) => a.payoutDate.compareTo(b.payoutDate));

    return PaymentsSnapshot(
      all: all,
      expected: all
          .where((item) => item.status == PaymentStatus.expected)
          .toList(growable: false),
      overdue: all
          .where((item) => item.status == PaymentStatus.overdue)
          .toList(growable: false),
      paid: all
          .where((item) => item.status == PaymentStatus.paid)
          .toList(growable: false),
      assumedPaid: all
          .where((item) => item.status == PaymentStatus.assumedPaid)
          .toList(growable: false),
      problematic: all
          .where(
            (item) =>
                item.status == PaymentStatus.skipped ||
                item.status == PaymentStatus.disputed,
          )
          .toList(growable: false),
      periodProgress: generated.periodProgress,
    );
  }

  Future<void> markPaid(
    PaymentItem item, {
    int? actualAmountMinor,
    DateTime? paidAt,
    String? note,
  }) {
    return _upsertPayment(
      item,
      status: PaymentStatus.paid,
      actualAmountMinor: actualAmountMinor ?? item.expectedAmountMinor,
      paidAt: paidAt ?? DateTime.now(),
      note: note,
    );
  }

  Future<void> markPastPayoutsAssumedPaid() async {
    final snapshot = await getPayments();
    final today = _today();
    final candidates = snapshot.all.where(
      (item) =>
          item.payoutDate.isBefore(today) &&
          item.expectedAmountMinor > 0 &&
          (item.status == PaymentStatus.expected ||
              item.status == PaymentStatus.overdue),
    );

    for (final item in candidates) {
      await _upsertPayment(
        item,
        status: PaymentStatus.assumedPaid,
        actualAmountMinor: item.expectedAmountMinor,
        paidAt: item.payoutDate,
      );
    }
  }

  Future<void> updatePayment(
    PaymentItem item, {
    required PaymentStatus status,
    int? actualAmountMinor,
    DateTime? paidAt,
    String? note,
  }) {
    return _upsertPayment(
      item,
      status: status,
      actualAmountMinor: actualAmountMinor,
      paidAt: paidAt,
      note: note,
    );
  }

  Future<void> deletePaymentStatus(String id) {
    return (_database.delete(_database.payments)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  Future<void> _upsertPayment(
    PaymentItem item, {
    required PaymentStatus status,
    int? actualAmountMinor,
    DateTime? paidAt,
    String? note,
  }) async {
    final now = DateTime.now().toUtc();
    await _database.into(_database.payments).insertOnConflictUpdate(
          PaymentsCompanion.insert(
            id: item.id,
            kimaiProjectId: item.kimaiProjectId,
            payoutDate: item.payoutDate,
            periodStart: item.periodStart,
            periodEnd: item.periodEnd,
            expectedAmountMinor: item.expectedAmountMinor,
            actualAmountMinor: Value(actualAmountMinor),
            status: status.storageValue,
            paidAt: Value(paidAt),
            note: Value(note),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<
      ({
        List<PaymentItem> items,
        List<PaymentPeriodProgress> periodProgress
      })> _generatePayments() async {
    final rows = await _projectRows();
    final customDates = await _database.select(_database.payoutDates).get();
    final settings =
        await (_settingsRepository ?? SettingsRepository(_database))
            .loadSettings();
    final today = _today();
    final beginWindow = today.subtract(const Duration(days: 90));
    final endWindow = today.add(const Duration(days: 75));
    final result = <PaymentItem>[];
    final progress = <PaymentPeriodProgress>[];

    for (final row in rows) {
      final appProject = row.readTable(_database.appProjects);
      final kimaiProject = row.readTable(_database.kimaiProjects);
      if (!appProject.enabled ||
          appProject.kimaiProjectId == null ||
          appProject.payoutRule == PayoutRule.none.storageValue) {
        continue;
      }

      final periods = buildPayoutPeriods(
        rule: appProject.payoutRule,
        anchorDate: appProject.payoutAnchorDate,
        from: beginWindow,
        to: endWindow,
        customDates: customDates
            .where((date) => date.appProjectId == appProject.id)
            .map((date) => date.payoutDate)
            .toList(),
      );

      for (final period in periods) {
        final isActive = period.contains(today);
        final calculationEnd =
            period.end.isAfter(today.add(const Duration(days: 1)))
                ? today.add(const Duration(days: 1))
                : period.end;
        final totals = await _totalsForPeriod(
          appProject.id,
          period.start,
          calculationEnd,
        );
        final amount = totals.amountMinor;
        final status = _generatedStatus(
          payoutDate: period.payoutDate,
          amountMinor: amount,
          today: today,
          assumePastPaid: settings.assumePastPayoutsPaid,
        );

        if (_shouldHideGeneratedPayment(
          amountMinor: amount,
          period: period,
          today: today,
        )) {
          continue;
        }

        final weeks = math.max(
          1,
          (period.end.difference(period.start).inDays / 7).ceil(),
        );
        final requiredSeconds =
            ((appProject.weeklyGoalHours ?? 0) * weeks * 3600).round();
        final item = PaymentItem(
          id: _paymentId(kimaiProject.id, period.payoutDate),
          kimaiProjectId: kimaiProject.id,
          projectName: kimaiProject.name,
          color: appProject.color ?? kimaiProject.color,
          payoutDate: period.payoutDate,
          periodStart: period.start,
          periodEnd: period.end,
          expectedAmountMinor: amount,
          trackedSeconds: totals.seconds,
          requiredSeconds: requiredSeconds,
          status: status,
          isActivePeriod: isActive,
          actualAmountMinor:
              status == PaymentStatus.assumedPaid ? amount : null,
          paidAt:
              status == PaymentStatus.assumedPaid ? period.payoutDate : null,
        );
        result.add(item);

        if (isActive) {
          progress.add(
            PaymentPeriodProgress(
              projectName: kimaiProject.name,
              color: appProject.color ?? kimaiProject.color,
              periodStart: period.start,
              periodEnd: period.end,
              payoutDate: period.payoutDate,
              requiredSeconds: requiredSeconds,
              trackedSeconds: totals.seconds,
              expectedAmountMinor: amount,
            ),
          );
        }
      }
    }

    progress.sort((a, b) => a.payoutDate.compareTo(b.payoutDate));
    return (items: result, periodProgress: progress);
  }

  Future<List<PaymentItem>> _storedPaymentItems() async {
    final rows = await _database.select(_database.payments).join([
      innerJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(_database.payments.kimaiProjectId),
      ),
      leftOuterJoin(
        _database.appProjects,
        _database.appProjects.kimaiProjectId
            .equalsExp(_database.payments.kimaiProjectId),
      ),
    ]).get();

    return [
      for (final row in rows)
        _storedPaymentItem(
          payment: row.readTable(_database.payments),
          kimaiProject: row.readTable(_database.kimaiProjects),
          appProject: row.readTableOrNull(_database.appProjects),
        ),
    ];
  }

  PaymentItem _storedPaymentItem({
    required Payment payment,
    required KimaiProject kimaiProject,
    required AppProject? appProject,
  }) {
    return PaymentItem(
      id: payment.id,
      kimaiProjectId: payment.kimaiProjectId,
      projectName: kimaiProject.name,
      color: appProject?.color ?? kimaiProject.color,
      payoutDate: payment.payoutDate,
      periodStart: payment.periodStart,
      periodEnd: payment.periodEnd,
      expectedAmountMinor: payment.expectedAmountMinor,
      trackedSeconds: 0,
      requiredSeconds: 0,
      actualAmountMinor: payment.actualAmountMinor,
      status: PaymentStatus.fromStorage(payment.status),
      paidAt: payment.paidAt,
      note: payment.note,
      isActivePeriod: false,
    );
  }

  PaymentItem _mergeStoredWithGenerated({
    required PaymentItem stored,
    required PaymentItem? generated,
  }) {
    if (generated == null) {
      return stored;
    }

    return PaymentItem(
      id: stored.id,
      kimaiProjectId: stored.kimaiProjectId,
      projectName: generated.projectName,
      color: generated.color,
      payoutDate: generated.payoutDate,
      periodStart: generated.periodStart,
      periodEnd: generated.periodEnd,
      expectedAmountMinor: generated.expectedAmountMinor,
      trackedSeconds: generated.trackedSeconds,
      requiredSeconds: generated.requiredSeconds,
      status: stored.status,
      isActivePeriod: generated.isActivePeriod,
      actualAmountMinor: stored.actualAmountMinor,
      paidAt: stored.paidAt,
      note: stored.note,
    );
  }

  Future<({int amountMinor, int seconds})> _totalsForPeriod(
    String appProjectId,
    DateTime begin,
    DateTime end,
  ) async {
    if (!end.isAfter(begin)) {
      return (amountMinor: 0, seconds: 0);
    }

    final rows = await (_database.select(_database.timesheets)
          ..where((table) => table.appProjectId.equals(appProjectId))
          ..where((table) => table.beginAt.isBiggerOrEqualValue(begin))
          ..where((table) => table.beginAt.isSmallerThanValue(end)))
        .get();
    final localRows = await (_database.select(_database.localTimeEntries)
          ..where((table) => table.projectId.equals(appProjectId))
          ..where((table) => table.beginAt.isBiggerOrEqualValue(begin))
          ..where((table) => table.beginAt.isSmallerThanValue(end))
          ..where(
            (table) =>
                table.status.equals(LocalTimeEntryStatus.running.storageValue) |
                table.status.equals(
                  LocalTimeEntryStatus.syncingStart.storageValue,
                ) |
                table.status.equals(
                  LocalTimeEntryStatus.runningLocal.storageValue,
                ) |
                table.status.equals(
                  LocalTimeEntryStatus.syncPending.storageValue,
                ) |
                table.status.equals(
                  LocalTimeEntryStatus.syncFailed.storageValue,
                ) |
                table.status.equals(
                  LocalTimeEntryStatus.stopFailed.storageValue,
                ) |
                table.status.equals(LocalTimeEntryStatus.conflict.storageValue),
          ))
        .get();
    final project = await (_database.select(_database.appProjects)
          ..where((table) => table.id.equals(appProjectId)))
        .getSingleOrNull();
    final localSeconds = localRows.fold<int>(
      0,
      (sum, row) => sum + _localDisplayDuration(row),
    );
    final localAmount = localRows.fold<int>(
      0,
      (sum, row) =>
          sum +
          (project?.hourlyRateMinor == null
              ? 0
              : (_localDisplayDuration(row) * project!.hourlyRateMinor! / 3600)
                  .round()),
    );

    final remoteSeconds = rows.fold<int>(
      0,
      (sum, row) => sum + _remoteDisplayDuration(row),
    );
    final remoteAmount = rows.fold<int>(
      0,
      (sum, row) =>
          sum +
          (row.endAt == null && project?.hourlyRateMinor != null
              ? (_remoteDisplayDuration(row) * project!.hourlyRateMinor! / 3600)
                  .round()
              : (row.amountMinor ?? 0)),
    );

    return (
      amountMinor: remoteAmount + localAmount,
      seconds: remoteSeconds + localSeconds,
    );
  }

  Future<List<TypedResult>> _projectRows() {
    return _database.select(_database.appProjects).join([
      innerJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id
            .equalsExp(_database.appProjects.kimaiProjectId),
      ),
    ]).get();
  }
}

List<PaymentPeriod> buildPayoutPeriods({
  required String rule,
  required DateTime? anchorDate,
  required DateTime from,
  required DateTime to,
  required List<DateTime> customDates,
}) {
  final periods = <PaymentPeriod>[];
  final startBoundary = _dateOnly(from);
  final endBoundary = _dateOnly(to);
  final anchor = _dateOnly(anchorDate ?? DateTime.now());

  if (rule == PayoutRule.customDates.storageValue) {
    final dates = customDates.map(_dateOnly).toList()..sort();
    for (var index = 0; index < dates.length; index++) {
      final payoutDate = dates[index];
      if (payoutDate.isBefore(startBoundary) ||
          payoutDate.isAfter(endBoundary)) {
        continue;
      }
      final previous = index == 0
          ? payoutDate.subtract(const Duration(days: 30))
          : dates[index - 1];
      periods.add(
        PaymentPeriod(start: previous, end: payoutDate, payoutDate: payoutDate),
      );
    }
    return periods;
  }

  if (rule == PayoutRule.monthly.storageValue) {
    var payoutDate = _monthlyPayoutDate(anchor, startBoundary);
    while (payoutDate.isBefore(startBoundary)) {
      payoutDate = _addMonthsFromAnchor(anchor, payoutDate, 1);
    }

    while (!payoutDate.isAfter(endBoundary)) {
      final previous = _addMonthsFromAnchor(anchor, payoutDate, -1);
      periods.add(
        PaymentPeriod(start: previous, end: payoutDate, payoutDate: payoutDate),
      );
      payoutDate = _addMonthsFromAnchor(anchor, payoutDate, 1);
    }
    return periods;
  }

  final step = rule == PayoutRule.triweekly.storageValue ? 21 : 14;
  var payoutDate = anchor;
  while (payoutDate.isBefore(startBoundary)) {
    payoutDate = payoutDate.add(Duration(days: step));
  }
  while (!payoutDate.isAfter(endBoundary)) {
    final start = payoutDate.subtract(Duration(days: step));
    periods.add(
      PaymentPeriod(start: start, end: payoutDate, payoutDate: payoutDate),
    );
    payoutDate = payoutDate.add(Duration(days: step));
  }

  return periods;
}

PaymentStatus _generatedStatus({
  required DateTime payoutDate,
  required int amountMinor,
  required DateTime today,
  required bool assumePastPaid,
}) {
  if (payoutDate.isBefore(today)) {
    if (assumePastPaid && amountMinor > 0) {
      return PaymentStatus.assumedPaid;
    }

    return PaymentStatus.overdue;
  }

  return PaymentStatus.expected;
}

bool _shouldHideGeneratedPayment({
  required int amountMinor,
  required PaymentPeriod period,
  required DateTime today,
}) {
  if (amountMinor > 0 || period.contains(today)) {
    return false;
  }

  return period.payoutDate.isAfter(today);
}

DateTime _monthlyPayoutDate(DateTime anchor, DateTime boundary) {
  var date = _sameDayOrMonthEnd(boundary.year, boundary.month, anchor.day);
  if (date.isBefore(boundary)) {
    date = _addMonthsFromAnchor(anchor, date, 1);
  }

  return date;
}

DateTime _addMonthsFromAnchor(DateTime anchor, DateTime fromDate, int delta) {
  return _sameDayOrMonthEnd(fromDate.year, fromDate.month + delta, anchor.day);
}

DateTime _sameDayOrMonthEnd(int year, int month, int day) {
  final monthStart = DateTime(year, month);
  final nextMonth = DateTime(monthStart.year, monthStart.month + 1);
  final lastDay = nextMonth.subtract(const Duration(days: 1)).day;

  return DateTime(monthStart.year, monthStart.month, math.min(day, lastDay));
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

int _remoteDisplayDuration(Timesheet entry) {
  if (entry.endAt == null) {
    final seconds = DateTime.now().toUtc().difference(entry.beginAt).inSeconds;
    return seconds < 60 ? 60 : seconds;
  }

  return entry.durationSeconds < 60 ? 60 : entry.durationSeconds;
}

int _localDisplayDuration(LocalTimeEntry entry) {
  if (_isOpenLocalEntry(entry)) {
    final seconds = DateTime.now().toUtc().difference(entry.beginAt).inSeconds;
    return seconds < 60 ? 60 : seconds;
  }

  return entry.durationSeconds < 60 ? 60 : entry.durationSeconds;
}

bool _isOpenLocalEntry(LocalTimeEntry entry) {
  if (entry.endAt != null) {
    return false;
  }

  return entry.status == LocalTimeEntryStatus.running.storageValue ||
      entry.status == LocalTimeEntryStatus.syncingStart.storageValue ||
      entry.status == LocalTimeEntryStatus.runningLocal.storageValue ||
      entry.status == LocalTimeEntryStatus.syncFailed.storageValue;
}

String _paymentId(int kimaiProjectId, DateTime payoutDate) {
  final date = '${payoutDate.year.toString().padLeft(4, '0')}-'
      '${payoutDate.month.toString().padLeft(2, '0')}-'
      '${payoutDate.day.toString().padLeft(2, '0')}';

  return 'kimai_${kimaiProjectId}_$date';
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(
    ref.watch(appDatabaseProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final paymentsSnapshotProvider = StreamProvider<PaymentsSnapshot>((ref) {
  return ref.watch(paymentsRepositoryProvider).watchPayments();
});
