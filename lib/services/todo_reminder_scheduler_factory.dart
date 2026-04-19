import 'todo_reminder_scheduler.dart';
import 'todo_reminder_scheduler_stub.dart'
    if (dart.library.html) 'todo_reminder_scheduler_web.dart'
    if (dart.library.io) 'todo_reminder_scheduler_native.dart';

Future<TodoReminderScheduler> createTodoReminderScheduler() =>
    createPlatformTodoReminderScheduler();
