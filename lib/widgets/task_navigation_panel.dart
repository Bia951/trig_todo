import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layout/app_layout_profile.dart';
import '../models/todo_list.dart';
import '../providers/todo_provider.dart';
import '../screens/manage_lists_screen.dart';
import 'new_list_sheet.dart';

enum _ListMenuAction { edit, delete }

class TaskNavigationPanel extends StatefulWidget {
  const TaskNavigationPanel({
    this.onDismiss,
    this.animateEntry = false,
    super.key,
  });

  final VoidCallback? onDismiss;
  final bool animateEntry;

  @override
  State<TaskNavigationPanel> createState() => _TaskNavigationPanelState();
}

class _TaskNavigationPanelState extends State<TaskNavigationPanel> {
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

  void _dismissThen(VoidCallback action) {
    widget.onDismiss?.call();
    if (widget.onDismiss == null) {
      action();
      return;
    }
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 220)).then((_) {
        if (mounted) action();
      }),
    );
  }

  void _editList(TodoList list) {
    _dismissThen(() => NewListSheet.show(context, existing: list));
  }

  Future<void> _confirmDeleteList(TodoList list) async {
    if (list.isInbox) return;
    final provider = context.read<TodoProvider>();
    final todoCount = provider.todos
        .where((todo) => todo.listId == list.id)
        .length;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete "${list.name}"?'),
            content: Text(
              todoCount == 0
                  ? 'This list will be deleted.'
                  : '$todoCount todo${todoCount == 1 ? '' : 's'} will move to Inbox.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    provider.deleteTodoList(list.id);
  }

  void _showMobileListActions(TodoList list) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit list'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _editList(list);
              },
            ),
            if (!list.isInbox)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete list',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_confirmDeleteList(list));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showDesktopListMenu(TodoList list, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_ListMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: _ListMenuAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit list'),
          ),
        ),
        if (!list.isInbox)
          const PopupMenuItem(
            value: _ListMenuAction.delete,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline_rounded),
              title: Text('Delete list'),
            ),
          ),
      ],
    );
    switch (action) {
      case _ListMenuAction.edit:
        _editList(list);
      case _ListMenuAction.delete:
        await _confirmDeleteList(list);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TodoProvider>();
    final usesDesktopInteractions = AppLayoutProfile.of(
      context,
    ).usesDesktopInteractions;
    final child = Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              child: Text(
                'Todos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Search todo',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _NavigationRow(
                icon: Icons.today_rounded,
                color: theme.colorScheme.primary,
                label: 'Today',
                count: provider.todayTodoCount,
                isActive: provider.showingToday,
                onTap: () {
                  _searchController.clear();
                  provider.showToday();
                  widget.onDismiss?.call();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _NavigationRow(
                icon: Icons.calendar_month_rounded,
                color: theme.colorScheme.tertiary,
                label: 'Schedule',
                count: 0,
                isActive: provider.showingSchedule,
                onTap: () {
                  _searchController.clear();
                  provider.showSchedule();
                  widget.onDismiss?.call();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text(
                'LISTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                itemCount: provider.lists.length,
                buildDefaultDragHandles: false,
                onReorder: provider.reorderLists,
                itemBuilder: (context, index) {
                  final list = provider.lists[index];
                  final row = _NavigationRow(
                    key: ValueKey(list.id),
                    icon: list.icon,
                    color: list.colorFor(theme.colorScheme),
                    label: list.name,
                    count: provider.countForList(list.id),
                    isActive:
                        !provider.showingToday &&
                        !provider.showingSchedule &&
                        list.id == provider.activeListId,
                    onTap: () {
                      _searchController.clear();
                      provider.setActiveList(list.id);
                      widget.onDismiss?.call();
                    },
                    onLongPress: usesDesktopInteractions
                        ? null
                        : () => _showMobileListActions(list),
                    onSecondaryTapUp: usesDesktopInteractions
                        ? (details) => unawaited(
                            _showDesktopListMenu(list, details.globalPosition),
                          )
                        : null,
                    dragHandle: usesDesktopInteractions
                        ? ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : ReorderableDelayedDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  );
                  return row;
                },
              ),
            ),
            Divider(
              height: 1,
              indent: 12,
              endIndent: 12,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 8),
            _NavigationFooterButton(
              icon: Icons.add_rounded,
              label: 'New List',
              onTap: () => _dismissThen(() => NewListSheet.show(context)),
            ),
            _NavigationFooterButton(
              icon: Icons.tune_rounded,
              label: 'Manage Lists',
              onTap: () => _dismissThen(
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManageListsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (!widget.animateEntry) return child;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(-16 * (1 - value), 0),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
    this.onSecondaryTapUp,
    this.dragHandle,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final GestureTapUpCallback? onSecondaryTapUp;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isActive
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTapUp: onSecondaryTapUp,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 4 : 0,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isActive ? 6 : 0,
                ),
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
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: count > 0
                      ? Text(
                          '$count',
                          key: ValueKey(count),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (dragHandle != null) ...[
                  const SizedBox(width: 6),
                  dragHandle!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationFooterButton extends StatelessWidget {
  const _NavigationFooterButton({
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
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
