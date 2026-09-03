import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../utils/constants.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: device.isConnected ? AppColors.priorityLow : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cell_tower,
            color: device.isConnected ? AppColors.priorityLow : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.endpointName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "ID: ${device.endpointId}",
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (device.isConnected ? AppColors.priorityLow : AppColors.textMuted).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              device.isConnected ? "Connected" : "Available",
              style: TextStyle(
                color: device.isConnected ? AppColors.priorityLow : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
