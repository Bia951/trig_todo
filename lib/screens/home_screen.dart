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
  bool _batchMode = false;
  final Set<String> _selectedTodoIds = <String>{};
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

  void _toggleBatchMode() {
    _dismissKeyboard();
    final provider = context.read<TodoProvider>();
    final willEnterBatchMode = !_batchMode;
    if (willEnterBatchMode && provider.searchQuery.isNotEmpty) {
      _searchController.clear();
      provider.setSearchQuery('');
    }

    setState(() {
      _batchMode = willEnterBatchMode;
      _selectedTodoIds.clear();
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

  Future<void> _openTodoDetail(
    Todo todo, {
    required bool startInEditMode,
  }) async {
    _dismissKeyboard();
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return TodoCardPage(
            initialTodo: todo,
            heroTag: 'todo-card-${todo.id}',
            startInEditMode: startInEditMode,
            onClose: () => Navigator.of(context).maybePop(),
          );
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

  void _toggleSelectedTodo(String id) {
    setState(() {
      if (!_selectedTodoIds.add(id)) {
        _selectedTodoIds.remove(id);
      }
    });
  }

  Future<void> _confirmDeleteSelectedTodos() async {
    _dismissKeyboard();
    final provider = context.read<TodoProvider>();
    final selectedTodos = provider.todos
        .where((todo) => _selectedTodoIds.contains(todo.id))
        .toList(growable: false);
    if (selectedTodos.isEmpty) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                selectedTodos.length == 1
                    ? 'Delete selected todo?'
                    : 'Delete ${selectedTodos.length} selected todos?',
              ),
              content: Text(
                selectedTodos.length == 1
                    ? 'This will remove "${selectedTodos.single.presentationTitle}" from your list.'
                    : 'This will remove all selected todos from your list.',
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

    provider.removeTodos(selectedTodos.map((todo) => todo.id));
    setState(() {
      _selectedTodoIds.clear();
    });
  }

  void _completeSelectedTodos() {
    final provider = context.read<TodoProvider>();
    final selectedTodos = provider.todos
        .where((todo) => _selectedTodoIds.contains(todo.id))
        .toList(growable: false);
    if (selectedTodos.isEmpty) {
      return;
    }

    final hasIncompleteTodo = selectedTodos.any((todo) => !todo.isCompleted);
    provider.completeTodos(selectedTodos.map((todo) => todo.id));
    setState(() {
      _selectedTodoIds.clear();
      if (hasIncompleteTodo) {
        _completedExpanded = false;
      }
    });
  }

  Widget _buildSectionTile(BuildContext context, Todo todo) {
    return TodoTile(
      key: ValueKey('todo-${todo.id}'),
      todo: todo,
      batchMode: _batchMode,
      isSelected: _selectedTodoIds.contains(todo.id),
      onOpenPreview: () => _openTodoDetail(todo, startInEditMode: false),
      onOpenEdit: () => _openTodoDetail(todo, startInEditMode: true),
      onToggleSelected: () => _toggleSelectedTodo(todo.id),
      onToggleMute: () => context.read<TodoProvider>().toggleMute(todo.id),
      onToggleCompleted: () => _toggleCompleted(todo),
      onToggleStarred: () =>
          context.read<TodoProvider>().toggleStarred(todo.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todoProvider = context.watch<TodoProvider>();
    final importantTodos = todoProvider.importantTodos;
    final pendingTodos = todoProvider.pendingTodos;
    final completedTodos = todoProvider.completedTodos;
    final selectedVisibleTodoCount = todoProvider.todos
        .where((todo) => _selectedTodoIds.contains(todo.id))
        .length;
    final hasSearchQuery = todoProvider.searchQuery.trim().isNotEmpty;
    final hasAnyVisibleTodos =
        importantTodos.isNotEmpty ||
        pendingTodos.isNotEmpty ||
        completedTodos.isNotEmpty;
    final showAllSectionsInSearch = hasSearchQuery && hasAnyVisibleTodos;
    final effectiveImportantExpanded =
        showAllSectionsInSearch && importantTodos.isEmpty
        ? false
        : _importantExpanded;
    final effectivePendingExpanded =
        showAllSectionsInSearch && pendingTodos.isEmpty
        ? false
        : _pendingExpanded;
    final effectiveCompletedExpanded =
        showAllSectionsInSearch && completedTodos.isEmpty
        ? false
        : _completedExpanded;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _ToolbarCircleButton(
              tooltip: _batchMode ? 'Finish edit' : 'Edit',
              onPressed: _toggleBatchMode,
              icon: Icon(
                Icons.edit_outlined,
                color: _batchMode ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  child: child,
                ),
              );
            },
            child: _batchMode
                ? _BatchModeTitle(
                    key: const ValueKey('batch-title'),
                    selectedCount: selectedVisibleTodoCount,
                  )
                : TextField(
                    key: const ValueKey('search-field'),
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
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.12, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _batchMode
                    ? Row(
                        key: const ValueKey('batch-actions'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ToolbarCircleButton(
                            tooltip: 'Delete selected',
                            onPressed: selectedVisibleTodoCount == 0
                                ? null
                                : _confirmDeleteSelectedTodos,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                          const SizedBox(width: 8),
                          _ToolbarCircleButton(
                            tooltip: 'Complete selected',
                            onPressed: selectedVisibleTodoCount == 0
                                ? null
                                : _completeSelectedTodos,
                            icon: const Icon(Icons.check_box_outlined),
                          ),
                        ],
                      )
                    : _ToolbarCircleButton(
                        key: const ValueKey('add-action'),
                        tooltip: 'Add todo',
                        onPressed: _openComposer,
                        icon: const Icon(Icons.add),
                      ),
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
          child: hasSearchQuery && !hasAnyVisibleTodos
              ? const _SearchEmptyState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (showAllSectionsInSearch ||
                        importantTodos.isNotEmpty) ...[
                      TodoSectionPanel(
                        title: 'Important',
                        todos: importantTodos,
                        isExpanded: effectiveImportantExpanded,
                        onToggleExpanded: () {
                          setState(() {
                            _importantExpanded = !_importantExpanded;
                          });
                        },
                        batchMode: _batchMode,
                        onReorder: _batchMode
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
                      isExpanded: effectivePendingExpanded,
                      onToggleExpanded: () {
                        setState(() {
                          _pendingExpanded = !_pendingExpanded;
                        });
                      },
                      batchMode: _batchMode,
                      onReorder: _batchMode
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
                      isExpanded: effectiveCompletedExpanded,
                      onToggleExpanded: () {
                        setState(() {
                          _completedExpanded = !_completedExpanded;
                        });
                      },
                      batchMode: _batchMode,
                      onReorder: _batchMode
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

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No todos match this search.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchModeTitle extends StatelessWidget {
  const _BatchModeTitle({required this.selectedCount, super.key});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          selectedCount == 0 ? 'Edit' : '$selectedCount selected',
          key: ValueKey(selectedCount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
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
    super.key,
  });

  final String tooltip;
  final VoidCallback? onPressed;
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
