import 'package:isar/isar.dart';

import 'todo.dart';

part 'todo_record.g.dart';

@collection
class TodoRecord {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String todoId;

  late String title;
  late String content;
  late DateTime reminderTime;
  late DateTime deadline;
  late int remindDaysBeforeDDL;
  late String notes;
  late bool isMuted;
  late bool isCompleted;
  late bool isStarred;
  late int sortOrder;

  Todo toTodo() {
    return Todo(
      id: todoId,
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

  static TodoRecord fromTodo(Todo todo) {
    return TodoRecord()
      ..todoId = todo.id
      ..title = todo.title
      ..content = todo.content
      ..reminderTime = todo.reminderTime
      ..deadline = todo.deadline
      ..remindDaysBeforeDDL = todo.remindDaysBeforeDDL
      ..notes = todo.notes
      ..isMuted = todo.isMuted
      ..isCompleted = todo.isCompleted
      ..isStarred = todo.isStarred
      ..sortOrder = todo.sortOrder;
  }
}
