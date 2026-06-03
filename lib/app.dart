import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/config/app_branding.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_screen.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/calendar/presentation/calendar_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/diagnostics/presentation/diagnostics_screen.dart';
import 'features/local_tracking/data/local_tracking_sync_service.dart';
import 'features/local_tracking/presentation/timer_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/payments/presentation/payments_screen.dart';
import 'features/progress/presentation/progress_history_screen.dart';
import 'features/projects/presentation/projects_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/sync/data/sync_controller.dart';
import 'features/timesheets/presentation/timesheets_screen.dart';
import 'features/updates/data/update_controller.dart';
import 'features/updates/data/update_repository.dart';
import 'features/updates/data/update_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: DashboardScreen.routePath,
    redirect: (context, state) async {
      final complete =
          await ref.read(settingsRepositoryProvider).isOnboardingComplete();
      final onboarding = state.uri.path == OnboardingScreen.routePath;
      final settings = state.uri.path == SettingsScreen.routePath;
      if (!complete && !onboarding && !settings) {
        return OnboardingScreen.routePath;
      }
      if (complete && onboarding) {
        return DashboardScreen.routePath;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: OnboardingScreen.routePath,
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: DashboardScreen.routePath,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: CalendarScreen.routePath,
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: TimesheetsScreen.routePath,
            builder: (context, state) => const TimesheetsScreen(),
          ),
          GoRoute(
            path: TimerScreen.routePath,
            builder: (context, state) => const TimerScreen(),
          ),
          GoRoute(
            path: ProjectsScreen.routePath,
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: PaymentsScreen.routePath,
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: ProgressHistoryScreen.routePath,
            builder: (context, state) => const ProgressHistoryScreen(),
          ),
          GoRoute(
            path: AnalyticsScreen.routePath,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: ReportsScreen.routePath,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: SettingsScreen.routePath,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: DiagnosticsScreen.routePath,
            builder: (context, state) => const DiagnosticsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => RouterErrorScreen(error: state.error),
  );
});

class OutstaffTrackerApp extends ConsumerWidget {
  const OutstaffTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppBranding.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => AutoUpdateHost(
        child: AutoSyncHost(child: child ?? const AppStartupFallback()),
      ),
    );
  }
}

class AppStartupFallback extends StatelessWidget {
  const AppStartupFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class RouterErrorScreen extends StatelessWidget {
  const RouterErrorScreen({required this.error, super.key});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Не удалось открыть экран',
      subtitle: 'Ошибка запуска маршрутизации приложения.',
      children: [
        AppPanel(
          child: SelectableText(error?.toString() ?? 'Неизвестная ошибка.'),
        ),
      ],
    );
  }
}

class AutoUpdateHost extends ConsumerStatefulWidget {
  const AutoUpdateHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AutoUpdateHost> createState() => _AutoUpdateHostState();
}

class _AutoUpdateHostState extends ConsumerState<AutoUpdateHost> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(updateControllerProvider.notifier).checkOnStartup(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateControllerProvider, (previous, next) {
      final result = next.result;
      if (_dialogShown || result == null || !result.hasUpdate) {
        return;
      }

      _dialogShown = true;
      unawaited(_showUpdateDialog(result));
    });

    return widget.child;
  }

  Future<void> _showUpdateDialog(UpdateCheckResult result) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        final nativeUpdatesSupported =
            result.installMode == UpdateInstallMode.native;
        final asset = result.selectedAsset;
        final actionLabel = nativeUpdatesSupported
            ? 'Обновить'
            : asset == null
                ? 'Открыть релиз'
                : result.platformLabel == 'Android'
                    ? 'Скачать APK'
                    : 'Скачать установщик';
        return AlertDialog(
          title: const Text('Доступна новая версия'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Текущая версия: ${result.currentVersion}',
              ),
              Text('Новая версия: ${result.metadata.version}'),
              Text('Платформа: ${result.platformLabel}'),
              if (asset != null) Text('Файл: ${asset.name}'),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  launchUrl(
                    Uri.parse(result.metadata.releaseNotesUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Что изменилось'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Позже'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref
                      .read(updateControllerProvider.notifier)
                      .installLatestUpdate();
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Не удалось запустить обновление: $error'),
                      ),
                    );
                  }
                }
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }
}

class AutoSyncHost extends ConsumerStatefulWidget {
  const AutoSyncHost({required this.child, super.key});

  final Widget? child;

  @override
  ConsumerState<AutoSyncHost> createState() => _AutoSyncHostState();
}

