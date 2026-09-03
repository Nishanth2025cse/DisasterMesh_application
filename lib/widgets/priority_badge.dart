import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    String icon;

    switch (priority.toUpperCase()) {
      case 'HIGH':
        bg = AppColors.priorityHigh;
        label = "HIGH";
        icon = "🔴";
        break;
      case 'MEDIUM':
        bg = AppColors.priorityMedium;
        label = "MEDIUM";
        icon = "🟠";
        break;
      case 'LOW':
      default:
        bg = AppColors.priorityLow;
        label = "LOW";
        icon = "🟢";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bg, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: bg,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
