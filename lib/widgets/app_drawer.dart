import 'package:flutter/material.dart';

import 'task_navigation_panel.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: TaskNavigationPanel(
        animateEntry: true,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}
