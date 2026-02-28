import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAu9O3rc9wznjy6eiFaZFiFZOGQBBsjnt8",
      authDomain: "health-tracker-zw.firebaseapp.com",
      projectId: "health-tracker-zw",
      storageBucket: "health-tracker-zw.firebasestorage.app",
      messagingSenderId: "557640477933",
      appId: "1:557640477933:web:c5016117b0c6abfe5b70e4"
    ),
  );
  
  runApp(const HealthTrackerProviderApp());
}

class HealthTrackerProviderApp extends StatelessWidget {
  const HealthTrackerProviderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Tracker - Provider Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}