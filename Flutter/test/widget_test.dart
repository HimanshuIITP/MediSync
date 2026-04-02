// test/widget_test.dart
// Basic smoke test – verifies the app starts without crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:medapp/main.dart';

void main() {
  testWidgets('MediSync smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediSyncApp());
    expect(find.text('MediSync'), findsOneWidget);
  });
}
