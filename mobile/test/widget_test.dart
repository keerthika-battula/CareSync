import 'package:flutter_test/flutter_test.dart';
import 'package:caresync/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const CareSyncApp());
    expect(find.byType(CareSyncApp), findsOneWidget);
  });
}
