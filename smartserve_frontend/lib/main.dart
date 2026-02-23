import 'package:flutter/material.dart';
import 'core/user_session.dart';
import 'screens/login_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clear old session so login screen always shows fresh
  await UserSession.logout();
  runApp(const SmartServeApp());
}

class SmartServeApp extends StatelessWidget {
  const SmartServeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartServe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}