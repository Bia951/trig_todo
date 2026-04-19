import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/todo.dart';
import '../models/todo_record.dart';
import 'todo_repository.dart';

const _isarInstanceName = 'trig_todo_v2';

Future<TodoRepository> createPlatformTodoRepository() async {
  final existing = Isar.getInstance(_isarInstanceName);
  if (existing != null) {
    return IsarTodoRepository(existing);
  }

  final directory = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    <CollectionSchema<dynamic>>[TodoRecordSchema],
    directory: directory.path,
    name: _isarInstanceName,
  );
  return IsarTodoRepository(isar);
}

class IsarTodoRepository extends TodoRepository {
  IsarTodoRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> clear() async {
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
    await _isar.writeTxn(() async {
      await _isar.todoRecords.deleteByIndex('todoId', <Object?>[todoId]);
    });
  }

  @override
  Future<List<Todo>> loadTodos() async {
    final records = await _isar.todoRecords.where().findAll();
    return records.map((record) => record.toTodo()).toList(growable: false);
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    final record = TodoRecord.fromTodo(todo);
    await _isar.writeTxn(() async {
      await _isar.todoRecords.putByIndex('todoId', record);
    });
  }
}
