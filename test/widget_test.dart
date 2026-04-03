import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chaos/main.dart';
import 'package:chaos/providers/theme_provider.dart';
import 'package:chaos/providers/settings_provider.dart';
import 'package:chaos/services/audio/audio_player_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Chaos app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          Provider<AudioPlayerService>(
            create: (_) => AudioPlayerService(),
            dispose: (_, s) => s.dispose(),
          ),
        ],
        child: const MyApp(isFirstLaunch: true),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Welcome screen renders individual characters of "Chaos".
    expect(find.text('C'), findsOneWidget);
    expect(find.text('h'), findsOneWidget);
  });
}

