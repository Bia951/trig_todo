import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_card_page.dart';
import '../widgets/todo_section_panel.dart';
import '../widgets/todo_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;
  bool _manageMode = false;
  bool _didInitializeExpansions = false;
  bool _importantExpanded = false;
  bool _pendingExpanded = true;
  bool _completedExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeExpansions) {
      return;
    }

    final provider = context.read<TodoProvider>();
    final hasImportant = provider.hasImportantTodos;
    _importantExpanded = hasImportant;
    _pendingExpanded = !hasImportant;
    _completedExpanded = false;
    _didInitializeExpansions = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openComposer() async {
    _dismissKeyboard();
    final provider = context.read<TodoProvider>();
    final draft = provider.createDraft();

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: TodoCardPage(
              initialTodo: draft,
              startInEditMode: true,
              closeOnSave: true,
            ),
          );
        },
      ),
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _toggleManageMode() {
    _dismissKeyboard();
    final provider = context.read<TodoProvider>();
    if (!_manageMode && provider.searchQuery.isNotEmpty) {
      _searchController.clear();
      provider.setSearchQuery('');
    }

    setState(() {
      _manageMode = !_manageMode;
    });
  }

  void _toggleCompleted(Todo todo) {
    context.read<TodoProvider>().toggleCompleted(todo.id);
    if (!todo.isCompleted) {
      setState(() {
        _completedExpanded = false;
      });
    }
  }

  Future<void> _confirmDeleteTodo(Todo todo) async {
    _dismissKeyboard();
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete todo?'),
              content: Text(
                'This will remove "${todo.presentationTitle}" from your list.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete || !mounted) {
      return;
    }

    context.read<TodoProvider>().removeTodo(todo.id);
  }

  Widget _buildSectionTile(BuildContext context, Todo todo) {
    return TodoTile(
      key: ValueKey('todo-${todo.id}'),
      todo: todo,
      manageMode: _manageMode,
      onRequestDelete: () => _confirmDeleteTodo(todo),
      onToggleCompleted: () => _toggleCompleted(todo),
      onToggleStarred: () =>
          context.read<TodoProvider>().toggleStarred(todo.id),
      detailBuilder: (context, closeContainer) {
        return TodoCardPage(
          initialTodo: todo,
          heroTag: 'todo-card-${todo.id}',
          onClose: closeContainer,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todoProvider = context.watch<TodoProvider>();
    final importantTodos = todoProvider.importantTodos;
    final pendingTodos = todoProvider.pendingTodos;
    final completedTodos = todoProvider.completedTodos;
    final hasSearchQuery = todoProvider.searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _ToolbarCircleButton(
              tooltip: _manageMode ? 'Finish editing' : 'Edit list',
              onPressed: _toggleManageMode,
              icon: Icon(
                Icons.edit_outlined,
                color: _manageMode ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: TextField(
            controller: _searchController,
            onChanged: todoProvider.setSearchQuery,
            onTapOutside: (_) => _dismissKeyboard(),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search todo',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        actions: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ToolbarCircleButton(
                tooltip: 'Add todo',
                onPressed: _openComposer,
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surfaceContainerLowest,
              Color.alphaBlend(
                theme.colorScheme.primary.withValues(alpha: 0.05),
                theme.colorScheme.surface,
              ),
              theme.colorScheme.surfaceContainerLow,
            ],
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (importantTodos.isNotEmpty) ...[
                TodoSectionPanel(
                  title: 'Important',
                  todos: importantTodos,
                  isExpanded: _importantExpanded,
                  onToggleExpanded: () {
                    setState(() {
                      _importantExpanded = !_importantExpanded;
                    });
                  },
                  manageMode: _manageMode,
                  onReorder: _manageMode
                      ? (oldIndex, newIndex) {
                          todoProvider.reorderTodos(
                            bucket: TodoBucket.important,
                            oldIndex: oldIndex,
                            newIndex: newIndex,
                          );
                        }
                      : null,
                  emptyLabel: hasSearchQuery
                      ? 'No important todos match this search.'
                      : 'No important todos yet.',
                  tileBuilder: _buildSectionTile,
                ),
                const SizedBox(height: 14),
              ],
              TodoSectionPanel(
                title: 'Pending',
                todos: pendingTodos,
                isExpanded: _pendingExpanded,
                onToggleExpanded: () {
                  setState(() {
                    _pendingExpanded = !_pendingExpanded;
                  });
                },
                manageMode: _manageMode,
                onReorder: _manageMode
                    ? (oldIndex, newIndex) {
                        todoProvider.reorderTodos(
                          bucket: TodoBucket.pending,
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        );
                      }
                    : null,
                emptyLabel: hasSearchQuery
                    ? 'No pending todos match this search.'
                    : 'No pending todos yet.',
                tileBuilder: _buildSectionTile,
              ),
              const SizedBox(height: 14),
              TodoSectionPanel(
                title: 'Completed',
                todos: completedTodos,
                isExpanded: _completedExpanded,
                onToggleExpanded: () {
                  setState(() {
                    _completedExpanded = !_completedExpanded;
                  });
                },
                manageMode: _manageMode,
                onReorder: _manageMode
                    ? (oldIndex, newIndex) {
                        todoProvider.reorderTodos(
                          bucket: TodoBucket.completed,
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        );
                      }
                    : null,
                emptyLabel: hasSearchQuery
                    ? 'No completed todos match this search.'
                    : 'Completed tasks will gather here.',
                tileBuilder: _buildSectionTile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarCircleButton extends StatelessWidget {
  const _ToolbarCircleButton({
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
      dimension: 44,
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(44),
          maximumSize: const Size.square(44),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: icon,
      ),
    );
  }
}
