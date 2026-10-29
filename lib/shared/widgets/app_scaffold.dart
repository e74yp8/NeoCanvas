import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.appBar,
    this.currentIndex = 0,
    this.showNavigation = true,
    this.floatingActionButton,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final int currentIndex;
  final bool showNavigation;
  final Widget? floatingActionButton;

  static const _destinations = <_NavDestination>[
    _NavDestination(
      label: '課程',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      route: '/courses',
    ),
    _NavDestination(
      label: '設定',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!showNavigation) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  minWidth: 80,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (index) =>
                      context.go(_destinations[index].route),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: destination.label,
                          child: Icon(destination.icon),
                        ),
                        selectedIcon: Tooltip(
                          message: destination.label,
                          child: Icon(destination.selectedIcon),
                        ),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }

        return Scaffold(
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                context.go(_destinations[index].route),
            destinations: [
              for (final destination in _destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
