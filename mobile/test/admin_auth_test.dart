import 'package:caresync/features/admin/data/models/admin_models.dart';
import 'package:caresync/features/auth/data/models/auth_models.dart';
import 'package:caresync/features/auth/presentation/providers/auth_provider.dart';
import 'package:caresync/features/family/data/models/public_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth & Role Models Test', () {
    test('UserModel parses ADMIN role correctly', () {
      final json = {
        'id': '1234-uuid',
        'email': 'admin@caresync.com',
        'firstName': 'Admin',
        'lastName': 'Super',
        'role': 'ADMIN',
        'active': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '1234-uuid');
      expect(user.fullName, 'Admin Super');
      expect(user.role, 'ADMIN');
      expect(user.isAdmin, isTrue);
      expect(user.isActive, isTrue);
    });

    test('UserModel parses USER role correctly', () {
      final json = {
        'id': 'user-uuid',
        'email': 'patient@caresync.com',
        'firstName': 'John',
        'lastName': 'Doe',
        'role': 'USER',
        'active': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.isAdmin, isFalse);
      expect(user.role, 'USER');
    });

    test('AuthState calculates permissions accurately', () {
      const emptyState = AuthState();
      expect(emptyState.isAuthenticated, isFalse);
      expect(emptyState.isAdmin, isFalse);

      final adminUser = UserModel(
        id: '1',
        email: 'admin@test.com',
        firstName: 'Adm',
        lastName: 'In',
        role: 'ADMIN',
      );

      final adminState = AuthState(user: adminUser, isInitialized: true);
      expect(adminState.isAuthenticated, isTrue);
      expect(adminState.isAdmin, isTrue);

      final regularUser = UserModel(
        id: '2',
        email: 'user@test.com',
        firstName: 'Reg',
        lastName: 'Ular',
        role: 'USER',
      );

      final regularState = AuthState(user: regularUser, isInitialized: true);
      expect(regularState.isAuthenticated, isTrue);
      expect(regularState.isAdmin, isFalse);
    });
  });

  group('Admin Models Test', () {
    test('AdminUser parses json correctly', () {
      final json = {
        'id': 'u1',
        'email': 'test@caresync.com',
        'firstName': 'Jane',
        'lastName': 'Doe',
        'phoneNumber': '+1234567890',
        'role': 'ADMIN',
        'active': true,
        'emailVerified': true,
        'createdAt': '2026-09-09T20:00:00.000',
      };

      final adminUser = AdminUser.fromJson(json);
      expect(adminUser.id, 'u1');
      expect(adminUser.fullName, 'Jane Doe');
      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.phoneNumber, '+1234567890');
      expect(adminUser.isEmailVerified, isTrue);
      expect(adminUser.createdAt, isNotNull);
    });

    test('AdminUserHealthcareOverview parses counts correctly', () {
      final json = {
        'data': {
          'userId': 'u1',
          'familyMembersCount': 3,
          'activeMedicinesCount': 5,
          'upcomingAppointmentsCount': 2,
          'totalDocumentsCount': 7,
        }
      };

      final overview = AdminUserHealthcareOverview.fromJson(json);
      expect(overview.userId, 'u1');
      expect(overview.familyMembersCount, 3);
      expect(overview.activeMedicinesCount, 5);
      expect(overview.upcomingAppointmentsCount, 2);
      expect(overview.totalDocumentsCount, 7);
    });

    test('AdminCreateUserRequest builds payload correctly', () {
      final req = AdminCreateUserRequest(
        firstName: 'Bob',
        lastName: 'Smith',
        email: 'bob@caresync.com',
        password: 'Password123!',
        role: 'USER',
      );

      final map = req.toJson();
      expect(map['firstName'], 'Bob');
      expect(map['lastName'], 'Smith');
      expect(map['email'], 'bob@caresync.com');
      expect(map['password'], 'Password123!');
      expect(map['role'], 'USER');
    });

    test('PublicUserName parses displayName only and has no sensitive fields', () {
      final json = {
        'displayName': 'Alice Patient',
        'email': 'secret@caresync.com',
        'role': 'USER',
      };

      final publicUser = PublicUserName.fromJson(json);
      expect(publicUser.displayName, 'Alice Patient');
    });
  });
}
