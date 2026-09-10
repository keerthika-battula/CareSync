import 'package:caresync/features/auth/presentation/screens/login_screen.dart';
import 'package:caresync/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Forgot Password UI & Validation Tests', () {
    testWidgets('LoginScreen displays Email or Username field', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pump();

      expect(find.text('Email or Username'), findsOneWidget);
    });

    testWidgets('LoginScreen displays Forgot Password link', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pump();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Tapping Forgot Password opens ForgotPasswordDialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pump();

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordDialog), findsOneWidget);
      expect(find.text('Send Reset Code'), findsOneWidget);
      expect(find.text('Registered Email'), findsOneWidget);
    });

    testWidgets('ForgotPasswordDialog validates email field on submit', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: ForgotPasswordDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Send Reset Code without entering email
      await tester.tap(find.text('Send Reset Code'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'notanemail');
      await tester.tap(find.text('Send Reset Code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('ForgotPasswordDialog step 1 pre-fills with initialEmail', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: ForgotPasswordDialog(initialEmail: 'user@caresync.com'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('user@caresync.com'), findsOneWidget);
    });
  });
}
