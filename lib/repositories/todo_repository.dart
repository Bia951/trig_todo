import '../models/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> loadTodos();

  Future<void> saveTodo(Todo todo);

  Future<void> deleteTodo(String todoId);

  Future<void> clear();

  Future<void> close();

  Future<void> replaceAll(Iterable<Todo> todos) async {
    await clear();
    for (final todo in todos) {
      await saveTodo(todo);
    }
  }
}
