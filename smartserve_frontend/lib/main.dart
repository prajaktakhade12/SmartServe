import 'package:flutter/material.dart';
import 'screens/language/language_selection_screen.dart';
import 'theme/app_theme.dart';

void main() {
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
      home: const LanguageSelectionScreen(),
    );
  }
}