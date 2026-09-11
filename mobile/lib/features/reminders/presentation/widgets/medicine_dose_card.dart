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
  final String? scheduleSummary;
  final List<String>? allScheduleTimes;

  const MedicineDoseCard({
    super.key,
    required this.dose,
    this.onEdit,
    this.onDelete,
    this.scheduleSummary,
    this.allScheduleTimes,
  });

  @override
  ConsumerState<MedicineDoseCard> createState() => _MedicineDoseCardState();
}

class _MedicineDoseCardState extends ConsumerState<MedicineDoseCard> {
  bool _isActionInProgress = false;

  String _formatTime(String timeStr) {
    try {
      if (timeStr.contains('T')) {
        final dt = DateTime.parse(timeStr);
        return DateFormat('h:mm a').format(dt);
      }
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dt = DateTime(2026, 1, 1, hour, minute);
        return DateFormat('h:mm a').format(dt);
      }
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
    final isOutOfStock = currentStock <= 0;
    final isLowStock = currentStock <= refillThreshold && !isOutOfStock;

    Color cardBorder = const Color(0xFFE2E8F0);
    if (isTaken) cardBorder = const Color(0xFFBBF7D0);
    if (isSnoozed) cardBorder = const Color(0xFFFDE68A);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Bar / Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isTaken
                          ? const Color(0xFFDCFCE7)
                          : isSnoozed
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isTaken
                          ? Icons.check_circle_rounded
                          : isSnoozed
                              ? Icons.snooze_rounded
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
                  // Name and Dosage
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                dose.medicineName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isTaken)
                              _buildStatusBadge('TAKEN', const Color(0xFFDCFCE7), const Color(0xFF166534))
                            else if (isSkipped)
                              _buildStatusBadge('SKIPPED', const Color(0xFFF1F5F9), const Color(0xFF475569))
                            else if (isSnoozed)
                              _buildStatusBadge('SNOOZED', const Color(0xFFFEF3C7), const Color(0xFF92400E))
                            else
                              _buildStatusBadge('SCHEDULED', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dose.dosage != null && dose.dosage!.isNotEmpty
                              ? dose.dosage!
                              : '${dose.dosagePerIntake.toInt()} ${dose.dosageUnit ?? "unit"} per intake',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // More Menu
                  if (widget.onEdit != null || widget.onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                SizedBox(width: 10),
                                Text('Edit Medicine', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        if (widget.onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                SizedBox(width: 10),
                                Text('Remove', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.error)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // Dose State Banner or Schedule Time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDoseStateBanner(dose, isTaken, isSkipped, isSnoozed),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            if (!isTaken && !isSkipped)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildActionButtons(),
              ),

            const SizedBox(height: 12),

            // Divider
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Footer: Stock Visualization & Refill Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: isOutOfStock
                        ? AppColors.error
                        : isLowStock
                            ? Colors.amber.shade800
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Stock: $currentStock ${dose.dosageUnit ?? "units"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOutOfStock
                          ? AppColors.error
                          : isLowStock
                              ? Colors.amber.shade900
                              : const Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  _buildStockBadge(isOutOfStock, isLowStock, currentStock, refillThreshold),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildDoseStateBanner(ReminderOccurrenceModel dose, bool isTaken, bool isSkipped, bool isSnoozed) {
    if (isTaken) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '✓ Taken at ${_formatTime(dose.actionTime ?? dose.scheduledTime)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isSkipped) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
      );
    }

    if (isSnoozed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_rounded, size: 18, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🔔 Snoozed until ${_formatTime(dose.snoozedUntil ?? dose.scheduledTime)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.allScheduleTimes != null && widget.allScheduleTimes!.length > 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Scheduled: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  ...widget.allScheduleTimes!.map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String scheduleText;
    if (widget.scheduleSummary != null && widget.scheduleSummary!.isNotEmpty) {
      scheduleText = widget.scheduleSummary!;
    } else if (dose.scheduledTime.isNotEmpty) {
      scheduleText = 'Scheduled for ${_formatTime(dose.scheduledTime)}';
    } else {
      scheduleText = 'Time not set';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              scheduleText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Taken Button
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: _isActionInProgress ? null : _handleTaken,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Taken'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Skip Button
        Expanded(
          flex: 3,
          child: OutlinedButton.icon(
            onPressed: _isActionInProgress ? null : _handleSkip,
            icon: const Icon(Icons.close_rounded, size: 15),
            label: const Text('Skip'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Snooze Button
        Expanded(
          flex: 3,
          child: OutlinedButton.icon(
            onPressed: _isActionInProgress ? null : _handleSnooze,
            icon: const Icon(Icons.snooze_rounded, size: 15),
            label: const Text('Snooze'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber.shade800,
              side: BorderSide(color: Colors.amber.shade300),
              backgroundColor: const Color(0xFFFFFDF5),
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockBadge(bool isOutOfStock, bool isLowStock, int currentStock, int threshold) {
    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'OUT OF STOCK',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
        ),
      );
    }
    if (isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'LOW STOCK ALERT',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'HEALTHY STOCK',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
      ),
    );
  }
}

extension DurationExtension on DateTime {
  DateTime plus(Duration duration) => add(duration);
}
