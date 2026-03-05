import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/tutorial_screen.dart';
import 'screens/home_screen.dart';
import 'models/checkin_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CheckinModelAdapter());
  await Hive.openBox<CheckinModel>('checkins');
  await Hive.openBox('settings');

  runApp(const HealthTrackerApp());
}

class HealthTrackerApp extends StatelessWidget {
  const HealthTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    final bool hasSeenTutorial = settingsBox.get(
      'has_seen_tutorial',
      defaultValue: false,
    );

    return MaterialApp(
      title: 'Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: hasSeenTutorial ? const HomeScreen() : const TutorialScreen(),
    );
  }
}
