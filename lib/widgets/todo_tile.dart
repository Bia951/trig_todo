import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    required this.todo,
    required this.batchMode,
    required this.isSelected,
    required this.onOpenPreview,
    required this.onOpenEdit,
    required this.onToggleSelected,
    required this.onToggleMute,
    required this.onToggleCompleted,
    required this.onToggleStarred,
    super.key,
  });

  static const Duration _animationDuration = Duration(milliseconds: 240);

  final Todo todo;
  final bool batchMode;
  final bool isSelected;
  final VoidCallback onOpenPreview;
  final VoidCallback onOpenEdit;
  final VoidCallback onToggleSelected;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCompleted;
  final VoidCallback onToggleStarred;

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
    final selectionColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? Color.alphaBlend(
                theme.colorScheme.primary.withValues(alpha: 0.12),
                theme.colorScheme.surfaceContainerLow,
              )
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.32)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: batchMode ? onToggleSelected : onOpenPreview,
          onLongPress: batchMode ? null : onOpenEdit,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: _animationDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-0.35, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                    );
                  },
                  child: batchMode
                      ? _CircleIconButton(
                          key: const ValueKey('batch-selection'),
                          tooltip: isSelected ? 'Unselect todo' : 'Select todo',
                          onPressed: onToggleSelected,
                          icon: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 18,
                            color: selectionColor,
                          ),
                        )
                      : _CircleIconButton(
                          key: const ValueKey('reminder'),
                          tooltip: todo.isMuted
                              ? 'Unmute reminder'
                              : 'Mute reminder',
                          onPressed: onToggleMute,
                          icon: Icon(
                            todo.isMuted
                                ? Icons.notifications_off_outlined
                                : Icons.notifications_rounded,
                            size: 18,
                            color: todo.isMuted
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                          ),
                        ),
                ),
                AnimatedContainer(
                  duration: _animationDuration,
                  curve: Curves.easeOutCubic,
                  width: batchMode ? 18 : 10,
                ),
                Expanded(
                  child: AnimatedSlide(
                    duration: _animationDuration,
                    curve: Curves.easeOutCubic,
                    offset: batchMode ? const Offset(0.02, 0) : Offset.zero,
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
                        AnimatedSize(
                          duration: _animationDuration,
                          curve: Curves.easeOutCubic,
                          child: batchMode
                              ? const SizedBox.shrink()
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 10),
                                    _CircleIconButton(
                                      tooltip: todo.isStarred
                                          ? 'Remove star'
                                          : 'Star todo',
                                      onPressed: onToggleStarred,
                                      icon: Icon(
                                        todo.isStarred
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 18,
                                        color: todo.isStarred
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: _animationDuration,
                  curve: Curves.easeOutCubic,
                  child: batchMode
                      ? const SizedBox.shrink()
                      : _CircleIconButton(
                          tooltip: todo.isCompleted
                              ? 'Mark as pending'
                              : 'Complete todo',
                          onPressed: onToggleCompleted,
                          icon: Icon(
                            todo.isCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 18,
                            color: todo.isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    super.key,
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
