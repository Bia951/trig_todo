import 'in_memory_todo_repository.dart';
import 'todo_repository.dart';

Future<TodoRepository> createPlatformTodoRepository() async {
  return InMemoryTodoRepository();
}
