import 'package:flutter/material.dart';
import 'core/officer_session.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await OfficerSession.loadSession();
  runApp(SmartServeOfficerApp(isLoggedIn: isLoggedIn));
}

class SmartServeOfficerApp extends StatelessWidget {
  final bool isLoggedIn;
  const SmartServeOfficerApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartServe Officer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
