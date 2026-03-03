import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF003c8f);
  static const Color accent = Color(0xFF42A5F5);
  static const Color reported = Color(0xFFFF7043);
  static const Color inProgress = Color(0xFFFFB300);
  static const Color completed = Color(0xFF43A047);
  static const Color background = Color(0xFFF5F7FA);
  static const Color sidebar = Color(0xFF1A237E);
  static const Color sidebarText = Color(0xFFB0BEC5);

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS': return inProgress;
      case 'COMPLETED': return completed;
      default: return reported;
    }
  }

  static Color getCategoryColor(String cat) {
    switch (cat.toUpperCase()) {
      case 'ROAD': return const Color(0xFF795548);
      case 'WATER': return const Color(0xFF0288D1);
      case 'ELECTRICITY': return const Color(0xFFF9A825);
      case 'SANITATION': return const Color(0xFF558B2F);
      case 'ENVIRONMENT': return const Color(0xFF2E7D32);
      case 'SAFETY': return const Color(0xFFC62828);
      case 'STREET_LIGHT': return const Color(0xFFF57F17);
      default: return const Color(0xFF546E7A);
    }
  }

  static IconData getCategoryIcon(String cat) {
    switch (cat.toUpperCase()) {
      case 'ROAD': return Icons.directions_car_rounded;
      case 'WATER': return Icons.water_drop_rounded;
      case 'ELECTRICITY': return Icons.flash_on_rounded;
      case 'SANITATION': return Icons.cleaning_services_rounded;
      case 'ENVIRONMENT': return Icons.eco_rounded;
      case 'SAFETY': return Icons.security_rounded;
      case 'STREET_LIGHT': return Icons.lightbulb_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }

  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: background,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}