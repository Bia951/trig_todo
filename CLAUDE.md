# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
flutter run                          # run on connected device/simulator
flutter run -d chrome                # run as web app
flutter test                         # run all tests
flutter test test/todo_provider_test.dart  # run a single test file
flutter analyze                      # lint / static analysis
dart run build_runner build          # regenerate Isar schema (after changing TodoRecord)
dart run build_runner watch          # watch mode for code gen
flutter build macos                  # build for macOS (or ios/android/windows/linux/web)
```

## Architecture

**Trig** is a cross-platform Flutter todo app (iOS, Android, macOS, Windows, Linux, Web) using Material 3 with Provider for state.

### Startup flow

`main()` → `TodoProvider.bootstrap()` (async: opens Isar, loads JSON files, schedules notifications) → `TrigBootstrap` (wraps in `DynamicColorBuilder` for Android Material You) → `TrigApp` (injects `TodoProvider` via `ChangeNotifierProvider`) → `AppShell`.

### Layout

`AppShell` switches at 700 px: mobile uses a `Scaffold` with a drawer (`AppDrawer`); desktop uses a persistent `AppSidebar` in a `Row`. Both render `HomeScreen` as the main pane.

### State: `TodoProvider`

Single `ChangeNotifier` that owns all in-memory state (`_todos`, `_lists`, `_activeListId`). All mutations update in-memory first, call `notifyListeners()`, then fire async persistence with `unawaited()`. Never `await` persistence before notifying — the UI must never block on I/O.

Todos are partitioned into three **buckets** by `_bucketFor()`:
- **important** — `isStarred && !isCompleted`
- **pending** — `!isStarred && !isCompleted`
- **completed** — `isCompleted`

`HomeScreen` displays the three buckets as collapsible `TodoSectionPanel` sections. Bucket rank determines list sort order (`important` → 0, `pending` → 1, `completed` → 2), then `sortOrder` within the bucket.

### Repository layer

All three layers use conditional Dart imports to swap platform implementations:

```dart
// factory file pattern (e.g. todo_repository_factory.dart):
import 'todo_repository_stub.dart'
    if (dart.library.html) 'todo_repository_web.dart'
    if (dart.library.io)   'todo_repository_native.dart';
```

| Layer | Native (IO) | Web | Tests |
|---|---|---|---|
| Todos | `IsarTodoRepository` (Isar v3) | `WebTodoRepository` (localStorage, key `trig.todo.items.v2`) | `InMemoryTodoRepository` |
| Lists | `NativeTodoListRepository` (JSON file `trig_lists_v1.json`) | `WebTodoListRepository` (localStorage) | `InMemoryTodoListRepository` |
| Reminders | `LocalNotificationTodoReminderScheduler` | `NoopTodoReminderScheduler` | `NoopTodoReminderScheduler` |

#### Isar sidecar for `listId`

`TodoRecord` (Isar) predates the multi-list feature, so `listId` is **not** stored in the Isar database. It lives in a sidecar JSON file (`trig_todo_listmap_v1.json`) keyed by `todoId`. `IsarTodoRepository` loads/saves this cache on every operation. Don't add `listId` as an Isar field without a migration plan.

### Models

- `Todo` — pure immutable Dart class, JSON-serializable, `copyWith`. Never extends or mixes with Isar.
- `TodoList` — same pattern; carries `iconCodePoint` (Material icon codePoint) and `colorValue` (ARGB int).
- `TodoRecord` — Isar `@collection` mapped from `Todo`; has a `@Index(unique: true)` on `todoId`. `todo_record.g.dart` is generated — run `build_runner` after any schema changes.

### Notifications

`LocalNotificationTodoReminderScheduler` schedules up to 3 notifications per todo: `reminderTime` (slot 0), `deadline` (slot 1), and N-days-before-deadline (slot 2). Linux skips scheduling entirely. Notification IDs are derived from a FNV-1a hash of `"$todoId#$slot"`.

### Theme

`TrigTheme` uses Material 3. Dynamic color (Android Material You) is applied only on Android; all other platforms use an orange seed color (`Colors.orange`). The theme is built once in `TrigApp` and not accessed via inherited widget elsewhere — always use `Theme.of(context)` in widgets.

### Testing

`TodoProvider` is tested directly with no repository mocking — pass `initialTodos` and an `InMemoryTodoRepository` is used automatically. Widget tests use the same approach. There are no golden tests.
