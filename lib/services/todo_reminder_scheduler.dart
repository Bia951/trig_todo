import '../models/todo.dart';

abstract class TodoReminderScheduler {
  Future<void> syncTodos(Iterable<Todo> todos);

  Future<void> syncTodo(Todo todo);

  Future<void> cancelTodo(String todoId);

  Future<void> dispose();
}

class NoopTodoReminderScheduler implements TodoReminderScheduler {
  @override
  Future<void> cancelTodo(String todoId) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> syncTodo(Todo todo) async {}

  @override
  Future<void> syncTodos(Iterable<Todo> todos) async {}
}
