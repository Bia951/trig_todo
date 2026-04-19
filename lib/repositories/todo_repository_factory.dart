import 'todo_repository.dart';
import 'todo_repository_stub.dart'
    if (dart.library.html) 'todo_repository_web.dart'
    if (dart.library.io) 'todo_repository_native.dart';

Future<TodoRepository> createTodoRepository() => createPlatformTodoRepository();
