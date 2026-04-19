import '../models/todo.dart';
import 'todo_repository.dart';

class InMemoryTodoRepository extends TodoRepository {
  InMemoryTodoRepository({List<Todo>? initialTodos})
    : _todos = List<Todo>.from(initialTodos ?? const <Todo>[]);

  final List<Todo> _todos;

  @override
  Future<void> clear() async {
    _todos.clear();
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> deleteTodo(String todoId) async {
    _todos.removeWhere((todo) => todo.id == todoId);
  }

  @override
  Future<List<Todo>> loadTodos() async {
    return List<Todo>.from(_todos);
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) {
      _todos.add(todo);
      return;
    }

    _todos[index] = todo;
  }
}
