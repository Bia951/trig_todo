import 'todo_reminder_scheduler.dart';
import 'todo_reminder_scheduler_native.dart';

Future<TodoReminderScheduler> createTodoReminderScheduler() =>
    createPlatformTodoReminderScheduler();
