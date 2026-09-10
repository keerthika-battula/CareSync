import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/auth/presentation/providers/auth_provider.dart';
import 'package:caresync/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _NavDestination {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _baseDestinations = [
    _NavDestination(
      route: '/dashboard',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    _NavDestination(
      route: '/medicines',
      icon: Icons.medication_outlined,
      selectedIcon: Icons.medication,
      label: 'Medicines',
    ),
    _NavDestination(
      route: '/appointments',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Appointments',
    ),
    _NavDestination(
      route: '/family',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
      label: 'Family',
    ),
    _NavDestination(
      route: '/documents',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: 'Documents',
    ),
    _NavDestination(
      route: '/profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  static const _adminDestination = _NavDestination(
    route: '/admin',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings,
    label: 'Admin',
  );

  List<_NavDestination> _getDestinations(bool isAdmin) {
    if (isAdmin) {
      return [..._baseDestinations, _adminDestination];
    }
    return _baseDestinations;
  }

  int _getCurrentIndex(BuildContext context, List<_NavDestination> destinations) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isAdmin;
    final destinations = _getDestinations(isAdmin);
    final currentIndex = _getCurrentIndex(context, destinations);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left Desktop Sidebar
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                children: [
                  // App Brand
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: AppLogo(
                      size: 38,
                      subtitle: 'Healthcare Platform',
                    ),
                  ),

                  // Role Badge if Admin
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withOpacity(0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'ADMINISTRATOR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Navigation Links
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final dest = destinations[index];
                        final isSelected = currentIndex == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (dest.route == '/admin'
                                    ? Colors.purple.withOpacity(0.12)
                                    : AppColors.primary.withOpacity(0.1))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              isSelected ? dest.selectedIcon : dest.icon,
                              color: isSelected
                                  ? (dest.route == '/admin' ? Colors.purple : AppColors.primary)
                                  : AppColors.textSecondary,
                            ),
                            title: Text(
                              dest.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? (dest.route == '/admin'
                                        ? Colors.purple
                                        : AppColors.primaryDark)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onTap: () => context.go(dest.route),
                          ),
                        );
                      },
                    ),
                  ),

                  // Footer / User Profile
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isAdmin
                              ? Colors.purple.withOpacity(0.15)
                              : AppColors.primaryLight.withOpacity(0.2),
                          child: Text(
                            authState.user?.firstName.isNotEmpty == true
                                ? authState.user!.firstName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isAdmin ? Colors.purple : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.user?.fullName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authState.user?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Logout',
                          icon: const Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile / Tablet View
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(destinations[index].route);
        },
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(
                  d.selectedIcon,
                  color: d.route == '/admin' ? Colors.purple : AppColors.primary,
                ),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
