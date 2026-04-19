import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoSectionPanel extends StatelessWidget {
  const TodoSectionPanel({
    required this.title,
    required this.todos,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.emptyLabel,
    required this.tileBuilder,
    this.onReorder,
    this.manageMode = false,
    super.key,
  });

  final String title;
  final List<Todo> todos;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final String emptyLabel;
  final Widget Function(BuildContext context, Todo todo) tileBuilder;
  final ReorderCallback? onReorder;
  final bool manageMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${todos.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            sizeCurve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 220),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: todos.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          emptyLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : manageMode && onReorder != null
                  ? ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: todos.length,
                      onReorder: onReorder!,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 1,
                              end: 1.015,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return Padding(
                          key: ValueKey('todo-section-$title-${todo.id}'),
                          padding: EdgeInsets.only(
                            bottom: index == todos.length - 1 ? 0 : 10,
                          ),
                          child: ReorderableDelayedDragStartListener(
                            index: index,
                            child: tileBuilder(context, todo),
                          ),
                        );
                      },
                    )
                  : Column(
                      children: [
                        for (var index = 0; index < todos.length; index++) ...[
                          tileBuilder(context, todos[index]),
                          if (index != todos.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
