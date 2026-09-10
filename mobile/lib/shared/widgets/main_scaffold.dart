import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (
      route: '/dashboard',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home'
    ),
    (
      route: '/medicines',
      icon: Icons.medication_outlined,
      selectedIcon: Icons.medication,
      label: 'Medicines'
    ),
    (
      route: '/appointments',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Appointments'
    ),
    (
      route: '/family',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
      label: 'Family'
    ),
    (
      route: '/documents',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: 'Documents'
    ),
    (
      route: '/profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile'
    ),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(_destinations[index].route);
        },
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
