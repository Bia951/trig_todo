import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../layout/app_layout_profile.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/desktop_todo_inspector.dart';
import '../widgets/page_title.dart';
import '../widgets/todo_editor.dart';
import '../widgets/todo_side_panel.dart';
import '../widgets/undo_snackbar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  String? _inspectedTodoId;
  TodoEditorSession? _editorSession;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _editorSession?.dispose();
    super.dispose();
  }

  void _shiftMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  void _selectToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  void _openTodo(Todo todo, {bool startInEditMode = false}) {
    if (startInEditMode) {
      _startEditor(todo);
      return;
    }
    setState(() => _inspectedTodoId = todo.id);
  }

  void _startEditor(Todo todo) {
    final previous = _editorSession;
    setState(
      () => _editorSession = TodoEditorSession(initialTodo: todo, isNew: false),
    );
    previous?.dispose();
  }

  void _closeEditor() {
    final session = _editorSession;
    if (session == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _editorSession = null);
    session.dispose();
  }

  void _saveEditor(Todo todo) {
    final session = _editorSession;
    context.read<TodoProvider>().saveTodo(todo);
    setState(() {
      _inspectedTodoId = todo.id;
      _editorSession = null;
    });
    session?.dispose();
  }

  void _deleteEditor() {
    final session = _editorSession;
    if (session == null) return;
    final provider = context.read<TodoProvider>();
    final removed = provider.removeTodo(session.draft.id);
    setState(() {
      _inspectedTodoId = null;
      _editorSession = null;
    });
    session.dispose();
    if (removed.isNotEmpty && mounted) {
      showUndoTodoSnackBar(
        ScaffoldMessenger.of(context),
        theme: Theme.of(context),
        message: 'Deleted "${removed.single.presentationTitle}"',
        onUndo: () => provider.restoreTodos(removed),
      );
    }
  }

  void _dismissSidePanel() {
    if (_editorSession != null) {
      _closeEditor();
    } else if (_inspectedTodoId != null) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _inspectedTodoId = null);
    }
  }

  Todo? _todoById(Iterable<Todo> todos) {
    for (final todo in todos) {
      if (todo.id == _inspectedTodoId) return todo;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TodoProvider>();
    final profile = AppLayoutProfile.of(context);
    final hasPersistentNavigation = profile.hasPersistentNavigation;
    final hasDockedDetailsPanel = profile.hasDockedDetailsPanel;
    final agendaTodos = provider.todosForDay(_selectedDay);
    final today = DateTime.now();
    final inspectedTodo = _todoById(provider.todos);

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            (_editorSession != null || _inspectedTodoId != null)) {
          _dismissSidePanel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: hasPersistentNavigation ? 32 : null,
              leadingWidth: hasPersistentNavigation ? 0 : 64,
              leading: hasPersistentNavigation
                  ? null
                  : Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: SizedBox.square(
                          dimension: 44,
                          child: IconButton.filledTonal(
                            tooltip: 'Open lists',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            style: IconButton.styleFrom(
                              minimumSize: const Size.square(44),
                              maximumSize: const Size.square(44),
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.menu_rounded),
                          ),
                        ),
                      ),
                    ),
              title: Align(
                alignment: Alignment.centerLeft,
                child: PageTitle(
                  icon: Icons.calendar_month_rounded,
                  color: theme.colorScheme.tertiary,
                  label: 'Schedule',
                ),
              ),
              actions: [
                TextButton(onPressed: _selectToday, child: const Text('Today')),
                const SizedBox(width: 8),
              ],
            ),
            body: Row(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _CalendarMonth(
                        visibleMonth: _visibleMonth,
                        selectedDay: _selectedDay,
                        today: today,
                        todosForDay: provider.todosForDay,
                        onPreviousMonth: () => _shiftMonth(-1),
                        onNextMonth: () => _shiftMonth(1),
                        onSelectDay: (day) =>
                            setState(() => _selectedDay = day),
                      ),
                      const SizedBox(height: 20),
                      _DailyAgendaReminderCard(
                        enabled: provider.dailyAgendaReminderEnabled,
                        onChanged: provider.setDailyAgendaReminderEnabled,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _agendaHeading(_selectedDay, today),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (agendaTodos.isEmpty)
                        const _AgendaEmptyState()
                      else
                        ...agendaTodos.map(
                          (todo) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AgendaTodoCard(
                              todo: todo,
                              selectedDay: _selectedDay,
                              onTap: () => _openTodo(todo),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasDockedDetailsPanel) ...[
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  SizedBox(
                    width: 340,
                    child: TodoSidePanelSurface(
                      onDismiss: _dismissSidePanel,
                      child: _editorSession == null
                          ? DesktopTodoInspector(
                              key: const ValueKey('schedule-inspector-docked'),
                              todo: inspectedTodo,
                              onDismiss: _dismissSidePanel,
                              onEdit: inspectedTodo == null
                                  ? () {}
                                  : () => _openTodo(
                                      inspectedTodo,
                                      startInEditMode: true,
                                    ),
                              onToggleCompleted: inspectedTodo == null
                                  ? () {}
                                  : () => provider.toggleCompleted(
                                      inspectedTodo.id,
                                    ),
                              onToggleStarred: inspectedTodo == null
                                  ? () {}
                                  : () => provider.toggleStarred(
                                      inspectedTodo.id,
                                    ),
                              onToggleMute: inspectedTodo == null
                                  ? () {}
                                  : () => provider.toggleMute(inspectedTodo.id),
                            )
                          : TodoEditorPane(
                              key: const ValueKey('schedule-editor-docked'),
                              session: _editorSession!,
                              onClose: _closeEditor,
                              onSave: _saveEditor,
                              onDelete: _deleteEditor,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!hasDockedDetailsPanel &&
              (_editorSession != null || inspectedTodo != null))
            TodoSidePanelOverlay(
              onDismiss: _dismissSidePanel,
              child: _editorSession != null
                  ? TodoEditorPane(
                      key: const ValueKey('schedule-editor-overlay'),
                      session: _editorSession!,
                      onClose: _closeEditor,
                      onSave: _saveEditor,
                      onDelete: _deleteEditor,
                      isOverlay: true,
                    )
                  : DesktopTodoInspector(
                      key: const ValueKey('schedule-inspector-overlay'),
                      todo: inspectedTodo,
                      onDismiss: _dismissSidePanel,
                      onEdit: () =>
                          _openTodo(inspectedTodo!, startInEditMode: true),
                      onToggleCompleted: () =>
                          provider.toggleCompleted(inspectedTodo!.id),
                      onToggleStarred: () =>
                          provider.toggleStarred(inspectedTodo!.id),
                      onToggleMute: () =>
                          provider.toggleMute(inspectedTodo!.id),
                    ),
            ),
        ],
      ),
    );
  }

  String _agendaHeading(DateTime day, DateTime today) {
    if (_isSameDay(day, today)) return 'Today’s agenda';
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatMediumDate(day);
  }
}

class _CalendarMonth extends StatelessWidget {
  const _CalendarMonth({
    required this.visibleMonth,
    required this.selectedDay,
    required this.today,
    required this.todosForDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDay,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final DateTime today;
  final List<Todo> Function(DateTime day) todosForDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final startOffset = firstDay.weekday - DateTime.monday;
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final monthLabel = MaterialLocalizations.of(
      context,
    ).formatMonthYear(visibleMonth);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const _WeekdayLabels(),
          const SizedBox(height: 4),
          ...List<Widget>.generate(6, (weekIndex) {
            return SizedBox(
              height: 54,
              child: Row(
                children: List<Widget>.generate(7, (weekdayIndex) {
                  final index = weekIndex * 7 + weekdayIndex;
                  final dayNumber = index - startOffset + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }
                  final day = DateTime(
                    visibleMonth.year,
                    visibleMonth.month,
                    dayNumber,
                  );
                  return Expanded(
                    child: _CalendarDay(
                      day: day,
                      isToday: _isSameDay(day, today),
                      isSelected: _isSameDay(day, selectedDay),
                      todoCount: todosForDay(day).length,
                      onTap: () => onSelectDay(day),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
          .map(
            (label) => Expanded(
              child: Center(child: _WeekdayLabel(label: label)),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.todoCount,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final int todoCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : isToday
              ? theme.colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: todoCount == 0 ? 0 : 6,
              height: todoCount == 0 ? 0 : 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaEmptyState extends StatelessWidget {
  const _AgendaEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No scheduled tasks for this day.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DailyAgendaReminderCard extends StatelessWidget {
  const _DailyAgendaReminderCard({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        secondary: Icon(
          enabled ? Icons.wb_sunny_rounded : Icons.wb_sunny_outlined,
          color: theme.colorScheme.tertiary,
        ),
        title: const Text('Daily Today reminder'),
        subtitle: const Text('A gentle prompt at 9:00 every morning.'),
      ),
    );
  }
}

class _AgendaTodoCard extends StatelessWidget {
  const _AgendaTodoCard({
    required this.todo,
    required this.selectedDay,
    required this.onTap,
  });

  final Todo todo;
  final DateTime selectedDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReminder = _isSameDay(todo.reminderTime, selectedDay);
    final isDeadline = _isSameDay(todo.deadline, selectedDay);
    final time = isReminder ? todo.reminderTime : todo.deadline;
    final label = isReminder && isDeadline
        ? 'Reminder · deadline'
        : isReminder
        ? 'Reminder'
        : 'Deadline';
    final timeText = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.presentationTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
