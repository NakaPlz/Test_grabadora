// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'mock_settings_service.dart';

void main() {
  testWidgets('App Header smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(settingsService: MockSettingsService()));

    // Verify that Splash Page shows up initially (or whatever Home is)
    // Since we have a SplashPage, we can look for that, or just generic check.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
