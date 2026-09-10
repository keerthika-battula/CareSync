import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:caresync/features/auth/presentation/providers/auth_provider.dart';
import 'package:caresync/features/family/presentation/providers/family_provider.dart';
import 'package:caresync/features/medicines/presentation/providers/medicine_provider.dart';
import 'package:caresync/shared/widgets/app_logo.dart';
import 'package:caresync/shared/widgets/pwa_install_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final medsCount = ref.watch(medicineProvider).maybeWhen(data: (l) => l.length.toString(), orElse: () => '0');
    final apptsCount = ref.watch(appointmentProvider).maybeWhen(data: (l) => l.length.toString(), orElse: () => '0');
    final famCount = ref.watch(familyProvider).maybeWhen(data: (l) => l.length.toString(), orElse: () => '0');

    final displayName = user != null && user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : 'Keerthika Battula';
    final displayEmail = user != null && user.email.trim().isNotEmpty
        ? user.email.trim()
        : 'battula.keerthika0@gmail.com';
    final role = user?.role.toUpperCase() ?? 'USER';
    final isAdmin = role == 'ADMIN';

    final initials = user != null && user.firstName.isNotEmpty
        ? (user.firstName[0] + (user.lastName.isNotEmpty ? user.lastName[0] : '')).toUpperCase()
        : 'KB';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const AppLogo(size: 28),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: const [
          PwaInstallButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x202563EB),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.purpleAccent.withOpacity(0.3) : Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
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
                      _ProfileStat(label: 'Care Circle', value: famCount),
                    ],
                  ),
                ],
              ),
            ),

            // Settings sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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

                  const SizedBox(height: 18),
                  const _SectionLabel(label: 'Application'),
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    subtitle: 'Medication alerts, refill reminders',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About CareSync',
                    subtitle: 'CareSync Healthcare PWA v2.0',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        backgroundColor: const Color(0xFFFEF2F2),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
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
      height: 32,
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
              letterSpacing: 1.1,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textLight),
      ),
    );
  }
}
