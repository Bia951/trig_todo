import 'todo_reminder_scheduler.dart';

Future<TodoReminderScheduler> createPlatformTodoReminderScheduler() async {
  return NoopTodoReminderScheduler();
}
