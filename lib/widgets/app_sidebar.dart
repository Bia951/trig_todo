import 'package:flutter/material.dart';

import 'task_navigation_panel.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 264, child: TaskNavigationPanel());
  }
}
