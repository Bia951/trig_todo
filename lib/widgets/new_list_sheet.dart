import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_list.dart';
import '../providers/todo_provider.dart';

class NewListSheet extends StatefulWidget {
  const NewListSheet({this.existing, super.key});

  final TodoList? existing;

  static Future<void> show(BuildContext context, {TodoList? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => NewListSheet(existing: existing),
    );
  }

  @override
  State<NewListSheet> createState() => _NewListSheetState();
}

class _NewListSheetState extends State<NewListSheet> {
  late final TextEditingController _nameController;
  late int _selectedColorValue;
  late int _selectedIconCodePoint;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(
      text: existing?.name ?? '',
    );
    _selectedColorValue =
        existing?.colorValue ?? TodoList.availableColorValues.first;
    _selectedIconCodePoint =
        existing?.iconCodePoint ?? TodoList.availableIcons.first.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<TodoProvider>();
    final existing = widget.existing;

    if (existing != null) {
      provider.saveTodoList(
        existing.copyWith(
          name: name,
          iconCodePoint: _selectedIconCodePoint,
          colorValue: _selectedColorValue,
        ),
      );
    } else {
      final newId =
          '${name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
      provider.saveTodoList(
        TodoList(
          id: newId,
          name: name,
          iconCodePoint: _selectedIconCodePoint,
          colorValue: _selectedColorValue,
          sortOrder: provider.lists.length,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = Color(_selectedColorValue);
    final selectedIcon = IconData(
      _selectedIconCodePoint,
      fontFamily: 'MaterialIcons',
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Title + Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit List' : 'New List',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _nameController.text.trim().isNotEmpty ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live preview chip
                  Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
                      decoration: BoxDecoration(
                        color: selectedColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              selectedIcon,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _nameController.text.trim().isEmpty
                                ? 'List name'
                                : _nameController.text.trim(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: selectedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Name field
                  Text(
                    'NAME',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'e.g. Travel',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: selectedColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Color picker
                  Text(
                    'COLOR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: TodoList.availableColorValues.map((colorValue) {
                      final isSelected = colorValue == _selectedColorValue;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColorValue = colorValue),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(colorValue)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: theme.colorScheme.surface,
                                      blurRadius: 0,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Color(colorValue),
                                      blurRadius: 0,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 22),

                  // Icon picker
                  Text(
                    'ICON',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: TodoList.availableIcons.length,
                    itemBuilder: (context, index) {
                      final iconData = TodoList.availableIcons[index];
                      final isSelected =
                          iconData.codePoint == _selectedIconCodePoint;
                      return GestureDetector(
                        onTap: () => setState(
                          () => _selectedIconCodePoint = iconData.codePoint,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            iconData,
                            size: 22,
                            color: isSelected
                                ? selectedColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
