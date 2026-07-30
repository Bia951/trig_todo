import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../models/todo_list.dart';
import '../repositories/in_memory_todo_list_repository.dart';
import '../repositories/in_memory_todo_repository.dart';
import '../repositories/todo_list_repository.dart';
import '../repositories/todo_list_repository_factory.dart';
import '../repositories/todo_repository.dart';
import '../repositories/todo_repository_factory.dart';
import '../services/todo_reminder_scheduler.dart';
import '../services/todo_reminder_scheduler_factory.dart';

enum TodoBucket { important, pending, completed }

class TodoProvider extends ChangeNotifier {
  TodoProvider({
    List<Todo>? initialTodos,
    List<TodoList>? initialLists,
    String? initialActiveListId,
    TodoRepository? repository,
    TodoListRepository? listRepository,
    TodoReminderScheduler? reminderScheduler,
  }) : _repository =
           repository ??
           InMemoryTodoRepository(initialTodos: initialTodos ?? []),
       _listRepository = listRepository ?? InMemoryTodoListRepository(),
       _reminderScheduler = reminderScheduler ?? NoopTodoReminderScheduler(),
       _todos = List<Todo>.from(initialTodos ?? []),
       _lists = List<TodoList>.from(initialLists ?? _buildSeedLists()),
       _activeListId =
           initialActiveListId ??
           (initialLists == null ? TodoList.inboxId : '') {
    _sortTodos();
    _sortLists();
  }

  static Future<TodoProvider> bootstrap() async {
    try {
      final todoRepository = await createTodoRepository();
      final listRepository = await createTodoListRepository();
      final provider = TodoProvider(
        initialTodos: const <Todo>[],
        repository: todoRepository,
        listRepository: listRepository,
      );
      await provider.hydrate();
      return provider;
    } on Object catch (error, stackTrace) {
      // A damaged database must not prevent the application shell from
      // appearing. The user can still work with an in-memory session.
      debugPrint('Failed to open persisted todo data: $error\n$stackTrace');
      final provider = TodoProvider();
      await provider.hydrate();
      return provider;
    }
  }

  final TodoRepository _repository;
  final TodoListRepository _listRepository;
  TodoReminderScheduler _reminderScheduler;
  Future<void>? _reminderInitialization;
  final List<Todo> _todos;
  final List<TodoList> _lists;
  String _activeListId;
  bool _showingToday = false;
  String _searchQuery = '';

  // ── List accessors ──

  UnmodifiableListView<TodoList> get lists => UnmodifiableListView(_lists);
  String get activeListId => _activeListId;
  bool get showingToday => _showingToday;
  TodoList? get activeList => _lists.cast<TodoList?>().firstWhere(
    (l) => l?.id == _activeListId,
    orElse: () => null,
  );

  int countForList(String listId) =>
      _todos.where((t) => t.listId == listId && !t.isCompleted).length;

  // ── Todo accessors (scoped to active list) ──

  UnmodifiableListView<Todo> get todos => UnmodifiableListView(_todos);
  String get searchQuery => _searchQuery;
  bool get hasImportantTodos => _todos.any(
    (todo) =>
        todo.listId == _activeListId && todo.isStarred && !todo.isCompleted,
  );

  List<Todo> get filteredTodos {
    final listScoped = _todos.where((t) => t.listId == _activeListId);
    if (_searchQuery.trim().isEmpty) {
      return List<Todo>.unmodifiable(listScoped);
    }
    final q = _searchQuery.trim().toLowerCase();
    return List<Todo>.unmodifiable(
      listScoped.where((todo) => _buildSearchableText(todo).contains(q)),
    );
  }

  List<Todo> get completedTodos => _todosForBucket(TodoBucket.completed);
  List<Todo> get importantTodos => _todosForBucket(TodoBucket.important);
  List<Todo> get pendingTodos => _todosForBucket(TodoBucket.pending);
  List<Todo> get todayTodos => _todayTodosForBucket();
  List<Todo> get todayCompletedTodos =>
      _todayTodosForBucket(bucket: TodoBucket.completed);
  List<Todo> get todayImportantTodos =>
      _todayTodosForBucket(bucket: TodoBucket.important);
  List<Todo> get todayPendingTodos =>
      _todayTodosForBucket(bucket: TodoBucket.pending);
  int get todayTodoCount => todayTodos.length;

