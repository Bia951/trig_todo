import '../models/todo_list.dart';

abstract class TodoListRepository {
  Future<({List<TodoList> lists, String? activeListId})> load();
  Future<void> saveList(TodoList list);
  Future<void> deleteList(String id);
  Future<void> saveActiveListId(String id);
  Future<void> close();

  Future<void> replaceAll(Iterable<TodoList> lists, String activeListId) async {
    for (final list in lists) {
      await saveList(list);
    }
    await saveActiveListId(activeListId);
  }
}
