import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/user_session.dart';
import 'core/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await UserSession.loadSession();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: SmartServeApp(isLoggedIn: isLoggedIn),
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
      home: isLoggedIn
          ? CitizenHomeScreen(selectedLanguage: appState.language)
          : const LoginScreen(),
    );
  }
}