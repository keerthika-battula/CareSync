import 'package:caresync/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class SnoozeDialog extends StatelessWidget {
  final String medicineName;
  final ValueChanged<int> onSnoozeSelected;

  const SnoozeDialog({
    super.key,
    required this.medicineName,
    required this.onSnoozeSelected,
  });

  static Future<int?> show(BuildContext context, String medicineName) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => SnoozeDialog(
        medicineName: medicineName,
        onSnoozeSelected: (mins) => Navigator.pop(ctx, mins),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.snooze, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Snooze reminder',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose snooze duration for $medicineName:',
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
            title: const Text('15 minutes', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            onTap: () => onSnoozeSelected(15),
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
            title: const Text('30 minutes', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            onTap: () => onSnoozeSelected(30),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
