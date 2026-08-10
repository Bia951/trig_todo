import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trig_todo/main.dart';
import 'package:trig_todo/models/todo.dart';
import 'package:trig_todo/models/todo_list.dart';
import 'package:trig_todo/providers/todo_provider.dart';

void main() {
  testWidgets(
    'renders trig home and filters todos',
    (tester) async {
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
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Escape exits batch edit mode',
    (tester) async {
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
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'wide desktop keeps todo details in the inspector',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = TodoProvider(
        initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
      );

      await tester.pumpWidget(TrigApp(todoProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Select a todo'), findsOneWidget);

      await tester.tap(find.text('Plan release').first);
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(find.byTooltip('Close details'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Select a todo'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'desktop editor keeps its draft while it docks',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 760);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final provider = TodoProvider(
        initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
      );
      await tester.pumpWidget(TrigApp(todoProvider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add todo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('todo-editor-overlay')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('todo-editor-title')),
        'Keep this draft',
      );
      tester.view.physicalSize = const Size(1100, 760);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('todo-editor-docked')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('todo-editor-title')))
            .controller!
            .text,
        'Keep this draft',
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'compact desktop presents todo details and editing in the side pane',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 760);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final provider = TodoProvider(
        initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
      );
      await tester.pumpWidget(TrigApp(todoProvider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plan release').first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('todo-inspector-overlay')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('todo-inspector-edit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('todo-editor-overlay')), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'desktop shortcuts recover after closing the editor',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = TodoProvider(
        initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
      );
      await tester.pumpWidget(TrigApp(todoProvider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plan release').first);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('todo-editor-docked')), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('todo-editor-docked')), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();
      expect(find.text('New todo'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'tablet keeps touch controls with a persistent navigation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      await tester.binding.setSurfaceSize(const Size(900, 760));
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = TodoProvider(
        initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
      );
      await tester.pumpWidget(TrigApp(todoProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Search todo'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Select a todo'), findsNothing);

      await tester.tap(find.byTooltip('Add todo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('todo-editor-overlay')), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'star and completion actions stay adjacent in a todo row',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      await tester.binding.setSurfaceSize(const Size(900, 760));
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = TodoProvider(
        initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
      );
      await tester.pumpWidget(TrigApp(todoProvider: provider));
      await tester.pumpAndSettle();

      final star = find.byTooltip('Star todo');
      final complete = find.byTooltip('Complete todo');
      expect(star, findsOneWidget);
      expect(complete, findsOneWidget);
      expect(
        (tester.getCenter(complete).dx - tester.getCenter(star).dx).abs(),
        lessThan(40),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'mobile keeps todo creation in the floating action button',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 760);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final provider = TodoProvider(
        initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
      );

      await tester.pumpWidget(TrigApp(todoProvider: provider));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('Add todo'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'the narrow side pane closes with Escape, outside tap, and its edge swipe',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 760);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final provider = TodoProvider(
        initialTodos: [_todo(id: 'todo-1', title: 'Plan release')],
      );
      await tester.pumpWidget(TrigApp(todoProvider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Plan release').first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('todo-inspector-overlay')),
        findsOneWidget,
      );

      final panel = find.byKey(const ValueKey('todo-inspector-overlay'));
      final panelLeftBeforeDrag = tester.getTopLeft(panel).dx;
      final reboundGesture = await tester.startGesture(
        Offset(panelLeftBeforeDrag + 8, 400),
      );
      await reboundGesture.moveBy(const Offset(36, 0));
      await tester.pump();
      expect(tester.getTopLeft(panel).dx, greaterThan(panelLeftBeforeDrag));
      await reboundGesture.up();
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('todo-inspector-overlay')),
        findsNothing,
      );

      await tester.tap(find.text('Plan release').first);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(360, 680));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('todo-inspector-overlay')),
        findsNothing,
      );

      await tester.tap(find.text('Plan release').first);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(545, 400));
      await gesture.moveBy(const Offset(80, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('todo-inspector-overlay')),
        findsNothing,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
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
