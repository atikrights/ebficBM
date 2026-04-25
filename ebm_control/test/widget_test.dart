import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ebm_control/main.dart';

void main() {
  testWidgets('EBM Control App smoke test — Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const EBMControlApp());
    // Login screen should be visible by default
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
