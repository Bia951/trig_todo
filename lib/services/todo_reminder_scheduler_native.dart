import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/todo.dart';
import 'todo_reminder_scheduler.dart';

const _channelId = 'trig.todo.reminders';
const _channelName = 'Trig Todo reminders';
const _channelDescription = 'Task reminders and deadline alerts from Trig.';
const _windowsGuid = 'd6eb1a4d-0141-4738-b875-b9d06b4d6a11';

Future<TodoReminderScheduler> createPlatformTodoReminderScheduler() async {
  final scheduler = LocalNotificationTodoReminderScheduler();
  await scheduler.initialize();
  return scheduler;
}

class LocalNotificationTodoReminderScheduler implements TodoReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _androidAllowsExactAlarms = true;
  bool _supportsScheduling = true;

  Future<void> initialize() async {
    _supportsScheduling = !Platform.isLinux;

    if (!_supportsScheduling) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open Trig');
    const windows = WindowsInitializationSettings(
      appName: 'Trig',
      appUserModelId: 'com.bia951.trig',
      guid: _windowsGuid,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
        windows: windows,
      ),
    );

    await _requestPermissions();
  }

  @override
  Future<void> cancelTodo(String todoId) async {
    if (!_supportsScheduling) {
      return;
    }

    await _plugin.cancel(id: _notificationId(todoId, 0));
    await _plugin.cancel(id: _notificationId(todoId, 1));
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> syncTodo(Todo todo) async {
    if (!_supportsScheduling) {
      return;
    }

    await cancelTodo(todo.id);

    if (todo.isMuted || todo.isCompleted) {
      return;
    }

    final reminderMoment = tz.TZDateTime.from(todo.reminderTime, tz.local);
    final leadDays = todo.remindDaysBeforeDDL.clamp(0, 365).toInt();
    final deadlineMoment = tz.TZDateTime.from(
      todo.deadline.subtract(Duration(days: leadDays)),
      tz.local,
    );
    final now = tz.TZDateTime.now(tz.local);

    if (reminderMoment.isAfter(now)) {
      await _schedule(
        id: _notificationId(todo.id, 0),
        title: 'Reminder: ${todo.presentationTitle}',
        body: _primaryBody(todo),
        when: reminderMoment,
      );
    }

    final isDistinctDeadlineAlert =
        deadlineMoment.millisecondsSinceEpoch !=
        reminderMoment.millisecondsSinceEpoch;
    if (deadlineMoment.isAfter(now) && isDistinctDeadlineAlert) {
      await _schedule(
        id: _notificationId(todo.id, 1),
        title: 'Deadline alert: ${todo.presentationTitle}',
        body: _deadlineBody(todo, deadlineMoment),
        when: deadlineMoment,
      );
    }
  }

  @override
  Future<void> syncTodos(Iterable<Todo> todos) async {
    if (!_supportsScheduling) {
      return;
    }

    await _plugin.cancelAll();
    for (final todo in todos) {
      await syncTodo(todo);
    }
  }

  Future<void> _configureLocalTimezone() async {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
  }

  String _deadlineBody(Todo todo, tz.TZDateTime when) {
    final suffix = _primaryBody(todo);
    final formattedMoment = _formatMoment(when);
    return 'Due by $formattedMoment. $suffix';
  }

  String _formatMoment(tz.TZDateTime moment) {
    final month = moment.month.toString().padLeft(2, '0');
    final day = moment.day.toString().padLeft(2, '0');
    final hour = moment.hour.toString().padLeft(2, '0');
    final minute = moment.minute.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day $hour:$minute';
  }

  int _notificationId(String todoId, int slot) {
    var hash = 0x811C9DC5;
    for (final codeUnit in '$todoId#$slot'.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  String _primaryBody(Todo todo) {
    final trimmedContent = todo.content.trim();
    if (trimmedContent.isNotEmpty) {
      return trimmedContent;
    }

    final trimmedNotes = todo.notes.trim();
    if (trimmedNotes.isNotEmpty) {
      return trimmedNotes;
    }

    return 'Open Trig to review this task.';
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final exactAlarmResult = await android?.requestExactAlarmsPermission();
    _androidAllowsExactAlarms = exactAlarmResult ?? true;

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(
          duration: WindowsNotificationDuration.long,
          scenario: WindowsNotificationScenario.reminder,
        ),
      ),
      androidScheduleMode: _androidAllowsExactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
