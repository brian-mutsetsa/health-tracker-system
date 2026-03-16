import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/home_screen.dart';
import 'models/checkin_model.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notifications
  await NotificationService().init();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CheckinModelAdapter());
  await Hive.openBox<CheckinModel>('checkins');
  await Hive.openBox('settings');

  runApp(const HealthTrackerApp());
}

class HealthTrackerApp extends StatelessWidget {
  const HealthTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    final bool isLoggedIn = settingsBox.get('is_logged_in', defaultValue: false);

    return MaterialApp(
      title: 'Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: SplashScreen(isLoggedIn: isLoggedIn),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/tutorial': (context) => const TutorialScreen(),
      },
    );
  }
}
