import 'package:caresync/core/pwa/pwa_install_provider.dart';
import 'package:caresync/shared/widgets/pwa_install_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PWA Install Provider & Button Tests', () {
    test('PwaInstallState default values', () {
      const state = PwaInstallState();
      expect(state.isInstalled, isFalse);
      expect(state.canInstall, isFalse);
      expect(state.isPrompting, isFalse);
    });

    test('PwaInstallState copyWith operates correctly', () {
      const state = PwaInstallState();
      final updated = state.copyWith(isInstalled: true, canInstall: true, isPrompting: true);
      expect(updated.isInstalled, isTrue);
      expect(updated.canInstall, isTrue);
      expect(updated.isPrompting, isTrue);
    });

    testWidgets('PwaInstallButton renders gracefully in widget tree', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(
                  children: [
                    PwaInstallButton(),
                  ],
                ),
              ),
              body: Center(child: Text('Test Body')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test Body'), findsOneWidget);
    });
  });
}
