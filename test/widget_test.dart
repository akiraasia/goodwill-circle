// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:goodwill_circle/features/landing/landing_screen.dart';

void main() {
  testWidgets('Goodwill Circle landing builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    await tester.pump();

    expect(find.textContaining('Goodwill Circle'), findsWidgets);
    expect(find.textContaining('Kindness'), findsOneWidget);
  });
}