class _AutoSyncHostState extends ConsumerState<AutoSyncHost> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 10), (_) {
      final controller = ref.read(syncControllerProvider.notifier);
      final state = ref.read(syncControllerProvider);
      if (!state.isSyncing) {
        unawaited(
          ref
              .read(localTrackingSyncServiceProvider)
              .syncPendingEntries()
              .catchError(
                (_) => const LocalTrackingSyncResult(
                  synced: 0,
                  failed: 0,
                  conflicts: 0,
                ),
              ),
        );
        unawaited(controller.runIncrementalSync().catchError((_) {}));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _destinations = <NavigationDestinationData>[
    NavigationDestinationData(
      label: 'Дашборд',
      path: DashboardScreen.routePath,
      icon: Icons.grid_view_rounded,
    ),
    NavigationDestinationData(
      label: 'Календарь',
      path: CalendarScreen.routePath,
      icon: Icons.calendar_month_rounded,
    ),
    NavigationDestinationData(
      label: 'Таймер',
      path: TimerScreen.routePath,
      icon: Icons.play_circle_rounded,
    ),
    NavigationDestinationData(
      label: 'Время',
      path: TimesheetsScreen.routePath,
      icon: Icons.timer_rounded,
    ),
    NavigationDestinationData(
      label: 'Проекты',
      path: ProjectsScreen.routePath,
      icon: Icons.folder_rounded,
    ),
    NavigationDestinationData(
      label: 'Выплаты',
      path: PaymentsScreen.routePath,
      icon: Icons.payments_rounded,
    ),
    NavigationDestinationData(
      label: 'История',
      path: ProgressHistoryScreen.routePath,
      icon: Icons.stacked_line_chart_rounded,
    ),
    NavigationDestinationData(
      label: 'Аналитика',
      path: AnalyticsScreen.routePath,
      icon: Icons.query_stats_rounded,
    ),
    NavigationDestinationData(
      label: 'Отчёты',
      path: ReportsScreen.routePath,
      icon: Icons.table_chart_rounded,
    ),
    NavigationDestinationData(
      label: 'Настройки',
      path: SettingsScreen.routePath,
      icon: Icons.settings_rounded,
    ),
    NavigationDestinationData(
      label: 'Диагностика',
      path: DiagnosticsScreen.routePath,
      icon: Icons.health_and_safety_rounded,
    ),
  ];

  static const _mobileDestinations = <NavigationDestinationData>[
    NavigationDestinationData(
      label: '\u041e\u0431\u0437\u043e\u0440',
      path: DashboardScreen.routePath,
      icon: Icons.grid_view_rounded,
    ),
    NavigationDestinationData(
      label: '\u041a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044c',
      path: CalendarScreen.routePath,
      icon: Icons.calendar_month_rounded,
    ),
    NavigationDestinationData(
      label: 'Таймер',
      path: TimerScreen.routePath,
      icon: Icons.play_circle_rounded,
    ),
    NavigationDestinationData(
      label: '\u0412\u0440\u0435\u043c\u044f',
      path: TimesheetsScreen.routePath,
      icon: Icons.timer_rounded,
    ),
    NavigationDestinationData(
      label: '\u0412\u044b\u043f\u043b\u0430\u0442\u044b',
      path: PaymentsScreen.routePath,
      icon: Icons.payments_rounded,
    ),
    NavigationDestinationData(
      label: '\u0415\u0449\u0451',
      path: '',
      icon: Icons.more_horiz_rounded,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final selectedIndex = _selectedIndex(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(
              destinations: _destinations,
              selectedIndex: selectedIndex,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileSelectedIndex(context),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          if (index == _mobileDestinations.length - 1) {
            _showMoreMenu(context);
            return;
          }
          context.go(_mobileDestinations[index].path);
        },
        destinations: [
          for (final destination in _mobileDestinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _destinations.indexWhere((item) => item.path == location);

    return index < 0 ? 0 : index;
  }

  int _mobileSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _mobileDestinations.indexWhere(
      (item) => item.path == location,
    );
    return index < 0 ? _mobileDestinations.length - 1 : index;
  }

  void _showMoreMenu(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final secondary = _destinations
        .where(
          (item) =>
              !_mobileDestinations.any((mobile) => mobile.path == item.path),
        )
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          children: [
            for (final destination in secondary)
              ListTile(
                selected: destination.path == location,
                leading: Icon(destination.icon),
                title: Text(destination.label),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(destination.path);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.destinations,
    required this.selectedIndex,
    super.key,
  });

  final List<NavigationDestinationData> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 24),
                child: Text(
                  AppBranding.appName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (var index = 0; index < destinations.length; index++)
                SidebarItem(
                  destination: destinations[index],
                  selected: index == selectedIndex,
                  onTap: () => context.go(destinations[index].path),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final NavigationDestinationData destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.textPrimary : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.surfaceElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: selected ? AppColors.border : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(destination.icon, size: 20, color: foreground),
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationDestinationData {
  const NavigationDestinationData({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final IconData icon;
}
