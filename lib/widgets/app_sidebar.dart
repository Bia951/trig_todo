import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';
import '../screens/manage_lists_screen.dart';
import 'new_list_sheet.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({required this.onSettingsTap, super.key});

  final VoidCallback onSettingsTap;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TodoProvider>();
    final lists = provider.lists;
    final activeListId = provider.activeListId;

    return SizedBox(
      width: 264,
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand row: "Trig" text only — no bolt icon (Note 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      'Trig',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Search field — fixed width, NOT flex-stretched (Note 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        context.read<TodoProvider>().setSearchQuery(v),
                    decoration: const InputDecoration(
                      hintText: 'Search todo',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                child: Text(
                  'LISTS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Scrollable list of lists
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    final isActive = list.id == activeListId;
                    final count = provider.countForList(list.id);
                    return _SidebarListRow(
                      name: list.name,
                      icon: list.icon,
                      color: list.color,
                      count: count,
                      isActive: isActive,
                      onTap: () =>
                          context.read<TodoProvider>().setActiveList(list.id),
                    );
                  },
                ),
              ),

              // Footer: New List + Manage Lists
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 8),
              _SidebarFootButton(
                icon: Icons.add_rounded,
                label: 'New List',
                onTap: () => NewListSheet.show(context),
              ),
              _SidebarFootButton(
                icon: Icons.tune_rounded,
                label: 'Manage Lists',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManageListsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarListRow extends StatelessWidget {
  const _SidebarListRow({
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color color;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive
            ? theme.colorScheme.secondaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                // Active indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 4 : 0,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(width: isActive ? 6 : 0),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                      color: isActive
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
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

class _SidebarFootButton extends StatelessWidget {
  const _SidebarFootButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 17,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
