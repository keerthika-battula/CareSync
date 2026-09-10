import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:caresync/features/auth/presentation/providers/auth_provider.dart';
import 'package:caresync/features/family/presentation/providers/family_provider.dart';
import 'package:caresync/features/medicines/presentation/providers/medicine_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final medsCount = ref.watch(medicineProvider).maybeWhen(data: (l) => l.length.toString(), orElse: () => '-');
    final apptsCount = ref.watch(appointmentProvider).maybeWhen(data: (l) => l.length.toString(), orElse: () => '-');
    final famCount = ref.watch(familyProvider).maybeWhen(data: (l) => l.length.toString(), orElse: () => '-');

    final displayName = user != null && user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : 'CareSync Member';
    final displayEmail = user?.email ?? '';
    final role = user?.role.toUpperCase() ?? 'USER';
    final isAdmin = role == 'ADMIN';

    final initials = user != null && user.firstName.isNotEmpty
        ? (user.firstName[0] + (user.lastName.isNotEmpty ? user.lastName[0] : '')).toUpperCase()
        : 'CS';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white24,
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.purpleAccent.withOpacity(0.3) : Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Quick stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProfileStat(label: 'Medicines', value: medsCount),
                      const _VerticalDivider(),
                      _ProfileStat(label: 'Appointments', value: apptsCount),
                      const _VerticalDivider(),
                      _ProfileStat(label: 'Family Members', value: famCount),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(label: 'Account & Security'),
                  _SettingsTile(
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    subtitle: user?.id ?? 'Not available',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    label: 'Account Role',
                    subtitle: '$role (Access level managed by CareSync)',
                    onTap: () {},
                  ),
                  if (isAdmin)
                    _SettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin Console',
                      subtitle: 'Open administrative user management',
                      onTap: () => context.go('/admin'),
                    ),

                  const SizedBox(height: 16),
                  const _SectionLabel(label: 'Application'),
                  _SettingsTile(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    subtitle: 'Medication alerts, reminders',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    label: 'About CareSync',
                    subtitle: 'Version 2.0 • Healthcare PWA',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of CareSync?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white24,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textLight),
      ),
    );
  }
}
