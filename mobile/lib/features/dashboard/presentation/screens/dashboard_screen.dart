import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/appointments/data/models/appointment_models.dart';
import 'package:caresync/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:caresync/features/auth/presentation/providers/auth_provider.dart';
import 'package:caresync/features/documents/data/models/document_models.dart';
import 'package:caresync/features/documents/presentation/providers/document_provider.dart';
import 'package:caresync/features/medicines/data/models/medicine_models.dart';
import 'package:caresync/features/medicines/presentation/providers/medicine_provider.dart';
import 'package:caresync/features/reminders/data/models/reminder_models.dart';
import 'package:caresync/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:caresync/features/reminders/presentation/widgets/medicine_dose_card.dart';
import 'package:caresync/shared/widgets/app_logo.dart';
import 'package:caresync/shared/widgets/pwa_install_button.dart';
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
    final documentsAsync = ref.watch(documentProvider);
    final remindersAsync = ref.watch(reminderProvider);

    final userDisplayName = user != null && user.firstName.isNotEmpty
        ? user.firstName
        : 'Keerthika';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const AppLogo(size: 28),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          const PwaInstallButton(),
          if (authState.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.shield_outlined, size: 16, color: Colors.purple),
                label: const Text(
                  'Admin',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                backgroundColor: Colors.purple.withOpacity(0.08),
                side: BorderSide(color: Colors.purple.withOpacity(0.3)),
                onPressed: () => context.go('/admin'),
              ),
            ),
          IconButton(
            tooltip: 'Refresh Dashboard',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(medicineProvider);
              ref.invalidate(appointmentProvider);
              ref.invalidate(documentProvider);
              ref.invalidate(reminderProvider);
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
            // Healthcare Hero Card - Greeting & Date
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x242563EB),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(greetingIcon, color: Colors.amberAccent, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          todayFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Robust Horizontal Greeting
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$greeting, $userDisplayName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your daily medication plan, visits, and health records are in sync.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions Bar
            _buildQuickActions(context),
            const SizedBox(height: 20),

            // Metrics Highlights
            _buildHighlights(isDesktop, medicinesAsync, appointmentsAsync, remindersAsync),
            const SizedBox(height: 24),

            // Today's Medications Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Medications",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Log your doses and stay on schedule',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.go('/medicines'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Manage All', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.medication_outlined, size: 44, color: AppColors.textSecondary),
                        const SizedBox(height: 10),
                        const Text(
                          'No medications added yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add your prescriptions to receive automated reminders and refill notifications.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/medicines'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Medication'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final doses = remindersAsync.valueOrNull ?? [];

                return Column(
                  children: medicines.take(3).map((med) {
                    final matchingDose = doses.cast<ReminderOccurrenceModel?>().firstWhere(
                          (d) => d?.medicineId == med.id,
                          orElse: () => null,
                        );

                    if (matchingDose != null) {
                      return MedicineDoseCard(
                        dose: matchingDose,
                        scheduleSummary: med.scheduleDisplaySummary,
                        allScheduleTimes: med.formattedScheduleTimes,
                      );
                    }

                    final String fallbackTimeStr;
                    if (med.schedules.isNotEmpty &&
                        med.schedules.first.scheduledTimes.isNotEmpty) {
                      final firstTime = med.schedules.first.scheduledTimes.first;
                      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                      fallbackTimeStr = '${todayStr}T$firstTime:00';
                    } else {
                      fallbackTimeStr = DateTime.now().toIso8601String();
                    }

                    final fallbackDose = ReminderOccurrenceModel(
                      id: med.id,
                      medicineId: med.id,
                      medicineName: med.name,
                      dosage: med.dosage,
                      currentStock: med.currentQuantity,
                      refillThreshold: med.refillThreshold,
                      scheduledTime: fallbackTimeStr,
                      status: 'PENDING',
                      snoozeCount: 0,
                    );

                    return MedicineDoseCard(
                      dose: fallbackDose,
                      scheduleSummary: med.scheduleDisplaySummary,
                      allScheduleTimes: med.formattedScheduleTimes,
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Appointments & Refills Sections
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
                                fontSize: 17,
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
                        const SizedBox(height: 10),
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                      fontSize: 17,
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
              const SizedBox(height: 10),
              _buildAppointmentsSection(appointmentsAsync, context),
              const SizedBox(height: 22),
              const Text(
                'Refill & Stock Alerts',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              _buildRefillAlerts(medicinesAsync, context),
            ],

            const SizedBox(height: 24),

            // Recent Documents Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Health Documents',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/documents'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildRecentDocuments(documentsAsync, context, ref),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (label: 'Add Medicine', icon: Icons.medication_rounded, route: '/medicines', color: AppColors.primary, bg: const Color(0xFFEFF6FF)),
      (label: 'Upload Report', icon: Icons.upload_file_rounded, route: '/documents', color: Colors.teal, bg: const Color(0xFFF0FDFA)),
      (label: 'Doctor Visit', icon: Icons.calendar_month_rounded, route: '/appointments', color: Colors.indigo, bg: const Color(0xFFEEF2FF)),
      (label: 'Care Circle', icon: Icons.people_alt_rounded, route: '/family', color: Colors.purple, bg: const Color(0xFFFAF5FF)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Row(
            children: actions.map((act) => Expanded(
              child: InkWell(
                onTap: () => context.go(act.route),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: act.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: act.color.withOpacity(0.2)),
                        ),
                        child: Icon(act.icon, color: act.color, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        act.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: act.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights(
    bool isDesktop,
    AsyncValue<List<MedicineModel>> medicinesAsync,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    AsyncValue<List<ReminderOccurrenceModel>> remindersAsync,
  ) {
    final medicineCount = medicinesAsync.valueOrNull?.length ?? 0;
    final appointmentCount = appointmentsAsync.valueOrNull?.length ?? 0;
    final lowStockCount = (medicinesAsync.valueOrNull ?? []).where((m) => m.isLowStock).length;
    final todayDoseCount = remindersAsync.valueOrNull?.length ?? 0;

    final items = [
      (
        title: 'Prescriptions',
        val: '$medicineCount',
        sub: medicineCount == 1 ? '1 active' : '$medicineCount active',
        icon: Icons.medication_rounded,
        color: AppColors.primary,
        bg: const Color(0xFFEFF6FF),
      ),
      (
        title: 'Today\'s Doses',
        val: '$todayDoseCount',
        sub: todayDoseCount == 1 ? '1 scheduled' : '$todayDoseCount scheduled',
        icon: Icons.check_circle_outline_rounded,
        color: Colors.teal,
        bg: const Color(0xFFF0FDFA),
      ),
      (
        title: 'Doctor Visits',
        val: '$appointmentCount',
        sub: appointmentCount == 1 ? '1 visit' : '$appointmentCount visits',
        icon: Icons.calendar_month_rounded,
        color: Colors.indigo,
        bg: const Color(0xFFEEF2FF),
      ),
      (
        title: 'Refill Alerts',
        val: '$lowStockCount',
        sub: lowStockCount == 0 ? 'Stocked' : '$lowStockCount alerts',
        icon: Icons.warning_amber_rounded,
        color: lowStockCount > 0 ? Colors.amber.shade800 : AppColors.success,
        bg: lowStockCount > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: items
            .map(
              (item) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
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
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.val,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: halfWidth,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.val,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                item.title,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
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
                Icon(Icons.calendar_today_outlined, size: 30, color: AppColors.textSecondary),
                SizedBox(height: 8),
                Text('No visits scheduled', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                SizedBox(height: 4),
                Text('Book a doctor consultation or checkup.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Medicines In Stock',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 13),
                      ),
                      Text(
                        'No medication has dropped below its alert threshold.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D)),
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
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Only ${med.currentQuantity} remaining (threshold: ${med.refillThreshold})',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/medicines'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Update', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildRecentDocuments(AsyncValue<List<HealthcareDocumentModel>> documentsAsync, BuildContext context, WidgetRef ref) {
    return documentsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e'),
      data: (documents) {
        if (documents.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.folder_open_rounded, color: AppColors.textSecondary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No health records uploaded yet',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Upload lab reports and prescriptions to keep them organized.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final doc = documents.first;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${doc.documentType.replaceAll("_", " ")} • ${doc.formattedFileSize}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                tooltip: 'View Document',
                onPressed: () => ref.read(documentProvider.notifier).downloadDocument(doc, openInNewTab: true),
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    specialty,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