  // ── Hydrate ──

  Future<void> hydrate({bool seedIfEmpty = true}) async {
    // Load lists first
    final (:lists, :activeListId) = await _listRepository.load();
    final normalizedLists = lists
        .map(
          (list) => list.id == TodoList.inboxId && list.name == '收件箱'
              ? list.copyWith(name: 'Inbox')
              : list,
        )
        .toList(growable: false);
    final didRenameInbox = normalizedLists.asMap().entries.any(
      (entry) => entry.value.name != lists[entry.key].name,
    );
    final needsInbox =
        seedIfEmpty && normalizedLists.every((list) => !list.isInbox);
    final effectiveLists = normalizedLists.isEmpty && seedIfEmpty
        ? _buildSeedLists()
        : needsInbox
        ? <TodoList>[_buildSeedLists().single, ...normalizedLists]
        : normalizedLists;

    _lists
      ..clear()
      ..addAll(effectiveLists);
    _sortLists();

    if ((lists.isEmpty && seedIfEmpty) || didRenameInbox || needsInbox) {
      for (final l in _lists) {
        unawaited(_listRepository.saveList(l));
      }
    }

    final firstListId = _lists.isNotEmpty ? _lists.first.id : '';
    _activeListId =
        activeListId != null && _lists.any((l) => l.id == activeListId)
        ? activeListId
        : firstListId;
    unawaited(_listRepository.saveActiveListId(_activeListId));

    // Load todos
    final persistedTodos = await _repository.loadTodos();
    final effectiveTodos = persistedTodos.isEmpty && seedIfEmpty
        ? _buildSeedTodos(defaultListId: firstListId)
        : persistedTodos;
    final normalizedTodos = effectiveTodos
        .map(_ensureTodoHasList)
        .toList(growable: false);
    final didRepairTodoLists = normalizedTodos.asMap().entries.any(
      (entry) => entry.value.listId != effectiveTodos[entry.key].listId,
    );

    _todos
      ..clear()
      ..addAll(normalizedTodos);
    _sortTodos();
    notifyListeners();

    if ((persistedTodos.isEmpty && seedIfEmpty) || didRepairTodoLists) {
      await _repository.replaceAll(_todos);
    }

    await _reminderScheduler.syncTodos(_todos);
  }

  /// Starts notification setup after the first app frame.
  ///
  /// First-launch permission prompts and platform plugin initialization must not
  /// hold up the initial UI. Repeated calls share the same initialization.
  Future<void> initializeReminderScheduler() {
    return _reminderInitialization ??= _initializeReminderScheduler();
  }

  Future<void> _initializeReminderScheduler() async {
    try {
      final scheduler = await createTodoReminderScheduler();
      final previousScheduler = _reminderScheduler;
      _reminderScheduler = scheduler;
      await scheduler.syncTodos(List<Todo>.unmodifiable(_todos));
      await previousScheduler.dispose();
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to initialize todo reminders: $error\n$stackTrace');
    }
  }

  // ── List management ──

  void setActiveList(String id) {
    if (_activeListId == id && !_showingToday) return;
    _activeListId = id;
    _showingToday = false;
    _searchQuery = '';
    notifyListeners();
    unawaited(_listRepository.saveActiveListId(id));
  }

  void showToday() {
    if (_showingToday) return;
    _showingToday = true;
    _searchQuery = '';
    notifyListeners();
  }

  void saveTodoList(TodoList list) {
    final index = _lists.indexWhere((l) => l.id == list.id);
    if (index == -1) {
      _lists.add(list);
    } else {
      _lists[index] = list;
    }
    _sortLists();
    notifyListeners();
    unawaited(_listRepository.saveList(list));
  }

