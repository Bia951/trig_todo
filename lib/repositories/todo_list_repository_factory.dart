import 'todo_list_repository.dart';
import 'todo_list_repository_native.dart';

Future<TodoListRepository> createTodoListRepository() =>
    createPlatformTodoListRepository();
