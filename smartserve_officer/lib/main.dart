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

class SmartServeOfficerApp extends StatefulWidget {
  final bool isLoggedIn;
  const SmartServeOfficerApp({super.key, required this.isLoggedIn});

  @override
  State<SmartServeOfficerApp> createState() => _SmartServeOfficerAppState();
}

class _SmartServeOfficerAppState extends State<SmartServeOfficerApp> {
  String _language = 'en'; // 'en', 'hi', 'mr'

  void _onLanguageChanged(String lang) {
    setState(() => _language = lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartServe Officer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: widget.isLoggedIn
          ? HomeScreen(
              language: _language,
              onLanguageChanged: _onLanguageChanged,
            )
          : LoginScreen(
              onLanguageChanged: _onLanguageChanged,
              language: _language,
            ),
    );
  }
}