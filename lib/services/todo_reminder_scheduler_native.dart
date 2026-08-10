import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/todo.dart';
import 'todo_reminder_scheduler.dart';

const _channelId = 'trig.todo.reminders';
const _channelName = 'Trig Todo reminders';
const _channelDescription = 'Task and daily-agenda reminders from Trig.';
const _windowsGuid = 'd6eb1a4d-0141-4738-b875-b9d06b4d6a11';
const _dailyAgendaNotificationId = 702146;

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
    await _plugin.cancel(id: _notificationId(todoId, 2));
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> syncTodo(Todo todo) async {
    if (!_supportsScheduling) {
      return;
    }

    await cancelTodo(todo.id);

    if (todo.isCompleted) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final reminderMoment = tz.TZDateTime.from(todo.reminderTime, tz.local);
    if (!todo.isMuted && reminderMoment.isAfter(now)) {
      await _schedule(
        id: _notificationId(todo.id, 0),
        title: todo.presentationTitle,
        body: _primaryBody(todo),
        when: reminderMoment,
      );
    }

    final leadMinutes = todo.deadlineHeadsUpMinutes.clamp(0, 525600).toInt();
    if (leadMinutes == 0) return;

    final deadlineHeadsUp = tz.TZDateTime.from(
      todo.deadline.subtract(Duration(minutes: leadMinutes)),
      tz.local,
    );
    final isDuplicate =
        deadlineHeadsUp.millisecondsSinceEpoch ==
        reminderMoment.millisecondsSinceEpoch;
    if (deadlineHeadsUp.isAfter(now) && !isDuplicate) {
      await _schedule(
        id: _notificationId(todo.id, 1),
        title: 'Deadline soon: ${todo.presentationTitle}',
        body: _deadlineBody(todo),
        when: deadlineHeadsUp,
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

  @override
  Future<void> syncDailyAgenda({required bool enabled}) async {
    if (!_supportsScheduling) return;

    await _plugin.cancel(id: _dailyAgendaNotificationId);
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    await _schedule(
      id: _dailyAgendaNotificationId,
      title: 'Today in Trig',
      body: 'Open Trig to review today’s tasks.',
      when: next,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _configureLocalTimezone() async {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
  }

  String _deadlineBody(Todo todo) {
    final deadlineMoment = tz.TZDateTime.from(todo.deadline, tz.local);
    final date =
        '${deadlineMoment.year}-${deadlineMoment.month.toString().padLeft(2, '0')}-${deadlineMoment.day.toString().padLeft(2, '0')}';
    return 'Deadline: $date. ${_primaryBody(todo)}';
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
    DateTimeComponents? matchDateTimeComponents,
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
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }
}
