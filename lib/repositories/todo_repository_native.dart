import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/todo.dart';
import '../models/todo_record.dart';
import 'todo_repository.dart';

const _isarInstanceName = 'trig_todo_v2';
const _listMapFileName = 'trig_todo_listmap_v1.json';

Future<TodoRepository> createPlatformTodoRepository() async {
  final existing = Isar.getInstance(_isarInstanceName);
  final directory = await getApplicationSupportDirectory();
  final listMapFile = File('${directory.path}/$_listMapFileName');

  if (existing != null) {
    return IsarTodoRepository(existing, listMapFile);
  }

  final isar = await Isar.open(
    <CollectionSchema<dynamic>>[TodoRecordSchema],
    directory: directory.path,
    name: _isarInstanceName,
  );
  return IsarTodoRepository(isar, listMapFile);
}

class IsarTodoRepository extends TodoRepository {
  IsarTodoRepository(this._isar, this._listMapFile);

  final Isar _isar;
  final File _listMapFile;
  Map<String, String> _listIdCache = {};
  bool _cacheLoaded = false;

  Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      if (await _listMapFile.exists()) {
        final decoded =
            jsonDecode(await _listMapFile.readAsString()) as Map<String, dynamic>;
        _listIdCache = decoded.cast<String, String>();
      }
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      await _listMapFile.writeAsString(jsonEncode(_listIdCache));
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    _listIdCache.clear();
    await _saveCache();
    await _isar.writeTxn(() async {
      await _isar.todoRecords.clear();
    });
  }

  @override
  Future<void> close() async {
    await _isar.close();
  }

  @override
  Future<void> deleteTodo(String todoId) async {
    await _loadCache();
    _listIdCache.remove(todoId);
    await _saveCache();
    await _isar.writeTxn(() async {
      await _isar.todoRecords.deleteByIndex('todoId', <Object?>[todoId]);
    });
  }

  @override
  Future<List<Todo>> loadTodos() async {
    await _loadCache();
    final records = await _isar.todoRecords.where().findAll();
    return records.map((record) {
      record.listId = _listIdCache[record.todoId] ?? 'personal';
      return record.toTodo();
    }).toList(growable: false);
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    await _loadCache();
    _listIdCache[todo.id] = todo.listId;
    await _saveCache();
    final record = TodoRecord.fromTodo(todo);
    await _isar.writeTxn(() async {
      await _isar.todoRecords.putByIndex('todoId', record);
    });
  }

  @override
  Future<void> replaceAll(Iterable<Todo> todos) async {
    await _loadCache();
    final list = todos.toList(growable: false);
    _listIdCache = {for (final t in list) t.id: t.listId};
    await _saveCache();
    final records = list.map(TodoRecord.fromTodo).toList(growable: false);
    await _isar.writeTxn(() async {
      await _isar.todoRecords.clear();
      await _isar.todoRecords.putAllByIndex('todoId', records);
    });
  }
}
