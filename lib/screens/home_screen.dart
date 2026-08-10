import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../layout/app_layout_profile.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/desktop_todo_inspector.dart';
import '../widgets/move_to_list_sheet.dart';
import '../widgets/page_title.dart';
import '../widgets/todo_editor.dart';
import '../widgets/todo_section_panel.dart';
import '../widgets/todo_side_panel.dart';
import '../widgets/todo_tile.dart';
import '../widgets/undo_snackbar.dart';
import 'schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _batchModeFocusNode;
  bool _batchMode = false;
  final Set<String> _selectedTodoIds = <String>{};
  bool _didInitializeExpansions = false;
  bool _importantExpanded = false;
  bool _pendingExpanded = true;
  bool _completedExpanded = false;
  String? _inspectedTodoId;
  TodoEditorSession? _editorSession;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _batchModeFocusNode = FocusNode(debugLabel: 'Batch mode keyboard focus');
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
    _batchModeFocusNode.dispose();
    _editorSession?.dispose();
    super.dispose();
  }

  void _openComposer() {
    _dismissKeyboard();
    final provider = context.read<TodoProvider>();
    _startEditor(provider.createDraft(), isNew: true);
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _restoreShortcutFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_batchMode) {
        _batchModeFocusNode.requestFocus();
      }
    });
  }

  void _startEditor(Todo todo, {required bool isNew}) {
    final previousSession = _editorSession;
    setState(() {
      _editorSession = TodoEditorSession(initialTodo: todo, isNew: isNew);
    });
    previousSession?.dispose();
  }

  void _closeEditor() {
    final session = _editorSession;
    if (session == null) return;
    _dismissKeyboard();
    setState(() => _editorSession = null);
    session.dispose();
    _restoreShortcutFocus();
  }

  void _dismissActiveSidePanel() {
    if (_editorSession != null) {
      _closeEditor();
      return;
    }
    if (_inspectedTodoId != null) {
      _dismissKeyboard();
      setState(() => _inspectedTodoId = null);
      _restoreShortcutFocus();
    }
  }

  void _saveEditor(Todo todo) {
    final provider = context.read<TodoProvider>();
    final session = _editorSession;
    provider.saveTodo(todo);
    setState(() {
      _inspectedTodoId = todo.id;
      _editorSession = null;
    });
    session?.dispose();
    _restoreShortcutFocus();
  }

  void _deleteEditor() {
    final session = _editorSession;
    if (session == null) return;
    if (session.isNew) {
      _closeEditor();
      return;
    }

    final provider = context.read<TodoProvider>();
    final removed = provider.removeTodo(session.draft.id);
    setState(() {
      _inspectedTodoId = null;
      _editorSession = null;
    });
    session.dispose();
    if (removed.isNotEmpty && mounted) {
      showUndoTodoSnackBar(
        ScaffoldMessenger.of(context),
        theme: Theme.of(context),
        message: 'Deleted "${removed.single.presentationTitle}"',
        onUndo: () => provider.restoreTodos(removed),
      );
    }
    _restoreShortcutFocus();
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

    if (willEnterBatchMode) {
      _batchModeFocusNode.requestFocus();
    }
  }

  void _toggleCompleted(Todo todo) {
    context.read<TodoProvider>().toggleCompleted(todo.id);
    if (!todo.isCompleted) {
      setState(() {
        _completedExpanded = false;
      });
    }
  }

  void _openTodoDetail(Todo todo, {required bool startInEditMode}) {
    if (startInEditMode) {
      _dismissKeyboard();
      _startEditor(todo, isNew: false);
      return;
    }
    _dismissKeyboard();
    setState(() => _inspectedTodoId = todo.id);
    _restoreShortcutFocus();
  }

  void _toggleSelectedTodo(String id) {
    setState(() {
      if (!_selectedTodoIds.add(id)) {
        _selectedTodoIds.remove(id);
      }
    });
  }

  Todo? _todoById(Iterable<Todo> todos, String? id) {
    if (id == null) return null;
    for (final todo in todos) {
      if (todo.id == id) return todo;
    }
    return null;
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

    final removed = provider.removeTodos(selectedTodos.map((todo) => todo.id));
    setState(() {
      _selectedTodoIds.clear();
    });
    if (removed.isNotEmpty && mounted) {
      showUndoTodoSnackBar(
        ScaffoldMessenger.of(context),
        theme: Theme.of(context),
        message: removed.length == 1
            ? 'Deleted "${removed.single.presentationTitle}"'
            : 'Deleted ${removed.length} todos',
        onUndo: () => provider.restoreTodos(removed),
      );
    }
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
      isPreviewSelected: !_batchMode && _inspectedTodoId == todo.id,
      onOpenPreview: () => _openTodoDetail(todo, startInEditMode: false),
      onOpenEdit: () => _openTodoDetail(todo, startInEditMode: true),
      onToggleSelected: () => _toggleSelectedTodo(todo.id),
      onToggleMute: () => context.read<TodoProvider>().toggleMute(todo.id),
      onToggleCompleted: () => _toggleCompleted(todo),
      onToggleStarred: () =>
          context.read<TodoProvider>().toggleStarred(todo.id),
      onMoveToList: () => MoveToListSheet.show(
        context,
        todoId: todo.id,
        currentListId: todo.listId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todoProvider = context.watch<TodoProvider>();
    if (todoProvider.showingSchedule) {
      return const ScheduleScreen();
    }
    final isTodayView = todoProvider.showingToday;
    final importantTodos = isTodayView
        ? todoProvider.todayImportantTodos
        : todoProvider.importantTodos;
    final pendingTodos = isTodayView
        ? todoProvider.todayPendingTodos
        : todoProvider.pendingTodos;
    final completedTodos = isTodayView
        ? const <Todo>[]
        : todoProvider.completedTodos;
    final selectedVisibleTodoCount = <Todo>[
      ...importantTodos,
      ...pendingTodos,
      ...completedTodos,
    ].where((todo) => _selectedTodoIds.contains(todo.id)).length;
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

    final profile = AppLayoutProfile.of(context);
    final usesDesktopInteractions = profile.usesDesktopInteractions;
    final hasPersistentNavigation = profile.hasPersistentNavigation;
    final hasDockedDetailsPanel = profile.hasDockedDetailsPanel;
    final activeList = todoProvider.activeList;
    final inspectedTodo = _todoById(todoProvider.todos, _inspectedTodoId);

    return Focus(
      focusNode: _batchModeFocusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (_batchMode) {
            _exitBatchMode();
            return KeyEventResult.handled;
          }
          if (_editorSession != null || _inspectedTodoId != null) {
            _dismissActiveSidePanel();
            return KeyEventResult.handled;
          }
        }
        if (usesDesktopInteractions && !_batchMode && _editorSession == null) {
          if (event.logicalKey == LogicalKeyboardKey.keyN) {
            _openComposer();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyE &&
              inspectedTodo != null) {
            _openTodoDetail(inspectedTodo, startInEditMode: true);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            appBar: AppBar(
              leadingWidth: hasPersistentNavigation ? 0 : 64,
              leading: hasPersistentNavigation
                  ? null
                  : _batchMode
                  ? Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _ToolbarCircleButton(
                          tooltip: 'Finish edit',
                          onPressed: _toggleBatchMode,
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _ToolbarCircleButton(
                          tooltip: 'Open lists',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      ),
                    ),
              titleSpacing: 0,
              title: Padding(
                padding: EdgeInsets.only(
                  left: hasPersistentNavigation ? 32 : 4,
                  right: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _batchMode
                      ? _BatchModeTitle(
                          key: const ValueKey('batch-title'),
                          selectedCount: selectedVisibleTodoCount,
                          alignment: Alignment.centerLeft,
                        )
                      : isTodayView
                      ? PageTitle(
                          key: const ValueKey('today-title'),
                          icon: Icons.today_rounded,
                          color: theme.colorScheme.primary,
                          label: 'Today',
                        )
                      : PageTitle(
                          key: const ValueKey('list-title'),
                          icon: activeList?.icon ?? Icons.list_rounded,
                          color:
                              activeList?.colorFor(theme.colorScheme) ??
                              theme.colorScheme.primary,
                          label: activeList?.name ?? 'Trig',
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
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ToolbarCircleButton(
                                  tooltip: 'Complete selected',
                                  onPressed: selectedVisibleTodoCount == 0
                                      ? null
                                      : _completeSelectedTodos,
                                  icon: const Icon(Icons.check_box_outlined),
                                ),
                                const SizedBox(width: 8),
                                _ToolbarCircleButton(
                                  tooltip: 'Finish edit',
                                  onPressed: _toggleBatchMode,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('normal-actions'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ToolbarCircleButton(
                                  tooltip: 'Edit',
                                  onPressed: _toggleBatchMode,
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                if (usesDesktopInteractions)
                                  const SizedBox(width: 8),
                                if (usesDesktopInteractions)
                                  _ToolbarCircleButton(
                                    tooltip: 'Add todo',
                                    onPressed: _openComposer,
                                    icon: const Icon(Icons.add),
                                    accent: true,
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: !usesDesktopInteractions && !_batchMode
                ? FloatingActionButton.extended(
                    tooltip: 'Add todo',
                    onPressed: _openComposer,
                    icon: Icon(
                      Icons.add_rounded,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    label: const Text('New todo'),
                  )
                : null,
            body: Row(
              children: [
                Expanded(
                  child: DecoratedBox(
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
                                  onReorder: _batchMode && !isTodayView
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
                                      : isTodayView
                                      ? 'No important todos today.'
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
                                onReorder: _batchMode && !isTodayView
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
                                    : isTodayView
                                    ? 'Nothing else is scheduled for today.'
                                    : 'No pending todos yet.',
                                tileBuilder: _buildSectionTile,
                              ),
                              const SizedBox(height: 14),
                              if (!isTodayView)
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
                if (hasDockedDetailsPanel) ...[
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  SizedBox(
                    width: 340,
                    child: TodoSidePanelSurface(
                      onDismiss: _dismissActiveSidePanel,
                      child: _editorSession == null
                          ? DesktopTodoInspector(
                              key: const ValueKey('todo-inspector-docked'),
                              todo: inspectedTodo,
                              onDismiss: _dismissActiveSidePanel,
                              onEdit: inspectedTodo == null
                                  ? () {}
                                  : () => _openTodoDetail(
                                      inspectedTodo,
                                      startInEditMode: true,
                                    ),
                              onToggleCompleted: inspectedTodo == null
                                  ? () {}
                                  : () => _toggleCompleted(inspectedTodo),
                              onToggleStarred: inspectedTodo == null
                                  ? () {}
                                  : () => todoProvider.toggleStarred(
                                      inspectedTodo.id,
                                    ),
                              onToggleMute: inspectedTodo == null
                                  ? () {}
                                  : () => todoProvider.toggleMute(
                                      inspectedTodo.id,
                                    ),
                            )
                          : TodoEditorPane(
                              key: const ValueKey('todo-editor-docked'),
                              session: _editorSession!,
                              onClose: _closeEditor,
                              onSave: _saveEditor,
                              onDelete: _deleteEditor,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!hasDockedDetailsPanel &&
              (_editorSession != null || inspectedTodo != null))
            TodoSidePanelOverlay(
              onDismiss: _dismissActiveSidePanel,
              child: _editorSession != null
                  ? TodoEditorPane(
                      key: const ValueKey('todo-editor-overlay'),
                      session: _editorSession!,
                      onClose: _closeEditor,
                      onSave: _saveEditor,
                      onDelete: _deleteEditor,
                      isOverlay: true,
                    )
                  : DesktopTodoInspector(
                      key: const ValueKey('todo-inspector-overlay'),
                      todo: inspectedTodo,
                      onDismiss: _dismissActiveSidePanel,
                      onEdit: () => _openTodoDetail(
                        inspectedTodo!,
                        startInEditMode: true,
                      ),
                      onToggleCompleted: () => _toggleCompleted(inspectedTodo!),
                      onToggleStarred: () =>
                          todoProvider.toggleStarred(inspectedTodo!.id),
                      onToggleMute: () =>
                          todoProvider.toggleMute(inspectedTodo!.id),
                    ),
            ),
        ],
      ),
    );
  }

  void _exitBatchMode() {
    if (_batchMode) {
      _toggleBatchMode();
    }
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
  const _BatchModeTitle({
    required this.selectedCount,
    required this.alignment,
    super.key,
  });

  final int selectedCount;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: alignment,
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
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
    this.accent = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: 44,
      child: accent
          ? IconButton.filled(
              tooltip: tooltip,
              onPressed: onPressed,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(44),
                maximumSize: const Size.square(44),
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
              icon: icon,
            )
          : IconButton.filledTonal(
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
