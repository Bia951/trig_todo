import 'package:flutter/material.dart';

import '../layout/app_layout_profile.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_sidebar.dart';
import 'home_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = AppLayoutProfile.of(context);
    final hasPersistentNavigation = profile.hasPersistentNavigation;

    return Scaffold(
      drawer: hasPersistentNavigation ? null : const AppDrawer(),
      body: Row(
        children: [
          if (hasPersistentNavigation) ...[
            const AppSidebar(),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ],
          const Expanded(child: HomeScreen(key: ValueKey('home-screen'))),
        ],
      ),
    );
  }
}
