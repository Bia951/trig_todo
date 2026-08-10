import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_list.dart';
import '../providers/todo_provider.dart';

class ManageListsScreen extends StatefulWidget {
  const ManageListsScreen({super.key});

  @override
  State<ManageListsScreen> createState() => _ManageListsScreenState();
}

class _ManageListsScreenState extends State<ManageListsScreen> {
  final Set<String> _selectedIds = <String>{};
  bool _isSelecting = false;

  void _toggleSelectionMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final provider = context.read<TodoProvider>();
    final selectedLists = provider.lists
        .where((list) => _selectedIds.contains(list.id))
        .toList(growable: false);
    final todoCount = provider.todos
        .where((todo) => _selectedIds.contains(todo.listId))
        .length;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Delete ${selectedLists.length} list${selectedLists.length == 1 ? '' : 's'}?',
            ),
            content: Text(
              todoCount == 0
                  ? 'The selected lists will be deleted.'
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

    for (final list in selectedLists) {
      provider.deleteTodoList(list.id);
    }
    setState(() {
      _selectedIds.clear();
      _isSelecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TodoProvider>();
    final lists = provider.lists;
    final deletableCount = lists.where((list) => !list.isInbox).length;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            _isSelecting ? '${_selectedIds.length} selected' : 'Manage Lists',
            key: ValueKey(_isSelecting ? 'selected' : 'title'),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: deletableCount == 0 && !_isSelecting
                ? null
                : _toggleSelectionMode,
            icon: Icon(_isSelecting ? Icons.close_rounded : Icons.select_all),
            label: Text(_isSelecting ? 'Cancel' : 'Select'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _isSelecting
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Text(
                      'Inbox is protected and hidden while selecting.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, _isSelecting ? 12 : 4, 16, 24),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                final isHiddenInbox = _isSelecting && list.isInbox;
                final selected = _selectedIds.contains(list.id);
                return AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: isHiddenInbox ? 0 : 1,
                    child: isHiddenInbox
                        ? const SizedBox.shrink()
                        : _BulkListRow(
                            list: list,
                            count: provider.countForList(list.id),
                            selecting: _isSelecting,
                            selected: selected,
                            onTap: _isSelecting
                                ? () => setState(() {
                                    if (!_selectedIds.add(list.id)) {
                                      _selectedIds.remove(list.id);
                                    }
                                  })
                                : null,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _isSelecting
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(
                      _selectedIds.isEmpty
                          ? 'Select lists to delete'
                          : 'Delete ${_selectedIds.length} selected',
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _BulkListRow extends StatelessWidget {
  const _BulkListRow({
    required this.list,
    required this.count,
    required this.selecting,
    required this.selected,
    this.onTap,
  });

  final TodoList list;
  final int count;
  final bool selecting;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = list.colorFor(theme.colorScheme);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selecting
                      ? Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          key: ValueKey(selected),
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        )
                      : Container(
                          key: const ValueKey('icon'),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(list.icon, color: color, size: 21),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count pending',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
