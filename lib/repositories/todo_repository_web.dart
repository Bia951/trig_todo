// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../models/todo.dart';
import 'todo_repository.dart';

const _storageKey = 'trig.todo.items.v2';

Future<TodoRepository> createPlatformTodoRepository() async {
  return WebTodoRepository();
}

class WebTodoRepository extends TodoRepository {
  final html.Storage _storage = html.window.localStorage;

  @override
  Future<void> clear() async {
    _storage.remove(_storageKey);
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> deleteTodo(String todoId) async {
    final todos = await loadTodos();
    todos.removeWhere((todo) => todo.id == todoId);
    await _writeTodos(todos);
  }

  @override
  Future<List<Todo>> loadTodos() async {
    final raw = _storage[_storageKey];
    if (raw == null || raw.isEmpty) {
      return <Todo>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => Todo.fromJson(
            Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    final todos = await loadTodos();
    final index = todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) {
      todos.add(todo);
    } else {
      todos[index] = todo;
    }
    await _writeTodos(todos);
  }

  Future<void> _writeTodos(List<Todo> todos) async {
    _storage[_storageKey] = jsonEncode(
      todos.map((todo) => todo.toJson()).toList(growable: false),
    );
  }
}
