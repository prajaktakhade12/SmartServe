import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/localization/app_strings.dart';
import 'report_issue_screen.dart';
import 'citizen_dashboard_screen.dart';
import 'my_issues_screen.dart';
import 'notification_screen.dart';
import '../nearby/nearby_issues_screen.dart';
import '../civic/civic_points_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  final String selectedLanguage;
  const CitizenHomeScreen({super.key, required this.selectedLanguage}) ;

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;
  late String _lang;

  @override
  void initState() {
    super.initState();
    _lang = widget.selectedLanguage;
  }

  List<Widget> get _screens => [
    ReportIssueScreen(selectedLanguage: _lang),
    CitizenDashboardScreen(selectedLanguage: _lang),
    MyIssuesScreen(selectedLanguage: _lang),
    NotificationScreen(selectedLanguage: _lang),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.location_city_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Text(_getAppBarTitle(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]))),
        actions: [
          // Dark mode toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
            onPressed: () => appState.toggleDarkMode(),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),
          // Nearby Issues
          IconButton(
            icon: const Icon(Icons.location_on_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => NearbyIssuesScreen(selectedLanguage: _lang))),
            tooltip: 'Nearby Issues',
          ),
          // Civic Points
          IconButton(
            icon: const Icon(Icons.stars_rounded, color: Colors.amber),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CivicPointsScreen(selectedLanguage: _lang))),
            tooltip: 'Civic Points',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.edit_note_rounded),
            selectedIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.primary),
            label: AppStrings.text('report', _lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_rounded),
            selectedIcon: const Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
            label: AppStrings.text('dashboard', _lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_rounded),
            selectedIcon: const Icon(Icons.assignment_rounded, color: AppTheme.primary),
            label: AppStrings.text('my_issues', _lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_rounded),
            selectedIcon: const Icon(Icons.notifications_rounded, color: AppTheme.primary),
            label: AppStrings.text('notifications', _lang),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    const titles = ['Report Issue', 'Dashboard', 'My Issues', 'Notifications'];
    return titles[_currentIndex];
  }
}