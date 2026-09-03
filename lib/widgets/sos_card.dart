import 'package:flutter/material.dart';
import '../models/sos_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'priority_badge.dart';

class SosCard extends StatelessWidget {
  final SosModel sos;
  final int index;
  final VoidCallback onTap;

  const SosCard({
    super.key,
    required this.sos,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayId = Helpers.formatDisplayId(sos.sosId, index);

    Color statusColor;
    switch (sos.status) {
      case 'Accepted':
        statusColor = AppColors.statusAccepted;
        break;
      case 'Responding':
        statusColor = AppColors.statusResponding;
        break;
      case 'Rescued':
        statusColor = AppColors.statusRescued;
        break;
      case 'Pending':
      default:
        statusColor = AppColors.statusPending;
        break;
    }

    return Card(
      color: AppColors.surface,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: sos.priority == 'HIGH' ? AppColors.primary.withOpacity(0.5) : AppColors.border,
          width: sos.priority == 'HIGH' ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PriorityBadge(priority: sos.priority),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      sos.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sos.victimName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sos.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: AppColors.surfaceLight, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        sos.category,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatTime(sos.timestamp),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
