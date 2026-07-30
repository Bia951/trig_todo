import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';
import '../widgets/app_sidebar.dart';
import 'home_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const double _desktopBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= _desktopBreakpoint) {
      return const _DesktopLayout();
    }
    return const _MobileLayout();
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(drawer: const AppDrawer(), body: const HomeScreen());
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const Expanded(child: HomeScreen()),
        ],
      ),
    );
  }
}
