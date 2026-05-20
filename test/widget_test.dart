import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chaos/screens/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    await tester.pump(const Duration(milliseconds: 100));

    // Welcome screen renders individual characters of "Chaos".
    expect(find.text('C'), findsOneWidget);
    expect(find.text('h'), findsOneWidget);
  });
}
