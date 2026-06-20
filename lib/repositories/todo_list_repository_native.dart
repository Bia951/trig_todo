import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/todo_list.dart';
import 'todo_list_repository.dart';

Future<TodoListRepository> createPlatformTodoListRepository() async {
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}/trig_lists_v1.json');
  return NativeTodoListRepository(file);
}

class NativeTodoListRepository extends TodoListRepository {
  NativeTodoListRepository(this._file);

  final File _file;

  @override
  Future<({List<TodoList> lists, String? activeListId})> load() async {
    try {
      if (!await _file.exists()) {
        return (lists: <TodoList>[], activeListId: null);
      }
      final raw = await _file.readAsString();
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
    final json = <String, dynamic>{
      'activeListId': activeListId,
      'lists': lists.map((l) => l.toJson()).toList(growable: false),
    };
    await _file.writeAsString(jsonEncode(json));
  }
}
