// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../models/todo_list.dart';
import 'todo_list_repository.dart';

const _storageKey = 'trig.lists.v1';

Future<TodoListRepository> createPlatformTodoListRepository() async {
  return WebTodoListRepository();
}

class WebTodoListRepository extends TodoListRepository {
  final html.Storage _storage = html.window.localStorage;

  @override
  Future<({List<TodoList> lists, String? activeListId})> load() async {
    final raw = _storage[_storageKey];
    if (raw == null || raw.isEmpty) {
      return (lists: <TodoList>[], activeListId: null);
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final listsJson = json['lists'] as List<dynamic>? ?? [];
      final lists = listsJson
          .map((e) => TodoList.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
      final activeListId = json['activeListId'] as String?;
      return (lists: lists, activeListId: activeListId);
    } catch (_) {
      return (lists: <TodoList>[], activeListId: null);
    }
  }

  @override
  Future<void> saveList(TodoList list) async {
    final (:lists, :activeListId) = await load();
    final mutable = lists.toList();
    final index = mutable.indexWhere((l) => l.id == list.id);
    if (index == -1) {
      mutable.add(list);
    } else {
      mutable[index] = list;
    }
    await _write(mutable, activeListId);
  }

  @override
  Future<void> deleteList(String id) async {
    final (:lists, :activeListId) = await load();
    final mutable = lists.where((l) => l.id != id).toList();
    await _write(mutable, activeListId);
  }

  @override
  Future<void> saveActiveListId(String id) async {
    final (:lists, activeListId: _) = await load();
    await _write(lists, id);
  }

  @override
  Future<void> close() async {}

  Future<void> _write(List<TodoList> lists, String? activeListId) async {
    _storage[_storageKey] = jsonEncode(<String, dynamic>{
      'activeListId': activeListId,
      'lists': lists.map((l) => l.toJson()).toList(growable: false),
    });
  }
}
