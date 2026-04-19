import 'package:flutter_test/flutter_test.dart';
import 'package:trig_todo/models/todo.dart';
import 'package:trig_todo/providers/todo_provider.dart';

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

  test('filteredTodos matches title, content and notes', () {
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
  });
}
