import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    required this.todo,
    required this.manageMode,
    required this.detailBuilder,
    required this.onRequestDelete,
    required this.onToggleCompleted,
    required this.onToggleStarred,
    super.key,
  });

  final Todo todo;
  final bool manageMode;
  final Widget Function(BuildContext context, VoidCallback closeContainer)
  detailBuilder;
  final VoidCallback onRequestDelete;
  final VoidCallback onToggleCompleted;
  final VoidCallback onToggleStarred;

  Future<void> _showDetailCard(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return detailBuilder(context, () => Navigator.of(context).maybePop());
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final reminderTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(todo.reminderTime),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final hasTitle = todo.hasTitle;
    final titleText = todo.presentationTitle;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: InkWell(
        onLongPress: manageMode ? null : () => _showDetailCard(context),
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                child: Text(
                  reminderTime,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasTitle
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (manageMode)
                _CircleIconButton(
                  tooltip: 'Delete todo',
                  onPressed: onRequestDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (manageMode) const SizedBox(width: 4),
              _CircleIconButton(
                tooltip: todo.isStarred ? 'Remove star' : 'Star todo',
                onPressed: onToggleStarred,
                icon: Icon(
                  todo.isStarred
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 18,
                  color: todo.isStarred
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              _CircleIconButton(
                tooltip: todo.isCompleted ? 'Mark as pending' : 'Complete todo',
                onPressed: onToggleCompleted,
                icon: Icon(
                  todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: todo.isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 28,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(28),
          maximumSize: const Size.square(28),
        ),
        icon: icon,
      ),
    );
  }
}
