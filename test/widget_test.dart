import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trig_todo/main.dart';
import 'package:trig_todo/models/todo.dart';
import 'package:trig_todo/models/todo_list.dart';
import 'package:trig_todo/providers/todo_provider.dart';
import 'package:trig_todo/widgets/todo_card_page.dart';

void main() {
  testWidgets('renders trig home and filters todos', (tester) async {
    final provider = TodoProvider(
      initialTodos: [
        Todo(
          id: 'todo-1',
          title: 'Design review',
          content: 'Validate popup motion',
          reminderTime: DateTime(2026, 4, 19, 10, 30),
          deadline: DateTime(2026, 4, 19, 15, 00),
          remindDaysBeforeDDL: 1,
          notes: 'Bring notes',
          isMuted: false,
          isCompleted: false,
          isStarred: true,
          sortOrder: 0,
          listId: TodoList.inboxId,
        ),
        Todo(
          id: 'todo-2',
          title: 'Buy groceries',
          content: 'Fruit and coffee',
          reminderTime: DateTime(2026, 4, 19, 18, 00),
          deadline: DateTime(2026, 4, 20, 20, 00),
          remindDaysBeforeDDL: 2,
          notes: 'Check discounts',
          isMuted: false,
          isCompleted: false,
          isStarred: false,
          sortOrder: 0,
          listId: TodoList.inboxId,
        ),
      ],
    );

    await tester.pumpWidget(TrigApp(todoProvider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Important'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Design review'), findsOneWidget);
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Search todo'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'coffee');
    await tester.pumpAndSettle();

    expect(find.text('Design review'), findsNothing);
    expect(find.text('Buy groceries'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'nothing matches');
    await tester.pumpAndSettle();

    expect(find.text('No todos match this search.'), findsOneWidget);
    expect(find.text('Important'), findsNothing);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Completed'), findsNothing);
  });

  testWidgets('Escape exits batch edit mode', (tester) async {
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final provider = TodoProvider(
      initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
    );

    await tester.pumpWidget(TrigApp(todoProvider: provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Finish edit'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('list-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('normal-actions')), findsOneWidget);
  });

  testWidgets('Escape closes an editing todo card', (tester) async {
    var didClose = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TodoCardPage(
          initialTodo: _todo(id: 'todo-1', title: 'Plan release'),
          startInEditMode: true,
          onClose: () => didClose = true,
        ),
      ),
    );
    await tester.tap(find.byType(TextField).first);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(didClose, isTrue);
  });
}

Todo _todo({required String id, required String title}) {
  return Todo(
    id: id,
    title: title,
    content: '',
    reminderTime: DateTime(2026, 4, 19, 10, 30),
    deadline: DateTime(2026, 4, 19, 15),
    remindDaysBeforeDDL: 1,
    notes: '',
    isMuted: false,
    isCompleted: false,
    isStarred: false,
    sortOrder: 0,
    listId: TodoList.inboxId,
  );
}
