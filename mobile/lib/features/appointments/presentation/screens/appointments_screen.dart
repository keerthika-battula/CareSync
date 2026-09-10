import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final _now = DateTime.now();

  static final _upcomingAppointments = [
    _Appointment(
      doctorName: 'Dr. Priya Sharma',
      specialty: 'Cardiologist',
      hospital: 'Apollo Hospitals',
      dateTime: _now.add(const Duration(days: 3)),
      status: 'UPCOMING',
    ),
    _Appointment(
      doctorName: 'Dr. Rajesh Kumar',
      specialty: 'Diabetologist',
      hospital: 'Fortis Healthcare',
      dateTime: _now.add(const Duration(days: 10)),
      status: 'UPCOMING',
    ),
  ];

  static final _completedAppointments = [
    _Appointment(
      doctorName: 'Dr. Ananya Singh',
      specialty: 'General Physician',
      hospital: 'Max Hospital',
      dateTime: _now.subtract(const Duration(days: 7)),
      status: 'COMPLETED',
    ),
  ];

  static final _cancelledAppointments = <_Appointment>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AppointmentList(
            appointments: _upcomingAppointments,
            emptyIcon: Icons.calendar_today_outlined,
            emptyTitle: 'No Upcoming Appointments',
            emptySubtitle: 'Schedule an appointment with your doctor.',
          ),
          _AppointmentList(
            appointments: _completedAppointments,
            emptyIcon: Icons.check_circle_outline,
            emptyTitle: 'No Completed Appointments',
            emptySubtitle: 'Your completed appointments will appear here.',
          ),
          _AppointmentList(
            appointments: _cancelledAppointments,
            emptyIcon: Icons.cancel_outlined,
            emptyTitle: 'No Cancelled Appointments',
            emptySubtitle: 'Your cancelled appointments will appear here.',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: navigate to add appointment screen
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
    );
  }
}

class _Appointment {
  const _Appointment({
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.dateTime,
    required this.status,
  });

  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime dateTime;
  final String status;
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.appointments,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<_Appointment> appointments;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return EmptyStateWidget(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: appointments.length,
      itemBuilder: (context, index) =>
          _AppointmentCard(appointment: appointments[index]),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final _Appointment appointment;

  Color get _statusColor {
    switch (appointment.status) {
      case 'UPCOMING':
        return AppColors.info;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child:
                      Icon(Icons.person_outline, color: _statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        appointment.specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPill(
                  icon: Icons.local_hospital_outlined,
                  label: appointment.hospital,
                ),
                const SizedBox(width: 12),
                _InfoPill(
                  icon: Icons.calendar_today,
                  label: DateFormat('MMM d, yyyy').format(appointment.dateTime),
                ),
                const SizedBox(width: 12),
                _InfoPill(
                  icon: Icons.access_time,
                  label: DateFormat('h:mm a').format(appointment.dateTime),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
