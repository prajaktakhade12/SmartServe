import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF003c8f);
  static const Color primaryLight = Color(0xFF5e92f3);
  static const Color accent = Color(0xFFFF6F00);
  static const Color accentLight = Color(0xFFFFBF40);

  // Status Colors
  static const Color reported = Color(0xFFEF5350);
  static const Color inProgress = Color(0xFFFFA726);
  static const Color completed = Color(0xFF66BB6A);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'ROAD': Color(0xFF78909C),
    'WATER': Color(0xFF29B6F6),
    'ELECTRICITY': Color(0xFFFFCA28),
    'SANITATION': Color(0xFF8D6E63),
    'ENVIRONMENT': Color(0xFF66BB6A),
    'SAFETY': Color(0xFFEF5350),
    'STREET_LIGHT': Color(0xFFFFEE58),
    'OTHER': Color(0xFFAB47BC),
  };

  static Color getCategoryColor(String cat) =>
      categoryColors[cat.toUpperCase()] ?? const Color(0xFFAB47BC);

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REPORTED': return reported;
      case 'IN_PROGRESS': return inProgress;
      case 'COMPLETED': return completed;
      default: return Colors.grey;
    }
  }

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        fontFamily: 'Roboto',
      );
}