  void deleteTodoList(String id) {
    if (id == TodoList.inboxId) return;
    final inboxId = _inboxListId;
    if (inboxId == null) return;

    final reassignedTodos = <Todo>[];
    for (var index = 0; index < _todos.length; index++) {
      final todo = _todos[index];
      if (todo.listId != id) continue;
      final reassigned = todo.copyWith(listId: inboxId);
      _todos[index] = reassigned;
      reassignedTodos.add(reassigned);
    }
    _lists.removeWhere((l) => l.id == id);
    if (_activeListId == id) {
      _activeListId = inboxId;
      unawaited(_listRepository.saveActiveListId(_activeListId));
    }
    notifyListeners();
    unawaited(_listRepository.deleteList(id));
    for (final todo in reassignedTodos) {
      unawaited(_persistUpsert(todo));
    }
  }

  void reorderLists(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = _lists.removeAt(oldIndex);
    _lists.insert(newIndex, moved);
    for (var i = 0; i < _lists.length; i++) {
      _lists[i] = _lists[i].copyWith(sortOrder: i);
      unawaited(_listRepository.saveList(_lists[i]));
    }
    notifyListeners();
  }

  void moveTodoToList(String todoId, String targetListId) {
    if (!_lists.any((list) => list.id == targetListId)) return;
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index == -1) return;
    final updated = _todos[index].copyWith(listId: targetListId);
    _todos[index] = updated;
    notifyListeners();
    unawaited(_persistUpsert(updated));
  }

  // ── Todo management (unchanged logic, scoped to active list) ──

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  Todo createDraft({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    return Todo(
      id: now.microsecondsSinceEpoch.toString(),
      listId: _activeListId,
      title: '',
      content: '',
      reminderTime: now.add(const Duration(hours: 1)),
      deadline: now.add(const Duration(days: 1)),
      remindDaysBeforeDDL: 1,
      notes: '',
      isMuted: false,
      isCompleted: false,
      isStarred: false,
      sortOrder: _nextSortOrder(TodoBucket.pending),
    );
  }

  void addTodo(Todo todo) {
    final normalizedTodo = _ensureTodoHasList(todo);
    _todos.add(normalizedTodo);
    _sortTodos();
    notifyListeners();
    unawaited(_persistUpsert(normalizedTodo));
  }

  void updateTodo(Todo updatedTodo) {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index == -1) return;
    final normalizedTodo = _ensureTodoHasList(updatedTodo);
    _todos[index] = normalizedTodo;
    _sortTodos();
    notifyListeners();
    unawaited(_persistUpsert(normalizedTodo));
  }

  void saveTodo(Todo todo) {
    final exists = _todos.any((item) => item.id == todo.id);
    if (exists) {
      updateTodo(todo);
      return;
    }
    addTodo(todo);
  }

  List<Todo> removeTodo(String id) {
    final removed = _todos
        .where((todo) => todo.id == id)
        .toList(growable: false);
    if (removed.isEmpty) return removed;
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
    unawaited(_persistDelete(id));
    return removed;
  }

  List<Todo> removeTodos(Iterable<String> ids) {
    final idsToRemove = ids.toSet();
    if (idsToRemove.isEmpty) return const [];
    final removed = _todos
        .where((todo) => idsToRemove.contains(todo.id))
        .toList(growable: false);
    if (removed.isEmpty) return removed;
    _todos.removeWhere((todo) => idsToRemove.contains(todo.id));
    notifyListeners();
    for (final id in idsToRemove) {
      unawaited(_persistDelete(id));
    }
    return removed;
  }

  void restoreTodos(Iterable<Todo> todos) {
    final toRestore = todos.toList(growable: false);
    if (toRestore.isEmpty) return;
    _todos.addAll(toRestore);
    _sortTodos();
    notifyListeners();
    for (final todo in toRestore) {
      unawaited(_persistUpsert(todo));
    }
  }

  void toggleMute(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index].copyWith(isMuted: !_todos[index].isMuted);
    _todos[index] = current;
    notifyListeners();
    unawaited(_persistUpsert(current));
  }

  void toggleCompleted(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index];
    final willComplete = !current.isCompleted;
    final targetBucket = willComplete
        ? TodoBucket.completed
        : (current.isStarred ? TodoBucket.important : TodoBucket.pending);
    final updated = current.copyWith(
      isCompleted: willComplete,
      sortOrder: _nextSortOrder(targetBucket, excludingId: id),
    );
    _todos[index] = updated;
    _sortTodos();
    notifyListeners();
    unawaited(_persistUpsert(updated));
  }

  void completeTodos(Iterable<String> ids) {
    final idsToComplete = ids.toSet();
    if (idsToComplete.isEmpty) return;
    final updatedTodos = <Todo>[];
    for (var index = 0; index < _todos.length; index++) {
      final current = _todos[index];
      if (!idsToComplete.contains(current.id) || current.isCompleted) continue;
      final updated = current.copyWith(
        isCompleted: true,
        sortOrder: _nextSortOrder(
          TodoBucket.completed,
          excludingId: current.id,
        ),
      );
      _todos[index] = updated;
      updatedTodos.add(updated);
    }
    if (updatedTodos.isEmpty) return;
    _sortTodos();
    notifyListeners();
    for (final todo in updatedTodos) {
      unawaited(_persistUpsert(todo));
    }
  }

  void toggleStarred(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    final current = _todos[index];
    final willStar = !current.isStarred;
    final targetBucket = current.isCompleted
        ? TodoBucket.completed
        : (willStar ? TodoBucket.important : TodoBucket.pending);
    final updated = current.copyWith(
      isStarred: willStar,
      sortOrder: current.isCompleted
          ? current.sortOrder
          : _nextSortOrder(targetBucket, excludingId: id),
    );
    _todos[index] = updated;
    _sortTodos();
    notifyListeners();
    unawaited(_persistUpsert(updated));
  }

  void reorderTodos({
    required TodoBucket bucket,
    required int oldIndex,
    required int newIndex,
  }) {
    final bucketTodos = _todosForBucket(bucket, includeSearch: false);
    if (bucketTodos.isEmpty) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 ||
        oldIndex >= bucketTodos.length ||
        newIndex < 0 ||
        newIndex >= bucketTodos.length) {
      return;
    }
    final reordered = List<Todo>.from(bucketTodos);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    for (var index = 0; index < reordered.length; index++) {
      final updatedTodo = reordered[index].copyWith(sortOrder: index);
      final todoIndex = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
      if (todoIndex != -1) {
        _todos[todoIndex] = updatedTodo;
        unawaited(_persistUpsert(updatedTodo));
      }
    }
    _sortTodos();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_repository.close());
    unawaited(_listRepository.close());
    unawaited(_reminderScheduler.dispose());
    super.dispose();
  }

  // ── Private helpers ──

  Future<void> _persistDelete(String id) async {
    try {
      await _repository.deleteTodo(id);
      await _reminderScheduler.cancelTodo(id);
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to delete todo $id: $error\n$stackTrace');
    }
  }

  Future<void> _persistUpsert(Todo todo) async {
    try {
      await _repository.saveTodo(todo);
      await _reminderScheduler.syncTodo(todo);
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to persist todo ${todo.id}: $error\n$stackTrace');
    }
  }

  String _buildSearchableText(Todo todo) {
    return [
      todo.title,
      todo.content,
      todo.notes,
      _formatSearchDateTime(todo.reminderTime),
      _formatSearchDateTime(todo.deadline),
      todo.reminderTime.toIso8601String(),
      todo.deadline.toIso8601String(),
    ].join(' ').toLowerCase();
  }

  String _formatSearchDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  void _sortTodos() {
    _todos.sort((a, b) {
      final bucketCompare = _bucketRank(a).compareTo(_bucketRank(b));
      if (bucketCompare != 0) return bucketCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.reminderTime.compareTo(b.reminderTime);
    });
  }

  void _sortLists() {
    _lists.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  int _bucketRank(Todo todo) {
    switch (_bucketFor(todo)) {
      case TodoBucket.important:
        return 0;
      case TodoBucket.pending:
        return 1;
      case TodoBucket.completed:
        return 2;
    }
  }

  TodoBucket _bucketFor(Todo todo) {
    if (todo.isCompleted) return TodoBucket.completed;
    if (todo.isStarred) return TodoBucket.important;
    return TodoBucket.pending;
  }

  int _nextSortOrder(TodoBucket bucket, {String? excludingId}) {
    final bucketTodos = _todos
        .where((todo) {
          if (excludingId != null && todo.id == excludingId) return false;
          return todo.listId == _activeListId && _bucketFor(todo) == bucket;
        })
        .toList(growable: false);
    if (bucketTodos.isEmpty) return 0;
    return bucketTodos
            .map((todo) => todo.sortOrder)
            .reduce((v, e) => v > e ? v : e) +
        1;
  }

  List<Todo> _todosForBucket(TodoBucket bucket, {bool includeSearch = true}) {
    final source = includeSearch
        ? filteredTodos
        : _todos.where((t) => t.listId == _activeListId).toList();
    return List<Todo>.unmodifiable(
      source.where((todo) => _bucketFor(todo) == bucket),
    );
  }

  List<Todo> _todayTodosForBucket({TodoBucket? bucket}) {
    final today = DateTime.now();
    final visibleTodos = _todos.where(
      (todo) =>
          !todo.isCompleted &&
          (_isSameDay(todo.reminderTime, today) ||
              _isSameDay(todo.deadline, today)),
    );
    final query = _searchQuery.trim().toLowerCase();
    final matchingTodos = query.isEmpty
        ? visibleTodos
        : visibleTodos.where(
            (todo) => _buildSearchableText(todo).contains(query),
          );
    return List<Todo>.unmodifiable(
      matchingTodos.where(
        (todo) => bucket == null || _bucketFor(todo) == bucket,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String? get _inboxListId => _lists
      .cast<TodoList?>()
      .firstWhere((list) => list?.isInbox ?? false, orElse: () => null)
      ?.id;

  Todo _ensureTodoHasList(Todo todo) {
    if (_lists.any((list) => list.id == todo.listId)) return todo;
    return todo.copyWith(listId: _inboxListId ?? TodoList.inboxId);
  }

  static List<TodoList> _buildSeedLists() {
    return [
      TodoList(
        id: TodoList.inboxId,
        name: 'Inbox',
        iconCodePoint: Icons.inbox_rounded.codePoint,
        colorValue: 0xFF1D7860,
        sortOrder: 0,
      ),
    ];
  }

  static List<Todo> _buildSeedTodos({String defaultListId = TodoList.inboxId}) {
    final now = DateTime.now();
    return [
      Todo(
        id: 'seed-1',
        listId: defaultListId,
        title: 'Morning focus',
        content: 'Review the shipping checklist and trim the backlog.',
        reminderTime: now.add(const Duration(minutes: 45)),
        deadline: now.add(const Duration(hours: 5)),
        remindDaysBeforeDDL: 0,
        notes: 'Keep the first hour meeting-free.',
        isMuted: false,
        isCompleted: false,
        isStarred: false,
        sortOrder: 0,
      ),
      Todo(
        id: 'seed-2',
        listId: defaultListId,
        title: 'Design review',
        content:
            'Confirm motion, spacing and edge-case handling for the popup.',
        reminderTime: now.add(const Duration(hours: 3)),
        deadline: now.add(const Duration(days: 1)),
        remindDaysBeforeDDL: 1,
        notes: 'Bring both mobile and desktop screenshots.',
        isMuted: false,
        isCompleted: false,
        isStarred: true,
        sortOrder: 0,
      ),
      Todo(
        id: 'seed-3',
        listId: defaultListId,
        title: 'Grocery refill',
        content: 'Pick up fruit, oat milk and coffee before the week starts.',
        reminderTime: now.add(const Duration(days: 1, hours: 2)),
        deadline: now.add(const Duration(days: 2, hours: 8)),
        remindDaysBeforeDDL: 2,
        notes: 'Check discount shelf first.',
        isMuted: true,
        isCompleted: false,
        isStarred: false,
        sortOrder: 1,
      ),
    ];
  }
}
