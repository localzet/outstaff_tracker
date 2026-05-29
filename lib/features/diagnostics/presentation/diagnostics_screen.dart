import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/app_screen.dart';
import '../../settings/data/settings_repository.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  static const routePath = '/diagnostics';

  static const _appVersion = '0.1.0+1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(_diagnosticsProvider);

    return AppScreen(
      title: 'Diagnostics',
      subtitle: 'Local app and database state for support/debugging.',
      children: [
        diagnostics.when(
          data: (data) => AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'App version', value: _appVersion),
                _Row(label: 'DB schema version', value: data.schemaVersion),
                _Row(label: 'Kimai base URL', value: data.baseUrl),
                _Row(
                  label: 'Enabled projects',
                  value: data.enabledProjects.toString(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Last sync logs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (data.logs.isEmpty)
                  Text(
                    'No sync logs yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  for (final log in data.logs)
                    Text(
                      '${log.startedAt.toLocal()} · ${log.operation} · ${log.status} · ${log.message ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: data.report),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Diagnostic report copied'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy diagnostic report'),
                ),
              ],
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Diagnostics unavailable',
            message: error.toString(),
          ),
        ),
      ],
    );
  }
}

class _DiagnosticsData {
  const _DiagnosticsData({
    required this.schemaVersion,
    required this.baseUrl,
    required this.enabledProjects,
    required this.logs,
  });

  final String schemaVersion;
  final String baseUrl;
  final int enabledProjects;
  final List<SyncLog> logs;

  String get report {
    return [
      'Outstaff Tracker diagnostics',
      'app_version=${DiagnosticsScreen._appVersion}',
      'db_schema_version=$schemaVersion',
      'kimai_base_url=$baseUrl',
      'enabled_projects=$enabledProjects',
      for (final log in logs)
        'sync_log=${log.startedAt.toIso8601String()} ${log.operation} ${log.status} ${log.message ?? ''}',
    ].join('\n');
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

final _diagnosticsProvider = FutureProvider<_DiagnosticsData>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final settings = await ref.watch(settingsRepositoryProvider).loadSettings();
  final enabledProjects = await (database.select(database.appProjects)
        ..where((table) => table.enabled.equals(true)))
      .get();
  final logs = await (database.select(database.syncLogs)
        ..orderBy([(table) => OrderingTerm.desc(table.startedAt)])
        ..limit(10))
      .get();

  return _DiagnosticsData(
    schemaVersion: database.schemaVersion.toString(),
    baseUrl: settings.baseUrl.isEmpty ? 'Not configured' : settings.baseUrl,
    enabledProjects: enabledProjects.length,
    logs: logs,
  );
});
