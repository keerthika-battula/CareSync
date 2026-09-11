import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/core/errors/app_error_formatter.dart';
import 'package:caresync/features/admin/data/models/admin_models.dart';
import 'package:caresync/features/admin/presentation/providers/admin_provider.dart';
import 'package:caresync/features/admin/presentation/providers/admin_user_healthcare_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminUserDetailDialog extends ConsumerStatefulWidget {
  final AdminUser user;

  const AdminUserDetailDialog({super.key, required this.user});

  @override
  ConsumerState<AdminUserDetailDialog> createState() => _AdminUserDetailDialogState();
}

class _AdminUserDetailDialogState extends ConsumerState<AdminUserDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).fetchHealthcareOverview(widget.user.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final overview = state.healthcareOverviews[widget.user.id];
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy, hh:mm a');

    // Find the latest state of this user if updated
    final currentUser = state.users.firstWhere(
      (u) => u.id == widget.user.id,
      orElse: () => widget.user,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: currentUser.isAdmin
                        ? Colors.purple.withOpacity(0.15)
                        : AppColors.primaryLight.withOpacity(0.2),
                    child: Text(
                      currentUser.firstName.isNotEmpty
                          ? currentUser.firstName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: currentUser.isAdmin ? Colors.purple : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                currentUser.fullName,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildRoleBadge(currentUser.role),
                            const SizedBox(width: 6),
                            _buildStatusBadge(currentUser.isActive),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser.email,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Information
                      Text(
                        'Account Information',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow('User ID', currentUser.id),
                      if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty)
                        _buildInfoRow('Phone', currentUser.phoneNumber!),
                      if (currentUser.createdAt != null)
                        _buildInfoRow('Created At', dateFormat.format(currentUser.createdAt!)),
                      _buildInfoRow('Email Verified', currentUser.isEmailVerified ? 'Yes' : 'No'),

                      const SizedBox(height: 20),

                      // Healthcare Summary (Lazy Loaded)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Healthcare Summary',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (state.isOverviewLoading && overview == null)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (overview != null)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 450;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildCountCard(
                                  title: 'Family Members',
                                  count: overview.familyMembersCount,
                                  icon: Icons.people_outline,
                                  color: Colors.indigo,
                                  width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2,
                                ),
                                _buildCountCard(
                                  title: 'Active Medicines',
                                  count: overview.activeMedicinesCount,
                                  icon: Icons.medication_outlined,
                                  color: Colors.teal,
                                  width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2,
                                ),
                                _buildCountCard(
                                  title: 'Upcoming Appointments',
                                  count: overview.upcomingAppointmentsCount,
                                  icon: Icons.calendar_month_outlined,
                                  color: Colors.orange,
                                  width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2,
                                ),
                                _buildCountCard(
                                  title: 'Total Documents',
                                  count: overview.totalDocumentsCount,
                                  icon: Icons.folder_outlined,
                                  color: Colors.blueGrey,
                                  width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2,
                                ),
                              ],
                            );
                          },
                        )
                      else if (state.isOverviewLoading)
                        Container(
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 10),
                              Text('Fetching healthcare statistics...'),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Detailed Healthcare Records Section (Lazy Loaded)
                      Row(
                        children: [
                          Text(
                            'Healthcare Records',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary),
                                SizedBox(width: 4),
                                Text(
                                  'Read-Only',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Detailed records are lazily loaded on demand for this user. Administrative actions are read-only to safeguard patient privacy.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),

                      // Tabs for Medicines, Documents, Family, Appointments
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: const [
                          Tab(icon: Icon(Icons.medication_outlined, size: 18), text: 'Medicines'),
                          Tab(icon: Icon(Icons.folder_outlined, size: 18), text: 'Documents'),
                          Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Family'),
                          Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Appointments'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 260,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMedicinesTab(widget.user.id),
                            _buildDocumentsTab(widget.user.id),
                            _buildFamilyTab(widget.user.id),
                            _buildAppointmentsTab(widget.user.id),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 20),
              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicinesTab(String userId) {
    final medAsync = ref.watch(adminUserMedicinesProvider(userId));
    return medAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(AppErrorFormatter.format(e), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)))),
      data: (meds) {
        if (meds.isEmpty) {
          return const Center(
            child: Text('No active medicines recorded for this user.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: meds.length,
          itemBuilder: (context, index) {
            final med = meds[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: Colors.teal, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        if (med.dosage != null)
                          Text(med.dosage!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('Stock: ${med.currentQuantity} (Threshold: ${med.refillThreshold})',
                            style: TextStyle(fontSize: 11, color: med.isLowStock ? AppColors.error : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  if (med.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('LOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentsTab(String userId) {
    final docsAsync = ref.watch(adminUserDocumentsProvider(userId));
    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(AppErrorFormatter.format(e), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)))),
      data: (docs) {
        if (docs.isEmpty) {
          return const Center(
            child: Text('No documents uploaded for this user.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: Colors.blueGrey, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${doc.documentType.replaceAll('_', ' ')} • ${doc.fileName} ${doc.formattedFileSize}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.primary),
                    tooltip: 'Open in browser',
                    onPressed: () => downloadAdminUserDocument(ref, userId, doc, openInNewTab: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.primary),
                    tooltip: 'Download file',
                    onPressed: () => downloadAdminUserDocument(ref, userId, doc, openInNewTab: false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFamilyTab(String userId) {
    final famAsync = ref.watch(adminUserFamilyProvider(userId));
    return famAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(AppErrorFormatter.format(e), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)))),
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Text('No family members registered for this user.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final m = members[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.indigo, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Relationship: ${m.relationship}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentsTab(String userId) {
    final apptAsync = ref.watch(adminUserAppointmentsProvider(userId));
    return apptAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(AppErrorFormatter.format(e), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)))),
      data: (appts) {
        if (appts.isEmpty) {
          return const Center(
            child: Text('No upcoming appointments for this user.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: appts.length,
          itemBuilder: (context, index) {
            final a = appts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: Colors.orange, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.doctorName.isNotEmpty ? a.doctorName : 'Medical Appointment',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${a.appointmentDate} ${a.appointmentTime} • ${a.hospitalClinic}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(a.status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role.toUpperCase() == 'ADMIN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.purple.withOpacity(0.12) : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Colors.purple.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAdmin ? Colors.purple : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard({
    required String title,
    required dynamic count,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count != null ? count.toString() : '-',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
