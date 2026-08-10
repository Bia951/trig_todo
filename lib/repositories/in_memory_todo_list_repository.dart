import '../models/todo_list.dart';
import 'todo_list_repository.dart';

class InMemoryTodoListRepository extends TodoListRepository {
  final List<TodoList> _lists = [];
  String? _activeListId;
  bool _dailyAgendaReminderEnabled = false;

  @override
  Future<({List<TodoList> lists, String? activeListId})> load() async {
    return (lists: List<TodoList>.from(_lists), activeListId: _activeListId);
  }

  @override
  Future<void> saveList(TodoList list) async {
    final index = _lists.indexWhere((l) => l.id == list.id);
    if (index == -1) {
      _lists.add(list);
    } else {
      _lists[index] = list;
    }
  }

  @override
  Future<void> deleteList(String id) async {
    _lists.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> saveActiveListId(String id) async {
    _activeListId = id;
  }

  @override
  Future<bool> loadDailyAgendaReminderEnabled() async =>
      _dailyAgendaReminderEnabled;

  @override
  Future<void> saveDailyAgendaReminderEnabled(bool enabled) async {
    _dailyAgendaReminderEnabled = enabled;
  }

  @override
  Future<void> close() async {}
}
