import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../providers/todo_provider.dart';

class TodoCardPage extends StatefulWidget {
  const TodoCardPage({
    required this.initialTodo,
    this.onClose,
    this.startInEditMode = false,
    this.closeOnSave = false,
    this.heroTag,
    super.key,
  });

  final Todo initialTodo;
  final VoidCallback? onClose;
  final bool startInEditMode;
  final bool closeOnSave;
  final Object? heroTag;

  @override
  State<TodoCardPage> createState() => _TodoCardPageState();
}

class _TodoCardPageState extends State<TodoCardPage> {
  late Todo _draft;
  late bool _isEditing;
  late bool _isNew;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialTodo;
    _isEditing = widget.startInEditMode;
    _isNew = widget.startInEditMode;
    _titleController = TextEditingController(text: _draft.title);
    _contentController = TextEditingController(text: _draft.content);
    _notesController = TextEditingController(text: _draft.notes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _draft.reminderTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft.reminderTime),
    );
    if (!mounted || time == null) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        reminderTime: DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    });
  }

  Future<void> _pickDeadlineDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _draft.deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft.deadline),
    );
    if (!mounted || time == null) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        deadline: DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    });
  }

  void _toggleMute() {
    setState(() {
      _draft = _draft.copyWith(isMuted: !_draft.isMuted);
    });

    if (_isNew) {
      return;
    }

    context.read<TodoProvider>().toggleMute(_draft.id);
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  void _close() {
    _dismissKeyboard();
    widget.onClose?.call();
    if (widget.onClose == null && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    final updatedTodo = _draft.copyWith(
      title: title,
      content: _contentController.text.trim(),
      notes: _notesController.text.trim(),
    );

    context.read<TodoProvider>().saveTodo(updatedTodo);

    setState(() {
      _draft = updatedTodo;
      _isEditing = false;
      _isNew = false;
    });

    if (widget.closeOnSave) {
      _close();
    }
  }

  void _delete() {
    if (_isNew) {
      _close();
      return;
    }

    context.read<TodoProvider>().removeTodo(_draft.id);
    _close();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: theme.colorScheme.scrim.withValues(alpha: 0.22),
        child: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxCardHeight = constraints.maxHeight;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: GestureDetector(
                        onTap: _dismissKeyboard,
                        child: Card(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: maxCardHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                18,
                                24,
                                24,
                              ),
                              child: Column(
                                children: [
                                  _CardHeader(
                                    isMuted: _draft.isMuted,
                                    title: _isEditing
                                        ? (_titleController.text.trim().isEmpty
                                              ? 'Todo'
                                              : _titleController.text.trim())
                                        : _draft.presentationTitle,
                                    onMutePressed: _toggleMute,
                                    onEditPressed: _enterEditMode,
                                    onClosePressed: _close,
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (_isEditing) ...[
                                            TextField(
                                              controller: _titleController,
                                              onChanged: (_) => setState(() {}),
                                              onTapOutside: (_) =>
                                                  _dismissKeyboard(),
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: const InputDecoration(
                                                hintText: 'Untitled todo',
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: _contentController,
                                              onTapOutside: (_) =>
                                                  _dismissKeyboard(),
                                              minLines: 3,
                                              maxLines: 5,
                                              decoration: const InputDecoration(
                                                labelText: 'Content',
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: _notesController,
                                              onTapOutside: (_) =>
                                                  _dismissKeyboard(),
                                              minLines: 2,
                                              maxLines: 4,
                                              decoration: const InputDecoration(
                                                labelText: 'Notes',
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            _EditableMetaTile(
                                              icon: Icons.schedule,
                                              label: 'Reminder time',
                                              value: _formatDateTime(
                                                context,
                                                _draft.reminderTime,
                                              ),
                                              onPressed: _pickReminderDateTime,
                                            ),
                                            const SizedBox(height: 12),
                                            _EditableMetaTile(
                                              icon: Icons.event,
                                              label: 'Deadline',
                                              value: _formatDateTime(
                                                context,
                                                _draft.deadline,
                                              ),
                                              onPressed: _pickDeadlineDateTime,
                                            ),
                                            const SizedBox(height: 16),
                                          ] else ...[
                                            _ReadOnlySection(
                                              label: 'Content',
                                              value: _draft.content,
                                              icon: Icons.subject,
                                            ),
                                            const SizedBox(height: 12),
                                            _ReadOnlySection(
                                              label: 'Notes',
                                              value: _draft.notes,
                                              icon:
                                                  Icons.sticky_note_2_outlined,
                                            ),
                                            const SizedBox(height: 12),
                                            _ReadOnlySection(
                                              label: 'Reminder time',
                                              value: _formatDateTime(
                                                context,
                                                _draft.reminderTime,
                                              ),
                                              icon: Icons.schedule,
                                            ),
                                            const SizedBox(height: 12),
                                            _ReadOnlySection(
                                              label: 'Deadline',
                                              value: _formatDateTime(
                                                context,
                                                _draft.deadline,
                                              ),
                                              icon: Icons.event,
                                            ),
                                            const SizedBox(height: 12),
                                            _ReadOnlySection(
                                              label: 'Muted',
                                              value: _draft.isMuted
                                                  ? 'Muted'
                                                  : 'Active',
                                              icon: _draft.isMuted
                                                  ? Icons
                                                        .notifications_off_outlined
                                                  : Icons
                                                        .notifications_none_rounded,
                                            ),
                                          ],
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 240,
                                            ),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            transitionBuilder:
                                                (child, animation) {
                                                  return SizeTransition(
                                                    sizeFactor: animation,
                                                    axisAlignment: -1,
                                                    child: child,
                                                  );
                                                },
                                            child: _isEditing
                                                ? _ReminderLeadSlider(
                                                    key: const ValueKey(
                                                      'lead-slider',
                                                    ),
                                                    value: _draft
                                                        .remindDaysBeforeDDL,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _draft = _draft.copyWith(
                                                          remindDaysBeforeDDL:
                                                              value,
                                                        );
                                                      });
                                                    },
                                                  )
                                                : const SizedBox.shrink(
                                                    key: ValueKey(
                                                      'slider-hidden',
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      if (_isEditing)
                                        FilledButton.tonalIcon(
                                          onPressed: _delete,
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: Text(
                                            _isNew ? 'Discard' : 'Delete',
                                          ),
                                        ),
                                      const Spacer(),
                                      if (_isEditing)
                                        FilledButton.icon(
                                          onPressed: _save,
                                          icon: const Icon(Icons.check),
                                          label: const Text('Save'),
                                        )
                                      else
                                        FilledButton.tonalIcon(
                                          onPressed: _close,
                                          icon: const Icon(
                                            Icons.keyboard_return,
                                          ),
                                          label: const Text('Back'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(value);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$date, $time';
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.isMuted,
    required this.title,
    required this.onMutePressed,
    required this.onEditPressed,
    required this.onClosePressed,
  });

  final bool isMuted;
  final String title;
  final VoidCallback onMutePressed;
  final VoidCallback onEditPressed;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                onPressed: onMutePressed,
                tooltip: isMuted ? 'Unmute reminder' : 'Mute reminder',
                style: _headerActionStyle(context),
                icon: Icon(
                  isMuted
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_none_rounded,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: onEditPressed,
                tooltip: 'Edit todo',
                style: _headerActionStyle(context),
                icon: const Icon(Icons.edit_note, size: 20),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 96),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton.filledTonal(
            onPressed: onClosePressed,
            tooltip: 'Close',
            style: _headerActionStyle(context),
            icon: const Icon(Icons.close, size: 20),
          ),
        ),
      ],
    );
  }

  ButtonStyle _headerActionStyle(BuildContext context) {
    return IconButton.styleFrom(
      minimumSize: const Size.square(40),
      maximumSize: const Size.square(40),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _EditableMetaTile extends StatelessWidget {
  const _EditableMetaTile({
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

class _ReadOnlySection extends StatelessWidget {
  const _ReadOnlySection({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value.trim().isEmpty ? 'No details yet.' : value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayValue,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ReminderLeadSlider extends StatelessWidget {
  const _ReminderLeadSlider({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Days before deadline reminder',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value day${value == 1 ? '' : 's'} before deadline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 14,
            divisions: 14,
            label: '$value',
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ],
      ),
    );
  }
}
