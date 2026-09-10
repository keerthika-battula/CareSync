import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/reminders/data/models/reminder_models.dart';
import 'package:caresync/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:caresync/features/reminders/presentation/widgets/snooze_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MedicineDoseCard extends ConsumerStatefulWidget {
  final ReminderOccurrenceModel dose;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicineDoseCard({
    super.key,
    required this.dose,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<MedicineDoseCard> createState() => _MedicineDoseCardState();
}

class _MedicineDoseCardState extends ConsumerState<MedicineDoseCard> {
  bool _isActionInProgress = false;

  String _formatTime(String timeStr) {
    try {
      final dt = DateTime.parse(timeStr);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _handleTaken() async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(reminderProvider.notifier).markTaken(widget.dose.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Marked ${widget.dose.medicineName} as taken'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update dose: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleSkip() async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(reminderProvider.notifier).markSkipped(widget.dose.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skipped dose for ${widget.dose.medicineName}'),
            backgroundColor: const Color(0xFF64748B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to skip dose: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleSnooze() async {
    if (_isActionInProgress) return;
    final minutes = await SnoozeDialog.show(context, widget.dose.medicineName);
    if (minutes == null) return;

    setState(() => _isActionInProgress = true);
    try {
      await ref.read(reminderProvider.notifier).snooze(widget.dose.id, minutes);
      final newTime = DateFormat('h:mm a').format(DateTime.now().plus(Duration(minutes: minutes)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder snoozed until $newTime'),
            backgroundColor: Colors.amber.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to snooze reminder: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dose = widget.dose;
    final isTaken = dose.isTaken;
    final isSkipped = dose.isSkipped;
    final isSnoozed = dose.isSnoozed;
    final currentStock = dose.currentStock ?? 0;
    final refillThreshold = dose.refillThreshold ?? 7;
    final isLowStock = currentStock <= refillThreshold;

    Color cardBorder = const Color(0xFFE2E8F0);
    if (isTaken) cardBorder = const Color(0xFFBBF7D0);
    if (isSnoozed) cardBorder = const Color(0xFFFDE68A);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Medicine Icon, Name, Dosage & Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isTaken
                      ? const Color(0xFFDCFCE7)
                      : isSnoozed
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isTaken
                      ? Icons.check_circle_outline
                      : isSnoozed
                          ? Icons.snooze
                          : Icons.medication_rounded,
                  color: isTaken
                      ? AppColors.success
                      : isSnoozed
                          ? Colors.amber.shade800
                          : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.medicineName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dose.dosage != null && dose.dosage!.isNotEmpty
                          ? dose.dosage!
                          : '${dose.dosagePerIntake.toInt()} unit',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (widget.onEdit != null || widget.onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'edit' && widget.onEdit != null) widget.onEdit!();
                    if (val == 'delete' && widget.onDelete != null) widget.onDelete!();
                  },
                  itemBuilder: (context) => [
                    if (widget.onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Edit Medicine'),
                          ],
                        ),
                      ),
                    if (widget.onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Remove', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Dose Status & Timing Banner
          if (isTaken) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    '✓ Taken at ${_formatTime(dose.actionTime ?? dose.scheduledTime)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isSkipped) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel_outlined, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text(
                    'Skipped dose for today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isSnoozed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 18, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Text(
                    '🔔 Snoozed until ${_formatTime(dose.snoozedUntil ?? dose.scheduledTime)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  "Today's dose: ${_formatTime(dose.scheduledTime)}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons: [ ✓ Taken ] [ Skip ] [ Snooze ]
          if (!isTaken && !isSkipped) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isActionInProgress ? null : _handleTaken,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Taken'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isActionInProgress ? null : _handleSkip,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isActionInProgress ? null : _handleSnooze,
                  icon: const Icon(Icons.snooze, size: 16),
                  label: const Text('Snooze'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade800,
                    side: BorderSide(color: Colors.amber.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Footer: Stock display
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Stock: $currentStock ${dose.dosageUnit ?? "units"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLowStock ? AppColors.error : AppColors.textSecondary,
                ),
              ),
              if (isLowStock) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LOW STOCK',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

extension DurationExtension on DateTime {
  DateTime plus(Duration duration) => add(duration);
}
