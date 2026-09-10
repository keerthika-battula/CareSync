import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresync/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CareSyncApp()));
    expect(find.byType(CareSyncApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
