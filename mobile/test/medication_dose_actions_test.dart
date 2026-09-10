import 'package:caresync/features/reminders/data/models/reminder_models.dart';
import 'package:caresync/features/reminders/presentation/widgets/medicine_dose_card.dart';
import 'package:caresync/features/reminders/presentation/widgets/snooze_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('Medication Dose Actions UI Tests', () {
    testWidgets('Displays MedicineDoseCard with Taken, Skip, Snooze for pending dose', (tester) async {
      final dose = ReminderOccurrenceModel(
        id: 'dose-123',
        medicineId: 'med-123',
        medicineName: 'Amoxicillin',
        dosage: '500mg • Once daily',
        currentStock: 30,
        refillThreshold: 7,
        scheduledTime: DateTime.now().toIso8601String(),
        status: 'PENDING',
        snoozeCount: 0,
      );

      await tester.pumpWidget(createTestWidget(MedicineDoseCard(dose: dose)));
      await tester.pumpAndSettle();

      expect(find.text('Amoxicillin'), findsOneWidget);
      expect(find.text('500mg • Once daily'), findsOneWidget);
      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.textContaining('Stock: 30'), findsOneWidget);
    });

    testWidgets('Displays Taken status and hides action buttons when dose is TAKEN', (tester) async {
      final dose = ReminderOccurrenceModel(
        id: 'dose-123',
        medicineId: 'med-123',
        medicineName: 'Metformin',
        dosage: '850mg',
        currentStock: 29,
        refillThreshold: 7,
        scheduledTime: DateTime.now().toIso8601String(),
        actionTime: DateTime.now().toIso8601String(),
        status: 'TAKEN',
        snoozeCount: 0,
      );

      await tester.pumpWidget(createTestWidget(MedicineDoseCard(dose: dose)));
      await tester.pumpAndSettle();

      expect(find.text('Metformin'), findsOneWidget);
      expect(find.textContaining('Taken at'), findsOneWidget);
      expect(find.text('Taken'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Snooze'), findsNothing);
      expect(find.textContaining('Stock: 29'), findsOneWidget);
    });

    testWidgets('Displays Snoozed status and keeps action buttons when dose is SNOOZED', (tester) async {
      final snoozedTime = DateTime.now().add(const Duration(minutes: 15)).toIso8601String();
      final dose = ReminderOccurrenceModel(
        id: 'dose-123',
        medicineId: 'med-123',
        medicineName: 'Lisinopril',
        dosage: '10mg',
        currentStock: 30,
        refillThreshold: 7,
        scheduledTime: DateTime.now().toIso8601String(),
        snoozedUntil: snoozedTime,
        status: 'SNOOZED',
        snoozeCount: 1,
      );

      await tester.pumpWidget(createTestWidget(MedicineDoseCard(dose: dose)));
      await tester.pumpAndSettle();

      expect(find.text('Lisinopril'), findsOneWidget);
      expect(find.textContaining('Snoozed until'), findsOneWidget);
      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.textContaining('Stock: 30'), findsOneWidget);
    });

    testWidgets('SnoozeDialog presents 15 minutes and 30 minutes options', (tester) async {
      int? selectedMinutes;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedMinutes = await SnoozeDialog.show(context, 'Atorvastatin');
                },
                child: const Text('Open Snooze'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Snooze'));
      await tester.pumpAndSettle();

      expect(find.text('Snooze reminder'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);

      await tester.tap(find.text('15 minutes'));
      await tester.pumpAndSettle();

      expect(selectedMinutes, 15);
    });
  });
}
