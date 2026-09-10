import 'package:caresync/features/appointments/presentation/screens/appointments_screen.dart';
import 'package:caresync/features/auth/presentation/screens/login_screen.dart';
import 'package:caresync/features/auth/presentation/screens/register_screen.dart';
import 'package:caresync/features/auth/presentation/screens/splash_screen.dart';
import 'package:caresync/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:caresync/features/documents/presentation/screens/documents_screen.dart';
import 'package:caresync/features/family/presentation/screens/family_screen.dart';
import 'package:caresync/features/medicines/presentation/screens/medicines_screen.dart';
import 'package:caresync/features/profile/presentation/screens/profile_screen.dart';
import 'package:caresync/shared/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/medicines',
            name: 'medicines',
            builder: (context, state) => const MedicinesScreen(),
          ),
          GoRoute(
            path: '/appointments',
            name: 'appointments',
            builder: (context, state) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/family',
            name: 'family',
            builder: (context, state) => const FamilyScreen(),
          ),
          GoRoute(
            path: '/documents',
            name: 'documents',
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
