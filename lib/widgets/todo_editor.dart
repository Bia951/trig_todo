import 'package:flutter/material.dart';

import '../models/todo.dart';

/// Owns an edit draft independently of the widget that presents it.
///
/// The same session can move between an overlay and a fixed side pane when the
/// window changes size without losing typed text or pending date changes.
class TodoEditorSession extends ChangeNotifier {
  TodoEditorSession({required Todo initialTodo, required this.isNew})
    : _draft = initialTodo,
      titleController = TextEditingController(text: initialTodo.title),
      contentController = TextEditingController(text: initialTodo.content),
      notesController = TextEditingController(text: initialTodo.notes);

  final bool isNew;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final TextEditingController notesController;
  Todo _draft;

  Todo get draft => _draft;

  String get displayTitle {
    final title = titleController.text.trim();
    return title.isEmpty ? 'Todo' : title;
  }

  void updateDraft(Todo draft) {
    _draft = draft;
    notifyListeners();
  }

  void refresh() => notifyListeners();

  Todo buildTodo() {
    return _draft.copyWith(
      title: titleController.text.trim(),
      content: contentController.text.trim(),
      notes: notesController.text.trim(),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    notesController.dispose();
    super.dispose();
  }
}

class TodoEditorPane extends StatelessWidget {
  const TodoEditorPane({
    required this.session,
    required this.onClose,
    required this.onSave,
    required this.onDelete,
    this.isOverlay = false,
    super.key,
  });

  final TodoEditorSession session;
  final VoidCallback onClose;
  final ValueChanged<Todo> onSave;
  final VoidCallback onDelete;
  final bool isOverlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: TodoEditorForm(
          session: session,
          onClose: onClose,
          onSave: onSave,
          onDelete: onDelete,
          isOverlay: isOverlay,
        ),
      ),
    );
  }
}

class TodoEditorForm extends StatefulWidget {
  const TodoEditorForm({
    required this.session,
    required this.onClose,
    required this.onSave,
    required this.onDelete,
    this.isOverlay = false,
    super.key,
  });

  final TodoEditorSession session;
  final VoidCallback onClose;
  final ValueChanged<Todo> onSave;
  final VoidCallback onDelete;
  final bool isOverlay;

  @override
  State<TodoEditorForm> createState() => _TodoEditorFormState();
}

class _TodoEditorFormState extends State<TodoEditorForm> {
  TodoEditorSession get _session => widget.session;

  Future<void> _pickDateTime({
    required DateTime current,
    required Todo Function(DateTime) updater,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted || time == null) return;

    _session.updateDraft(
      updater(
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      ),
    );
  }

  Future<void> _pickDeadlineHeadsUp() async {
    final initialMinutes = _session.draft.deadlineHeadsUpMinutes;
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        var enabled = initialMinutes > 0;
        var days = (initialMinutes ~/ Duration.minutesPerDay)
            .clamp(0, 30)
            .toInt();
        var hours = ((initialMinutes % Duration.minutesPerDay) ~/ 60)
            .clamp(0, 23)
            .toInt();
        if (enabled && days == 0 && hours == 0) hours = 1;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Deadline heads-up'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: enabled,
                  title: const Text('Remind before deadline'),
                  onChanged: (value) {
                    setDialogState(() {
                      enabled = value;
                      if (enabled && days == 0 && hours == 0) hours = 1;
                    });
                  },
                ),
                if (enabled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: days,
                          decoration: const InputDecoration(labelText: 'Days'),
                          items: List<DropdownMenuItem<int>>.generate(
                            31,
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          ),
                          onChanged: (value) => setDialogState(() {
                            days = value ?? 0;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: hours,
                          decoration: const InputDecoration(labelText: 'Hours'),
                          items: List<DropdownMenuItem<int>>.generate(
                            24,
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          ),
                          onChanged: (value) => setDialogState(() {
                            hours = value ?? 0;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final minutes = enabled
                      ? days * Duration.minutesPerDay + hours * 60
                      : 0;
                  Navigator.of(
                    context,
                  ).pop(minutes == 0 && enabled ? 60 : minutes);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || result == null) return;
    _session.updateDraft(
      _session.draft.copyWith(deadlineHeadsUpMinutes: result),
    );
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(value)}, ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
  }

  String _deadlineHeadsUpLabel(int minutes) {
    if (minutes <= 0) return 'Off';
    final days = minutes ~/ Duration.minutesPerDay;
    final hours = (minutes % Duration.minutesPerDay) ~/ 60;
    final parts = <String>[
      if (days > 0) '$days day${days == 1 ? '' : 's'}',
      if (hours > 0) '$hours hour${hours == 1 ? '' : 's'}',
    ];
    return '${parts.join(' ')} before the deadline';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        final draft = _session.draft;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.isOverlay ? 20 : 24,
                16,
                widget.isOverlay ? 12 : 16,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _session.isNew ? 'New todo' : 'Edit todo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close editor',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  widget.isOverlay ? 20 : 24,
                  20,
                  widget.isOverlay ? 20 : 24,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('todo-editor-title'),
                      controller: _session.titleController,
                      onChanged: (_) => _session.refresh(),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Untitled todo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('todo-editor-content'),
                      controller: _session.contentController,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Content'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('todo-editor-notes'),
                      controller: _session.notesController,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 16),
                    _EditorReminderTile(
                      enabled: !draft.isMuted,
                      onChanged: (enabled) => _session.updateDraft(
                        draft.copyWith(isMuted: !enabled),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EditorMetaTile(
                      icon: Icons.schedule,
                      label: 'Reminder time',
                      value: _formatDateTime(context, draft.reminderTime),
                      onPressed: () => _pickDateTime(
                        current: draft.reminderTime,
                        updater: (value) => draft.copyWith(reminderTime: value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EditorMetaTile(
                      icon: Icons.event,
                      label: 'Deadline',
                      value: _formatDateTime(context, draft.deadline),
                      onPressed: () => _pickDateTime(
                        current: draft.deadline,
                        updater: (value) => draft.copyWith(deadline: value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EditorMetaTile(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'Deadline heads-up',
                      value: _deadlineHeadsUpLabel(
                        draft.deadlineHeadsUpMinutes,
                      ),
                      onPressed: _pickDeadlineHeadsUp,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cancel = TextButton.icon(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Cancel'),
                  );
                  final delete = TextButton.icon(
                    onPressed: widget.onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                  );
                  final save = FilledButton.icon(
                    onPressed: () => widget.onSave(_session.buildTodo()),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save'),
                  );

                  if (!_session.isNew && constraints.maxWidth < 430) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [cancel, const Spacer(), delete]),
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerRight, child: save),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      cancel,
                      const Spacer(),
                      if (!_session.isNew) ...[
                        delete,
                        const SizedBox(width: 8),
                      ],
                      save,
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EditorMetaTile extends StatelessWidget {
  const _EditorMetaTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        hoverColor: Colors.white.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.32,
        ),
        highlightColor: Colors.white.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorReminderTile extends StatelessWidget {
  const _EditorReminderTile({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onChanged(!enabled),
        borderRadius: BorderRadius.circular(20),
        hoverColor: Colors.white.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.32,
        ),
        highlightColor: Colors.white.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Icon(
                enabled
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_outlined,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task reminder',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled
                          ? 'Send one notification at the selected time.'
                          : 'No notification will be sent for this task.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
