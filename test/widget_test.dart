// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chaos/main.dart';
import 'package:chaos/providers/theme_provider.dart';
import 'package:chaos/providers/settings_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Chaos app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MyApp(isFirstLaunch: true),
      ),
    );

    // Build our app and trigger a frame with providers
    await tester.pump(const Duration(seconds: 1));

    // Verify that welcome screen characters are there
    // Since each character is a separate Text widget, we check for 'C', 'h', 'a', 'o', 's'
    expect(find.text('C'), findsOneWidget);
    expect(find.text('h'), findsOneWidget);
  });
}
