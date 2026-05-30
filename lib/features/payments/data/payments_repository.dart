import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../projects/data/projects_repository.dart';

enum PaymentStatus {
  expected,
  paid,
  skipped,
  disputed;

  String get storageValue => switch (this) {
        PaymentStatus.expected => 'expected',
        PaymentStatus.paid => 'paid',
        PaymentStatus.skipped => 'skipped',
        PaymentStatus.disputed => 'disputed',
      };

  String get label => switch (this) {
        PaymentStatus.expected => 'Ожидается',
        PaymentStatus.paid => 'Оплачено',
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
    required this.status,
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
  final PaymentStatus status;
  final int? actualAmountMinor;
  final DateTime? paidAt;
  final String? note;
}

class PaymentsSnapshot {
  const PaymentsSnapshot({
    required this.expected,
    required this.paid,
    required this.problematic,
  });

  final List<PaymentItem> expected;
  final List<PaymentItem> paid;
  final List<PaymentItem> problematic;

  List<PaymentItem> get nextExpected => expected.take(3).toList();
}

class PaymentsRepository {
  PaymentsRepository(this._database);

  final AppDatabase _database;

  Stream<PaymentsSnapshot> watchPayments() {
    return _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM app_projects '
          'UNION ALL SELECT COUNT(*) FROM payout_dates '
          'UNION ALL SELECT COUNT(*) FROM timesheets '
          'UNION ALL SELECT COUNT(*) FROM payments',
          readsFrom: {
            _database.appProjects,
            _database.payoutDates,
            _database.timesheets,
            _database.payments,
          },
        )
        .watch()
        .asyncMap((_) => getPayments());
  }

  Future<PaymentsSnapshot> getPayments() async {
    final generated = await _generateExpectedPayments();
    final stored = await _storedPaymentItems();
    final byId = {for (final item in generated) item.id: item};

    for (final item in stored) {
      byId[item.id] = item;
    }

    final all = byId.values.toList()
      ..sort((a, b) => a.payoutDate.compareTo(b.payoutDate));

    return PaymentsSnapshot(
      expected: all
          .where((item) => item.status == PaymentStatus.expected)
          .toList(growable: false),
      paid: all
          .where((item) => item.status == PaymentStatus.paid)
          .toList(growable: false),
      problematic: all
          .where(
            (item) =>
                item.status == PaymentStatus.skipped ||
                item.status == PaymentStatus.disputed,
          )
          .toList(growable: false),
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

  Future<List<PaymentItem>> _generateExpectedPayments() async {
    final rows = await _database.select(_database.appProjects).join([
      innerJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id
            .equalsExp(_database.appProjects.kimaiProjectId),
      ),
    ]).get();
    final customDates = await _database.select(_database.payoutDates).get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final beginWindow = DateTime(today.year, today.month - 3, 1);
    final endWindow = DateTime(today.year, today.month + 6, 1);
    final result = <PaymentItem>[];

    for (final row in rows) {
      final appProject = row.readTable(_database.appProjects);
      final kimaiProject = row.readTable(_database.kimaiProjects);
      if (!appProject.enabled ||
          appProject.kimaiProjectId == null ||
          appProject.payoutRule == PayoutRule.none.storageValue) {
        continue;
      }

      final periods = _buildPeriods(
        rule: appProject.payoutRule,
        from: beginWindow,
        to: endWindow,
        customDates: customDates
            .where((date) => date.appProjectId == appProject.id)
            .map((date) => date.payoutDate)
            .toList(),
      );

      for (final period in periods) {
        final amount = await _amountForPeriod(
          appProject.id,
          period.start,
          period.end,
        );
        if (amount == 0 && period.payoutDate.isBefore(today)) {
          continue;
        }
        result.add(
          PaymentItem(
            id: _paymentId(kimaiProject.id, period.payoutDate),
            kimaiProjectId: kimaiProject.id,
            projectName: kimaiProject.name,
            color: appProject.color ?? kimaiProject.color,
            payoutDate: period.payoutDate,
            periodStart: period.start,
            periodEnd: period.end,
            expectedAmountMinor: amount,
            status: PaymentStatus.expected,
          ),
        );
      }
    }

    return result;
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
      actualAmountMinor: payment.actualAmountMinor,
      status: PaymentStatus.fromStorage(payment.status),
      paidAt: payment.paidAt,
      note: payment.note,
    );
  }

  Future<int> _amountForPeriod(
    String appProjectId,
    DateTime begin,
    DateTime end,
  ) async {
    final rows = await (_database.select(_database.timesheets)
          ..where((table) => table.appProjectId.equals(appProjectId))
          ..where((table) => table.beginAt.isBiggerOrEqualValue(begin))
          ..where((table) => table.beginAt.isSmallerThanValue(end)))
        .get();

    return rows.fold<int>(0, (sum, row) => sum + (row.amountMinor ?? 0));
  }
}

List<({DateTime start, DateTime end, DateTime payoutDate})> _buildPeriods({
  required String rule,
  required DateTime from,
  required DateTime to,
  required List<DateTime> customDates,
}) {
  final periods = <({DateTime start, DateTime end, DateTime payoutDate})>[];
  if (rule == PayoutRule.customDates.storageValue) {
    final dates = customDates.map(_dateOnly).toList()..sort();
    for (var index = 0; index < dates.length; index++) {
      final payoutDate = dates[index];
      final previous = index == 0
          ? payoutDate.subtract(const Duration(days: 30))
          : dates[index - 1];
      periods.add((start: previous, end: payoutDate, payoutDate: payoutDate));
    }
    return periods;
  }

  if (rule == PayoutRule.monthly.storageValue) {
    var start = DateTime(from.year, from.month);
    while (start.isBefore(to)) {
      final end = DateTime(start.year, start.month + 1);
      periods.add((start: start, end: end, payoutDate: end));
      start = end;
    }
    return periods;
  }

  final step = rule == PayoutRule.triweekly.storageValue ? 21 : 14;
  var start = _dateOnly(from);
  while (start.isBefore(to)) {
    final end = start.add(Duration(days: step));
    periods.add((start: start, end: end, payoutDate: end));
    start = end;
  }

  return periods;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _paymentId(int kimaiProjectId, DateTime payoutDate) {
  final date = '${payoutDate.year.toString().padLeft(4, '0')}-'
      '${payoutDate.month.toString().padLeft(2, '0')}-'
      '${payoutDate.day.toString().padLeft(2, '0')}';

  return 'kimai_${kimaiProjectId}_$date';
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(appDatabaseProvider));
});

final paymentsSnapshotProvider = StreamProvider<PaymentsSnapshot>((ref) {
  return ref.watch(paymentsRepositoryProvider).watchPayments();
});
