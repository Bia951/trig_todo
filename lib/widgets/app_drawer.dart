import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';
import '../screens/manage_lists_screen.dart';
import 'new_list_sheet.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
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

    return Drawer(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: title + settings icon (Note 4: no-op for now)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRIG · LISTS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'My Lists',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings button — kept without function (Note 4)
                  IconButton.filledTonal(
                    onPressed: () {},
                    tooltip: 'Settings',
                    style: IconButton.styleFrom(
                      shape: const CircleBorder(),
                      minimumSize: const Size.square(44),
                      maximumSize: const Size.square(44),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),

            // Search field (Note 3: added in same position as desktop sidebar)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => context.read<TodoProvider>().setSearchQuery(v),
                decoration: const InputDecoration(
                  hintText: 'Search todo',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'LISTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Scrollable list of lists
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  final list = lists[index];
                  final isActive = list.id == activeListId;
                  final count = provider.countForList(list.id);
                  return _ListRow(
                    name: list.name,
                    icon: list.icon,
                    color: list.color,
                    count: count,
                    isActive: isActive,
                    onTap: () {
                      context.read<TodoProvider>().setActiveList(list.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),

            // Footer: New List + Manage Lists (Note 3: same position as desktop)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: theme.colorScheme.outlineVariant,
            ),
            _DrawerFootButton(
              icon: Icons.add_rounded,
              label: 'New List',
              onTap: () {
                Navigator.of(context).pop();
                NewListSheet.show(context);
              },
            ),
            _DrawerFootButton(
              icon: Icons.tune_rounded,
              label: 'Manage Lists',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManageListsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.onSecondaryContainer
                              .withValues(alpha: 0.12)
                          : theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSecondaryContainer,
                      ),
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

class _DrawerFootButton extends StatelessWidget {
  const _DrawerFootButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 19,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 13),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
