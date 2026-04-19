import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/todo.dart';
import '../repositories/in_memory_todo_repository.dart';
import '../repositories/todo_repository.dart';
import '../repositories/todo_repository_factory.dart';
import '../services/todo_reminder_scheduler.dart';
import '../services/todo_reminder_scheduler_factory.dart';

enum TodoBucket { important, pending, completed }

class TodoProvider extends ChangeNotifier {
  TodoProvider({
    List<Todo>? initialTodos,
    TodoRepository? repository,
    TodoReminderScheduler? reminderScheduler,
  }) : _repository =
           repository ??
           InMemoryTodoRepository(
             initialTodos: initialTodos ?? _buildSeedTodos(),
           ),
       _reminderScheduler = reminderScheduler ?? NoopTodoReminderScheduler(),
       _todos = List<Todo>.from(initialTodos ?? _buildSeedTodos()) {
    _sortTodos();
  }

  static Future<TodoProvider> bootstrap() async {
    final repository = await createTodoRepository();
    final reminderScheduler = await createTodoReminderScheduler();
    final provider = TodoProvider(
      initialTodos: const <Todo>[],
      repository: repository,
      reminderScheduler: reminderScheduler,
    );
    await provider.hydrate();
    return provider;
  }

  final TodoRepository _repository;
  final TodoReminderScheduler _reminderScheduler;
  final List<Todo> _todos;
  String _searchQuery = '';

  UnmodifiableListView<Todo> get todos => UnmodifiableListView(_todos);
  String get searchQuery => _searchQuery;
  bool get hasImportantTodos =>
      _todos.any((todo) => todo.isStarred && !todo.isCompleted);

  List<Todo> get filteredTodos {
    if (_searchQuery.trim().isEmpty) {
      return List<Todo>.unmodifiable(_todos);
    }

    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return List<Todo>.unmodifiable(
      _todos.where((todo) {
        final searchableText = '${todo.title} ${todo.content} ${todo.notes}'
            .toLowerCase();
        return searchableText.contains(normalizedQuery);
      }),
    );
  }

  List<Todo> get completedTodos => _todosForBucket(TodoBucket.completed);

  List<Todo> get importantTodos => _todosForBucket(TodoBucket.important);

  List<Todo> get pendingTodos => _todosForBucket(TodoBucket.pending);

  Todo createDraft({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final reminder = now.add(const Duration(hours: 1));
    final deadline = now.add(const Duration(days: 1, hours: 6));

    return Todo(
      id: now.microsecondsSinceEpoch.toString(),
      title: '',
      content: '',
      reminderTime: reminder,
      deadline: deadline,
      remindDaysBeforeDDL: 1,
      notes: '',
      isMuted: false,
      isCompleted: false,
      isStarred: false,
      sortOrder: _nextSortOrder(TodoBucket.pending),
    );
  }

  Future<void> hydrate({bool seedIfEmpty = true}) async {
    final persistedTodos = await _repository.loadTodos();
    final effectiveTodos = persistedTodos.isEmpty && seedIfEmpty
        ? _buildSeedTodos()
        : persistedTodos;

    _todos
      ..clear()
      ..addAll(effectiveTodos);
    _sortTodos();
    notifyListeners();

    if (persistedTodos.isEmpty && seedIfEmpty) {
      await _repository.replaceAll(_todos);
    }

    await _reminderScheduler.syncTodos(_todos);
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    notifyListeners();
  }

  void addTodo(Todo todo) {
    _todos.add(todo);
    _sortTodos();
    notifyListeners();
    unawaited(_persistUpsert(todo));
  }

  void updateTodo(Todo updatedTodo) {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index == -1) {
      return;
    }

    _todos[index] = updatedTodo;
    _sortTodos();
    notifyListeners();
    unawaited(_persistUpsert(updatedTodo));
  }

  void saveTodo(Todo todo) {
    final exists = _todos.any((item) => item.id == todo.id);
    if (exists) {
      updateTodo(todo);
      return;
    }

    addTodo(todo);
  }

  void removeTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
    unawaited(_persistDelete(id));
  }

  void toggleMute(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      return;
    }

    final current = _todos[index].copyWith(isMuted: !_todos[index].isMuted);
    _todos[index] = current;
    notifyListeners();
    unawaited(_persistUpsert(current));
  }

  void toggleCompleted(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      return;
    }

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

  void toggleStarred(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      return;
    }

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
    if (bucketTodos.isEmpty) {
      return;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
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
    unawaited(_reminderScheduler.dispose());
    super.dispose();
  }

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

  void _sortTodos() {
    _todos.sort((a, b) {
      final bucketCompare = _bucketRank(a).compareTo(_bucketRank(b));
      if (bucketCompare != 0) {
        return bucketCompare;
      }

      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) {
        return sortCompare;
      }

      return a.reminderTime.compareTo(b.reminderTime);
    });
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
    if (todo.isCompleted) {
      return TodoBucket.completed;
    }
    if (todo.isStarred) {
      return TodoBucket.important;
    }
    return TodoBucket.pending;
  }

  int _nextSortOrder(TodoBucket bucket, {String? excludingId}) {
    final bucketTodos = _todos
        .where((todo) {
          if (excludingId != null && todo.id == excludingId) {
            return false;
          }
          return _bucketFor(todo) == bucket;
        })
        .toList(growable: false);
    if (bucketTodos.isEmpty) {
      return 0;
    }
    return bucketTodos
            .map((todo) => todo.sortOrder)
            .reduce((value, element) => value > element ? value : element) +
        1;
  }

  List<Todo> _todosForBucket(TodoBucket bucket, {bool includeSearch = true}) {
    final source = includeSearch ? filteredTodos : _todos;
    return List<Todo>.unmodifiable(
      source.where((todo) => _bucketFor(todo) == bucket),
    );
  }

  static List<Todo> _buildSeedTodos() {
    final now = DateTime.now();

    Todo buildTodo({
      required String id,
      required String title,
      required String content,
      required DateTime reminderTime,
      required DateTime deadline,
      required int remindDaysBeforeDDL,
      required String notes,
      required bool isMuted,
      required bool isCompleted,
      required bool isStarred,
      required int sortOrder,
    }) {
      return Todo(
        id: id,
        title: title,
        content: content,
        reminderTime: reminderTime,
        deadline: deadline,
        remindDaysBeforeDDL: remindDaysBeforeDDL,
        notes: notes,
        isMuted: isMuted,
        isCompleted: isCompleted,
        isStarred: isStarred,
        sortOrder: sortOrder,
      );
    }

    return [
      buildTodo(
        id: 'seed-1',
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
      buildTodo(
        id: 'seed-2',
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
      buildTodo(
        id: 'seed-3',
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
