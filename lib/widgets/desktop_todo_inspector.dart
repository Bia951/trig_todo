import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../providers/todo_provider.dart';
import 'move_to_list_sheet.dart';

class DesktopTodoInspector extends StatelessWidget {
  const DesktopTodoInspector({
    required this.todo,
    required this.onDismiss,
    required this.onEdit,
    required this.onToggleCompleted,
    required this.onToggleStarred,
    required this.onToggleMute,
    super.key,
  });

  final Todo? todo;
  final VoidCallback onDismiss;
  final VoidCallback onEdit;
  final VoidCallback onToggleCompleted;
  final VoidCallback onToggleStarred;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTodo = todo;
    if (currentTodo == null) {
      return ColoredBox(
        color: theme.colorScheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'Select a todo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Its details will stay here while you work.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final provider = context.watch<TodoProvider>();
    final list = provider.lists
        .where((item) => item.id == currentTodo.listId)
        .firstOrNull;
    final listColor =
        list?.colorFor(theme.colorScheme) ?? theme.colorScheme.primary;

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Text(
                  'Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close details',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentTodo.presentationTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        key: const ValueKey('todo-inspector-edit'),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                      _InspectorAction(
                        tooltip: currentTodo.isCompleted
                            ? 'Mark as pending'
                            : 'Complete todo',
                        icon: currentTodo.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        onPressed: onToggleCompleted,
                      ),
                      _InspectorAction(
                        tooltip: currentTodo.isStarred
                            ? 'Remove star'
                            : 'Star todo',
                        icon: currentTodo.isStarred
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        onPressed: onToggleStarred,
                      ),
                      _InspectorAction(
                        tooltip: currentTodo.isMuted
                            ? 'Enable task reminder'
                            : 'Disable task reminder',
                        icon: currentTodo.isMuted
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_rounded,
                        onPressed: onToggleMute,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InspectorTile(
                    icon: list?.icon ?? Icons.list_rounded,
                    color: listColor,
                    label: 'List',
                    value: list?.name ?? 'Inbox',
                    onTap: () => MoveToListSheet.show(
                      context,
                      todoId: currentTodo.id,
                      currentListId: currentTodo.listId,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InspectorTile(
                    icon: currentTodo.isMuted
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_rounded,
                    label: 'Task reminder',
                    value: currentTodo.isMuted
                        ? 'Off'
                        : _formatDateTime(context, currentTodo.reminderTime),
                  ),
                  const SizedBox(height: 12),
                  _InspectorTile(
                    icon: Icons.event_outlined,
                    label: 'Deadline',
                    value: _formatDateTime(context, currentTodo.deadline),
                  ),
                  const SizedBox(height: 20),
                  _InspectorText(label: 'Content', value: currentTodo.content),
                  const SizedBox(height: 12),
                  _InspectorText(label: 'Notes', value: currentTodo.notes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(value);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$date, $time';
  }
}

class _InspectorAction extends StatelessWidget {
  const _InspectorAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
    );
  }
}

class _InspectorTile extends StatelessWidget {
  const _InspectorTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        hoverColor: Colors.white.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.34,
        ),
        highlightColor: Colors.white.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectorText extends StatelessWidget {
  const _InspectorText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.trim().isEmpty ? 'No details yet.' : value,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ],
    );
  }
}
