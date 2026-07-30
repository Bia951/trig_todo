import 'todo_repository.dart';
import 'todo_repository_native.dart';

Future<TodoRepository> createTodoRepository() => createPlatformTodoRepository();
