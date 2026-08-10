import 'package:flutter/material.dart';

class PageTitle extends StatelessWidget {
  const PageTitle({
    required this.icon,
    required this.color,
    required this.label,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
