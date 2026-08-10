import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trig_todo/models/todo.dart';
import 'package:trig_todo/models/todo_list.dart';
import 'package:trig_todo/providers/todo_provider.dart';
import 'package:trig_todo/repositories/in_memory_todo_list_repository.dart';
import 'package:trig_todo/repositories/in_memory_todo_repository.dart';

void main() {
  Todo buildTodo({required String id, required String title}) {
    return Todo(
      id: id,
      title: title,
      content: '$title content',
      reminderTime: DateTime(2026, 4, 19, 9, 0),
      deadline: DateTime(2026, 4, 19, 18, 0),
      remindDaysBeforeDDL: 1,
      notes: '$title notes',
      isMuted: false,
      isCompleted: false,
      isStarred: false,
      sortOrder: int.parse(id),
      listId: TodoList.inboxId,
    );
  }

  test('saveTodo adds and updates records', () {
    final provider = TodoProvider(initialTodos: []);
    final todo = buildTodo(id: '1', title: 'First');

    provider.saveTodo(todo);
    expect(provider.todos, hasLength(1));

    provider.saveTodo(todo.copyWith(title: 'Updated first'));
    expect(provider.todos.single.title, 'Updated first');
  });

  test('defaults to one inbox list', () {
    final provider = TodoProvider(initialTodos: []);

    expect(provider.lists, hasLength(1));
    expect(provider.lists.single.id, TodoList.inboxId);
    expect(provider.lists.single.name, 'Inbox');
  });

  test('hydrates orphaned todos into Inbox', () async {
    final repository = InMemoryTodoRepository(
      initialTodos: [
        buildTodo(id: '1', title: 'Legacy').copyWith(listId: 'personal'),
      ],
    );
    final provider = TodoProvider(
      initialTodos: const <Todo>[],
      repository: repository,
      listRepository: InMemoryTodoListRepository(),
    );

    await provider.hydrate();

    expect(provider.todos.single.listId, TodoList.inboxId);
    expect((await repository.loadTodos()).single.listId, TodoList.inboxId);
  });

  test('deleting a list moves its todos to Inbox', () {
    final inbox = TodoList(
      id: TodoList.inboxId,
      name: 'Inbox',
      iconCodePoint: Icons.inbox_rounded.codePoint,
      colorValue: 0xFF1D7860,
    );
    final work = TodoList(
      id: 'work',
      name: 'Work',
      iconCodePoint: Icons.work_rounded.codePoint,
      colorValue: 0xFF8F4E00,
    );
    final provider = TodoProvider(
      initialLists: [inbox, work],
      initialActiveListId: 'work',
      initialTodos: [
        buildTodo(id: '1', title: 'Move me').copyWith(listId: 'work'),
      ],
    );

    provider.deleteTodoList('work');

    expect(provider.lists, [inbox]);
    expect(provider.activeListId, TodoList.inboxId);
    expect(provider.todos.single.listId, TodoList.inboxId);

    provider.deleteTodoList(TodoList.inboxId);
    expect(provider.lists, [inbox]);
  });

  test('Today shows incomplete todos with a reminder or deadline today', () {
    final clock = DateTime.now();
    final now = DateTime(clock.year, clock.month, clock.day, 10);
    final provider = TodoProvider(
      initialTodos: [
        buildTodo(id: '1', title: 'Reminder today').copyWith(
          reminderTime: now.add(const Duration(hours: 1)),
          deadline: now.add(const Duration(days: 2)),
        ),
        buildTodo(id: '2', title: 'Deadline today').copyWith(
          reminderTime: now.add(const Duration(days: 2)),
          deadline: now.add(const Duration(hours: 2)),
        ),
        buildTodo(id: '3', title: 'Completed today').copyWith(
          reminderTime: now.add(const Duration(hours: 1)),
          isCompleted: true,
        ),
        buildTodo(id: '4', title: 'Later').copyWith(
          reminderTime: now.add(const Duration(days: 2)),
          deadline: now.add(const Duration(days: 3)),
        ),
      ],
    );

    provider.showToday();

    expect(provider.showingToday, isTrue);
    expect(provider.todayTodos.map((todo) => todo.id), ['1', '2']);
    expect(provider.todayTodoCount, 2);

    provider.setActiveList(TodoList.inboxId);
    expect(provider.showingToday, isFalse);
  });

  test('Schedule groups incomplete todos by reminder or deadline day', () {
    final day = DateTime(2026, 8, 3);
    final provider = TodoProvider(
      initialTodos: [
        buildTodo(id: '1', title: 'Reminder').copyWith(
          reminderTime: day.add(const Duration(hours: 9)),
          deadline: day.add(const Duration(days: 2)),
        ),
        buildTodo(id: '2', title: 'Deadline').copyWith(
          reminderTime: day.add(const Duration(days: 2)),
          deadline: day.add(const Duration(hours: 17)),
        ),
        buildTodo(id: '3', title: 'Done').copyWith(
          reminderTime: day.add(const Duration(hours: 10)),
          isCompleted: true,
        ),
      ],
    );

    provider.showSchedule();

    expect(provider.showingSchedule, isTrue);
    expect(provider.todosForDay(day).map((todo) => todo.id), ['1', '2']);
  });

  test('createDraft defaults reminder to one hour and deadline to one day', () {
    final provider = TodoProvider(initialTodos: []);
    final reference = DateTime(2026, 4, 19, 9, 30);

    final draft = provider.createDraft(reference: reference);

    expect(draft.reminderTime, reference.add(const Duration(hours: 1)));
    expect(draft.deadline, reference.add(const Duration(days: 1)));
    expect(draft.isMuted, isTrue);
    expect(draft.remindDaysBeforeDDL, 0);
  });

  test(
    'deadline heads-up supports hours without changing legacy day values',
    () {
      final legacy = buildTodo(id: '1', title: 'Legacy');
      final hourly = legacy.copyWith(deadlineHeadsUpMinutes: 27 * 60);

      expect(legacy.deadlineHeadsUpMinutes, Duration.minutesPerDay);
      expect(hourly.deadlineHeadsUpMinutes, 27 * 60);
    },
  );

  test('toggleMute and removeTodo mutate existing items', () {
    final provider = TodoProvider(
      initialTodos: [buildTodo(id: '1', title: 'First')],
    );

    provider.toggleMute('1');
    expect(provider.todos.single.isMuted, isTrue);

    provider.removeTodo('1');
    expect(provider.todos, isEmpty);
  });

  test('toggleCompleted and toggleStarred move todos between sections', () {
    final provider = TodoProvider(
      initialTodos: [buildTodo(id: '1', title: 'First')],
    );

    provider.toggleStarred('1');
    expect(provider.importantTodos.single.id, '1');
    expect(provider.pendingTodos, isEmpty);

    provider.toggleCompleted('1');
    expect(provider.completedTodos.single.id, '1');
    expect(provider.importantTodos, isEmpty);
  });

  test('completeTodos marks only selected incomplete todos completed', () {
    final provider = TodoProvider(
      initialTodos: [
        buildTodo(id: '1', title: 'One'),
        buildTodo(id: '2', title: 'Two').copyWith(isCompleted: true),
        buildTodo(id: '3', title: 'Three'),
      ],
    );

    provider.completeTodos(['1', '2']);

    expect(
      provider.completedTodos.map((todo) => todo.id),
      containsAll(['1', '2']),
    );
    expect(provider.pendingTodos.map((todo) => todo.id), ['3']);
  });

  test('removeTodos deletes all matching ids', () {
    final provider = TodoProvider(
      initialTodos: [
        buildTodo(id: '1', title: 'One'),
        buildTodo(id: '2', title: 'Two'),
        buildTodo(id: '3', title: 'Three'),
      ],
    );

    provider.removeTodos(['1', '3', 'missing']);

    expect(provider.todos.map((todo) => todo.id), ['2']);
  });

  test('reorderTodos updates manual sort order within a bucket', () {
    final provider = TodoProvider(
      initialTodos: [
        buildTodo(id: '1', title: 'One'),
        buildTodo(id: '2', title: 'Two'),
      ],
    );

    provider.reorderTodos(bucket: TodoBucket.pending, oldIndex: 0, newIndex: 2);

    expect(provider.pendingTodos.map((todo) => todo.id), ['2', '1']);
  });

  test(
    'filteredTodos matches title, content, notes, reminder and deadline',
    () {
      final provider = TodoProvider(
        initialTodos: [
          buildTodo(id: '1', title: 'Alpha'),
          buildTodo(id: '2', title: 'Beta'),
        ],
      );

      provider.setSearchQuery('beta content');
      expect(provider.filteredTodos.single.title, 'Beta');

      provider.setSearchQuery('alpha notes');
      expect(provider.filteredTodos.single.title, 'Alpha');

      provider.setSearchQuery('2026-04-19 09:00');
      expect(provider.filteredTodos, hasLength(2));

      provider.setSearchQuery('2026-04-19 18:00');
      expect(provider.filteredTodos, hasLength(2));
    },
  );
}
