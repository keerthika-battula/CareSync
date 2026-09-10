import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/appointments/data/models/appointment_models.dart';
import 'package:caresync/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:caresync/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh appointments',
            onPressed: () => ref.read(appointmentProvider.notifier).loadAppointments(),
          ),
        ],
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load appointments: $err', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(appointmentProvider.notifier).loadAppointments(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (appointments) {
          if (appointments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.calendar_today_outlined,
              title: 'No upcoming appointments',
              subtitle: 'Keep track of doctor consultations, lab tests, and hospital visits.',
              actionLabel: 'Book Appointment',
              onAction: () => _showAddAppointmentDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              return _buildAppointmentCard(appt);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAppointmentDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Schedule Appointment'),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.orange, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appt.doctorName.isNotEmpty ? appt.doctorName : 'Doctor Consultation',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        appt.status,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                if (appt.hospitalClinic.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appt.hospitalClinic,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${appt.appointmentDate} at ${appt.appointmentTime}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
                if (appt.purpose != null && appt.purpose!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Purpose: ${appt.purpose}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
                if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    appt.notes!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
            tooltip: 'Cancel appointment',
            onPressed: () => _confirmCancelAppointment(appt),
          ),
        ],
      ),
    );
  }

  void _showAddAppointmentDialog() {
    final doctorController = TextEditingController();
    final hospitalController = TextEditingController();
    final purposeController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    int reminderMinutes = 60;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Schedule Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: doctorController,
                      decoration: const InputDecoration(
                        labelText: 'Doctor / Specialist *',
                        hintText: 'e.g., Dr. Priya Sharma (Cardiology)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Doctor name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: hospitalController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital / Clinic',
                        hintText: 'e.g., Apollo Hospitals',
                        prefixIcon: Icon(Icons.local_hospital_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: dialogCtx,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date *',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: dialogCtx,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time *',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: purposeController,
                      decoration: const InputDecoration(
                        labelText: 'Purpose / Reason',
                        hintText: 'e.g., Routine cardiac checkup',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: reminderMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Reminder Alert',
                        prefixIcon: Icon(Icons.alarm),
                      ),
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                        DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                        DropdownMenuItem(value: 60, child: Text('1 hour before')),
                        DropdownMenuItem(value: 120, child: Text('2 hours before')),
                        DropdownMenuItem(value: 1440, child: Text('1 day before')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => reminderMinutes = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Notes',
                        hintText: 'e.g., Bring past test reports and fast 8h prior',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                        final timeStr =
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';

                        await ref.read(appointmentProvider.notifier).createAppointment(
                              doctorName: doctorController.text.trim(),
                              hospitalClinic: hospitalController.text.trim(),
                              appointmentDate: dateStr,
                              appointmentTime: timeStr,
                              purpose: purposeController.text.trim(),
                              notes: notesController.text.trim(),
                              reminderMinutesBefore: reminderMinutes,
                            );

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Appointment scheduled successfully'), backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Appointment'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelAppointment(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel the appointment with "${appt.doctorName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref.read(appointmentProvider.notifier).deleteAppointment(appt.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment cancelled successfully'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
