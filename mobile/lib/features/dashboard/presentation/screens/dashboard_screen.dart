import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/appointments/data/models/appointment_models.dart';
import 'package:caresync/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:caresync/features/auth/presentation/providers/auth_provider.dart';
import 'package:caresync/features/medicines/data/models/medicine_models.dart';
import 'package:caresync/features/medicines/presentation/providers/medicine_provider.dart';
import 'package:caresync/features/reminders/data/models/reminder_models.dart';
import 'package:caresync/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:caresync/features/reminders/presentation/widgets/medicine_dose_card.dart';
import 'package:caresync/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 17) {
      return Icons.wb_sunny_rounded;
    } else if (hour >= 17 && hour < 21) {
      return Icons.wb_twilight_rounded;
    } else {
      return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final greeting = _getGreeting();
    final greetingIcon = _getGreetingIcon();
    final todayFormatted = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final medicinesAsync = ref.watch(medicineProvider);
    final appointmentsAsync = ref.watch(appointmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const AppLogo(size: 28),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          if (authState.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.shield_outlined, size: 16, color: Colors.purple),
                label: const Text(
                  'Admin Console',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                backgroundColor: Colors.purple.withOpacity(0.08),
                side: BorderSide(color: Colors.purple.withOpacity(0.3)),
                onPressed: () => context.go('/admin'),
              ),
            ),
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(medicineProvider);
              ref.invalidate(appointmentProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Greeting Card - Full width & completely horizontal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(greetingIcon, color: Colors.amberAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          todayFormatted,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (authState.isAdmin && isDesktop) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/admin'),
                          icon: const Icon(Icons.admin_panel_settings, size: 16),
                          label: const Text('Admin Panel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$greeting, ${user != null && user.firstName.isNotEmpty ? user.firstName : "Friend"}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your health reminders and medications are in sync.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Bar
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // Metrics Row
            _buildQuickHighlights(isDesktop, medicinesAsync, appointmentsAsync),
            const SizedBox(height: 28),

            // Today's Scheduled Medication Doses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Medications",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/medicines'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Manage All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            medicinesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text('Unable to load medications: $err', style: TextStyle(color: Colors.red.shade800)),
              ),
              data: (medicines) {
                if (medicines.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.medication_outlined, size: 40, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        const Text(
                          'No medications added yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Keep track of your dosages and refill alerts by adding your first medicine.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/medicines'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Medication'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final remindersAsync = ref.watch(reminderProvider);
                final doses = remindersAsync.valueOrNull ?? [];

                return Column(
                  children: medicines.take(4).map((med) {
                    final matchingDose = doses.cast<ReminderOccurrenceModel?>().firstWhere(
                          (d) => d?.medicineId == med.id,
                          orElse: () => null,
                        );

                    if (matchingDose != null) {
                      return MedicineDoseCard(dose: matchingDose);
                    }

                    final fallbackDose = ReminderOccurrenceModel(
                      id: med.id,
                      medicineId: med.id,
                      medicineName: med.name,
                      dosage: med.dosage,
                      currentStock: med.currentQuantity,
                      refillThreshold: med.refillThreshold,
                      scheduledTime: DateTime.now().toIso8601String(),
                      status: 'PENDING',
                      snoozeCount: 0,
                    );

                    return MedicineDoseCard(dose: fallbackDose);
                  }).toList(),
                );
              },
            ),


            const SizedBox(height: 28),

            // Upcoming Appointments & Refills Grid
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Upcoming Appointments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/appointments'),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildAppointmentsSection(appointmentsAsync, context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Refill & Stock Alerts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRefillAlerts(medicinesAsync, context),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/appointments'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAppointmentsSection(appointmentsAsync, context),
              const SizedBox(height: 24),
              const Text(
                'Refill & Stock Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildRefillAlerts(medicinesAsync, context),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (label: 'Add Medicine', icon: Icons.medication_outlined, route: '/medicines', color: AppColors.primary),
      (label: 'Upload Document', icon: Icons.upload_file_outlined, route: '/documents', color: Colors.teal),
      (label: 'Schedule Visit', icon: Icons.calendar_today_outlined, route: '/appointments', color: Colors.indigo),
      (label: 'Add Family', icon: Icons.group_add_outlined, route: '/family', color: Colors.purple),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: actions.map((act) => ActionChip(
              avatar: Icon(act.icon, size: 16, color: act.color),
              label: Text(act.label, style: TextStyle(fontWeight: FontWeight.w600, color: act.color, fontSize: 13)),
              backgroundColor: act.color.withOpacity(0.08),
              side: BorderSide(color: act.color.withOpacity(0.25)),
              onPressed: () => context.go(act.route),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHighlights(
    bool isDesktop,
    AsyncValue<List<MedicineModel>> medicinesAsync,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
  ) {
    final medicineCount = medicinesAsync.valueOrNull?.length ?? 0;
    final appointmentCount = appointmentsAsync.valueOrNull?.length ?? 0;
    final lowStockCount = (medicinesAsync.valueOrNull ?? []).where((m) => m.isLowStock).length;

    final items = [
      (
        title: 'Active Rx',
        val: '$medicineCount',
        sub: medicineCount == 1 ? '1 medicine' : '$medicineCount medicines',
        icon: Icons.medication_outlined,
        color: AppColors.primary,
        bg: const Color(0xFFEFF6FF),
      ),
      (
        title: 'Appointments',
        val: '$appointmentCount',
        sub: appointmentCount == 1 ? '1 scheduled' : '$appointmentCount scheduled',
        icon: Icons.calendar_month_outlined,
        color: Colors.indigo,
        bg: const Color(0xFFEEF2FF),
      ),
      (
        title: 'Refill Alerts',
        val: '$lowStockCount',
        sub: lowStockCount == 0 ? 'All well stocked' : '$lowStockCount need refill',
        icon: Icons.warning_amber_rounded,
        color: lowStockCount > 0 ? Colors.amber.shade700 : AppColors.success,
        bg: lowStockCount > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: items
            .map(
              (item) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.val,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            item.sub,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: item.color, size: 20),
                    const SizedBox(height: 8),
                    Text(
                      item.val,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAppointmentsSection(AsyncValue<List<AppointmentModel>> appointmentsAsync, BuildContext context) {
    return appointmentsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e'),
      data: (appointments) {
        if (appointments.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.calendar_today_outlined, size: 32, color: AppColors.textSecondary),
                SizedBox(height: 8),
                Text('No visits scheduled', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                SizedBox(height: 4),
                Text('Schedule a doctor visit anytime.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final nextAppt = appointments.first;
        return _buildAppointmentCard(
          doctor: nextAppt.doctorName,
          specialty: nextAppt.hospitalClinic.isNotEmpty ? nextAppt.hospitalClinic : (nextAppt.purpose ?? 'General Consultation'),
          dateStr: '${nextAppt.appointmentDate} at ${nextAppt.appointmentTime}',
          onTap: () => context.go('/appointments'),
        );
      },
    );
  }

  Widget _buildRefillAlerts(AsyncValue<List<MedicineModel>> medicinesAsync, BuildContext context) {
    return medicinesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (medicines) {
        final lowStockMeds = medicines.where((m) => m.isLowStock).toList();
        if (lowStockMeds.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Medicines In Stock',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                      Text(
                        'No medication has dropped below its threshold.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: lowStockMeds.take(2).map((med) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Only ${med.currentQuantity} remaining (threshold: ${med.refillThreshold})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/medicines'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Update Stock', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentCard({
    required String doctor,
    required String specialty,
    required String dateStr,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    specialty,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

