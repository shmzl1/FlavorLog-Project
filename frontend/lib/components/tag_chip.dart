import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return Chip(
      label: Text(label),
      labelStyle: TextStyle(
        color: chipColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: chipColor.withOpacity(0.12),
      side: BorderSide(color: chipColor.withOpacity(0.24)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
