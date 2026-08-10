import 'package:flutter/material.dart';

void showUndoTodoSnackBar(
  ScaffoldMessengerState messenger, {
  required ThemeData theme,
  required String message,
  required VoidCallback onUndo,
}) {
  final colors = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  messenger.removeCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      backgroundColor: isDark
          ? colors.surfaceContainerHighest
          : colors.inverseSurface,
      content: Text(
        message,
        style: TextStyle(
          color: isDark ? colors.onSurface : colors.onInverseSurface,
        ),
      ),
      action: SnackBarAction(
        label: 'Undo',
        textColor: isDark ? colors.primary : colors.inversePrimary,
        onPressed: onUndo,
      ),
      duration: const Duration(seconds: 5),
      showCloseIcon: true,
      closeIconColor: isDark ? colors.onSurface : colors.onInverseSurface,
    ),
  );

  Future<void>.delayed(const Duration(seconds: 5), controller.close);
}
