import 'todo_list_repository.dart';
import 'todo_list_repository_stub.dart'
    if (dart.library.html) 'todo_list_repository_web.dart'
    if (dart.library.io) 'todo_list_repository_native.dart';

Future<TodoListRepository> createTodoListRepository() =>
    createPlatformTodoListRepository();
