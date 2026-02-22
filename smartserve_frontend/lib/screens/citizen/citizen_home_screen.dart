import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../theme/app_theme.dart';
import 'report_issue_screen.dart';
import 'citizen_dashboard_screen.dart';
import 'my_issues_screen.dart';
import 'notification_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  final String selectedLanguage;

  const CitizenHomeScreen({Key? key, required this.selectedLanguage})
      : super(key: key);

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ReportIssueScreen(selectedLanguage: widget.selectedLanguage),
      CitizenDashboardScreen(selectedLanguage: widget.selectedLanguage),
      MyIssuesScreen(selectedLanguage: widget.selectedLanguage),
      NotificationScreen(selectedLanguage: widget.selectedLanguage),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.selectedLanguage;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.grey.shade500,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.report_problem_outlined),
              activeIcon: const Icon(Icons.report_problem_rounded),
              label: AppStrings.text("report", lang),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard_rounded),
              label: AppStrings.text("dashboard", lang),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt_outlined),
              activeIcon: const Icon(Icons.list_alt_rounded),
              label: AppStrings.text("my_issues", lang),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_outlined),
              activeIcon: const Icon(Icons.notifications_rounded),
              label: AppStrings.text("notifications", lang),
            ),
          ],
        ),
      ),
    );
  }
}