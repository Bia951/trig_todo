import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';

class MoveToListSheet extends StatefulWidget {
  const MoveToListSheet({
    required this.todoId,
    required this.currentListId,
    super.key,
  });

  final String todoId;
  final String currentListId;

  static Future<void> show(
    BuildContext context, {
    required String todoId,
    required String currentListId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => MoveToListSheet(
        todoId: todoId,
        currentListId: currentListId,
      ),
    );
  }

  @override
  State<MoveToListSheet> createState() => _MoveToListSheetState();
}

class _MoveToListSheetState extends State<MoveToListSheet> {
  late String _selectedListId;

  @override
  void initState() {
    super.initState();
    _selectedListId = widget.currentListId;
  }

  void _confirm() {
    if (_selectedListId == widget.currentListId) {
      Navigator.of(context).pop();
      return;
    }
    context.read<TodoProvider>().moveTodoToList(widget.todoId, _selectedListId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lists = context.watch<TodoProvider>().lists;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle
        Center(
          child: Container(
            width: 38,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MOVE TO',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a list',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              final isCurrent = list.id == widget.currentListId;
              final isSelected = list.id == _selectedListId;
              return Opacity(
                opacity: isCurrent ? 0.45 : 1.0,
                child: InkWell(
                  onTap: isCurrent
                      ? null
                      : () => setState(() => _selectedListId = list.id),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.secondaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: list.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(list.icon, color: list.color, size: 19),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            list.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Text(
                            'Current',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else if (isSelected)
                          Icon(
                            Icons.radio_button_checked_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          )
                        else
                          Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: theme.colorScheme.outline,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _selectedListId != widget.currentListId
                      ? _confirm
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Move to "${lists.where((l) => l.id == _selectedListId).firstOrNull?.name ?? ''}"',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
