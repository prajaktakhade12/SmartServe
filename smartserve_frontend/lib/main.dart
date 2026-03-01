import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/user_session.dart';
import 'core/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserSession.logout(); // Forces login screen every time
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SmartServeApp(isLoggedIn: false),
    ),
  );
}

class SmartServeApp extends StatelessWidget {
  final bool isLoggedIn;
  const SmartServeApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'SmartServe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}