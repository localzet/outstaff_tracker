import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/analytics/presentation/analytics_screen.dart';
import 'features/calendar/presentation/calendar_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/projects/presentation/projects_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/timesheets/presentation/timesheets_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: DashboardScreen.routePath,
    routes: <RouteBase>[
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
            path: ProjectsScreen.routePath,
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: AnalyticsScreen.routePath,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: SettingsScreen.routePath,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class OutstaffTrackerApp extends ConsumerWidget {
  const OutstaffTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Outstaff Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _destinations = <NavigationDestinationData>[
    NavigationDestinationData(
      label: 'Dashboard',
      path: DashboardScreen.routePath,
      icon: Icons.grid_view_rounded,
    ),
    NavigationDestinationData(
      label: 'Calendar',
      path: CalendarScreen.routePath,
      icon: Icons.calendar_month_rounded,
    ),
    NavigationDestinationData(
      label: 'Timesheets',
      path: TimesheetsScreen.routePath,
      icon: Icons.timer_rounded,
    ),
    NavigationDestinationData(
      label: 'Projects',
      path: ProjectsScreen.routePath,
      icon: Icons.folder_rounded,
    ),
    NavigationDestinationData(
      label: 'Analytics',
      path: AnalyticsScreen.routePath,
      icon: Icons.query_stats_rounded,
    ),
    NavigationDestinationData(
      label: 'Settings',
      path: SettingsScreen.routePath,
      icon: Icons.settings_rounded,
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
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(_destinations[index].path),
        destinations: [
          for (final destination in _destinations)
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
                  'Outstaff Tracker',
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
