import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/localization/app_strings.dart';
import '../../theme/app_theme.dart';
import 'report_issue_screen.dart';
import 'citizen_dashboard_screen.dart';
import 'my_issues_screen.dart';
import 'notification_screen.dart';
import '../nearby/nearby_issues_screen.dart';
import '../civic/civic_points_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  final String selectedLanguage;
  const CitizenHomeScreen({Key? key, required this.selectedLanguage}) : super(key: key);

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;

  void _showLanguageDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.language_rounded, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(AppStrings.text('select_language', appState.language)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langOption(context, appState, 'English', 'en'),
            const SizedBox(height: 10),
            _langOption(context, appState, 'हिंदी', 'hi'),
            const SizedBox(height: 10),
            _langOption(context, appState, 'मराठी', 'mr'),
          ],
        ),
      ),
    );
  }

  Widget _langOption(BuildContext context, AppState appState, String label, String code) {
    final isSelected = appState.language == code;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          appState.changeLanguage(code);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primary : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isSelected) ...[
            const Icon(Icons.check_circle_rounded, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final isDark = appState.isDarkMode;

    final screens = [
      ReportIssueScreen(selectedLanguage: lang),
      CitizenDashboardScreen(selectedLanguage: lang),
      MyIssuesScreen(selectedLanguage: lang),
      NotificationScreen(selectedLanguage: lang),
    ];

    final titles = [
      AppStrings.text('report_issue', lang),
      AppStrings.text('dashboard', lang),
      AppStrings.text('my_issues', lang),
      AppStrings.text('notifications', lang),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.location_city_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Text(titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]))),
        actions: [
          // Language toggle
          IconButton(
            icon: const Icon(Icons.language_rounded, color: Colors.white),
            onPressed: () => _showLanguageDialog(context, appState),
            tooltip: AppStrings.text('change_language', lang),
          ),
          // Dark mode toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white),
            onPressed: () => appState.toggleDarkMode(),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),
          // Nearby Issues
          IconButton(
            icon: const Icon(Icons.location_on_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => NearbyIssuesScreen(selectedLanguage: lang))),
            tooltip: 'Nearby Issues',
          ),
          // Civic Points
          IconButton(
            icon: const Icon(Icons.stars_rounded, color: Colors.amber),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CivicPointsScreen(selectedLanguage: lang))),
            tooltip: 'Civic Points',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.edit_note_rounded),
            selectedIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.primary),
            label: AppStrings.text('report', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_rounded),
            selectedIcon: const Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
            label: AppStrings.text('dashboard', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_rounded),
            selectedIcon: const Icon(Icons.assignment_rounded, color: AppTheme.primary),
            label: AppStrings.text('my_issues', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_rounded),
            selectedIcon: const Icon(Icons.notifications_rounded, color: AppTheme.primary),
            label: AppStrings.text('notifications', lang),
          ),
        ],
      ),
    );
  }
}