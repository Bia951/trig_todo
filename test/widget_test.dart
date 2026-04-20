import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trig_todo/main.dart';
import 'package:trig_todo/models/todo.dart';
import 'package:trig_todo/providers/todo_provider.dart';

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
}
