import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker_v1/main.dart';

void main() {
  testWidgets('Health Tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HealthTrackerApp());

    // Verify that the condition selection screen shows up
    expect(find.text('Select Your Condition'), findsOneWidget);
    expect(find.text('Hypertension'), findsOneWidget);
    expect(find.text('Diabetes'), findsOneWidget);
  });
}