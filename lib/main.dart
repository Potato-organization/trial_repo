import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigation.dart';
import 'services/background_service.dart';
import 'services/alarm_service.dart';
import 'services/iap_service.dart';
import 'services/audio/audio_player_service.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService.initialize();
  await AlarmService.initialize();
  IAPService().initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('first_launch') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        Provider<AudioPlayerService>(
          create: (_) => AudioPlayerService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MyApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, SettingsProvider>(
      builder: (context, themeProvider, settingsProvider, _) {
        // Show a minimal splash while providers load from SharedPreferences.
        if (themeProvider.isLoading || settingsProvider.isLoading) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: AppConstants.backgroundColor,
              body: const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'Chaos',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getThemeData().copyWith(
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: isFirstLaunch ? const WelcomeScreen() : const MainNavigation(),
        );
      },
    );
  }
}
