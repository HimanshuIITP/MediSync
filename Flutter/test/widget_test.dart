// test/widget_test.dart
// Basic smoke test — verifies the app starts without crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:medapp/main.dart';

void main() {
  testWidgets('MedApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MedApp());
    expect(find.text('MedAssist'), findsOneWidget);
  });
}
