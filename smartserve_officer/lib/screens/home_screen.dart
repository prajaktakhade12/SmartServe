import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../core/officer_strings.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'issues_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'team_screen.dart';
import 'directory_screen.dart';

class HomeScreen extends StatefulWidget {
  final String language;
  final void Function(String) onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _alertCount = 0;
  late String _lang; // local copy — rebuilds instantly on tap

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
    _initAlertCount();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() => _lang = widget.language);
    }
  }

  void _changeLanguage(String code) {
    setState(() => _lang = code);   // instant local rebuild
    widget.onLanguageChanged(code); // propagate to root
  }

  Future<void> _loadAlertCount() async {
    // Only count NEW issues (reported in last 24 hours) for the badge
    // Once the officer opens the Alerts tab, badge clears to 0
    if (_alertCount == 0) return; // already cleared — don't re-add
    try {
      final result = await ApiService.getOfficerNotifications(
        OfficerSession.category ?? '',
        officerId: OfficerSession.id,
        role: OfficerSession.role ?? '',
      );
      if (result is List && _alertCount != 0) {
        setState(() => _alertCount = result.length);
      }
    } catch (_) {}
  }

  Future<void> _initAlertCount() async {
    // Called only once on login — sets the initial badge count
    try {
      final result = await ApiService.getOfficerNotifications(
        OfficerSession.category ?? '',
        officerId: OfficerSession.id,
        role: OfficerSession.role ?? '',
      );
      if (result is List) {
        setState(() => _alertCount = result.length);
      }
    } catch (_) {}
  }

  List<_NavItem> get _navItems {
    final s = _lang;
    final showTeam = OfficerSession.role == 'dept_head' ||
        OfficerSession.role == 'head';

    return [
      _NavItem(Icons.dashboard_rounded, OfficerStrings.text('dashboard', s), 0),
      _NavItem(Icons.list_alt_rounded, OfficerStrings.text('issues', s), 1),
      _NavItem(Icons.notifications_rounded, OfficerStrings.text('alerts', s), 2,
          badge: _alertCount),
      _NavItem(Icons.person_rounded, OfficerStrings.text('profile', s), 3),
      if (showTeam)
        _NavItem(Icons.groups_rounded, OfficerStrings.text('my_team', s), 4),
      if (OfficerSession.isHead)
        _NavItem(Icons.contacts_rounded,
            _lang == 'hi' ? 'निर्देशिका' : _lang == 'mr' ? 'निर्देशिका' : 'Directory', 5),
    ];
  }

  Widget _currentScreen() {
    final lang = _lang;
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(language: lang);
      case 1:
        return IssuesScreen(language: lang);
      case 2:
        // NotificationsScreen — updated to accept language ✅
        return NotificationsScreen(language: lang);
      case 3:
        return ProfileScreen(language: lang);
      case 4:
        // TeamScreen — new screen, accepts language ✅
        return TeamScreen(language: lang);
      case 5:
        return DirectoryScreen(language: lang);
      default:
        return DashboardScreen(language: lang);
    }
  }

  void _logout() async {
    await OfficerSession.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          language: _lang,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(children: [
        // ── Sidebar ───────────────────────────────────────────────────────────
        Container(
          width: 220,
          color: AppTheme.sidebar,
          child: Column(children: [
            // Logo / App name
            Container(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text('SmartServe',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ]),
                  const SizedBox(height: 16),
                  Text(OfficerSession.name ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(OfficerSession.designation ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      _formatCategory(OfficerSession.category ?? ''),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10)),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                children: _navItems.map((item) {
                  final selected = _selectedIndex == item.index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedIndex = item.index;
                          // Clear alert badge when officer opens Alerts tab
                          if (item.index == 2) _alertCount = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? Colors.white.withOpacity(0.3)
                                : Colors.transparent),
                        ),
                        child: Row(children: [
                          Stack(children: [
                            Icon(item.icon,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.sidebarText,
                                size: 20),
                            if (item.badge > 0)
                              Positioned(
                                top: -2, right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  constraints: const BoxConstraints(
                                      minWidth: 14, minHeight: 14),
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: Text(
                                    item.badge > 99
                                        ? '99+'
                                        : '${item.badge}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ]),
                          const SizedBox(width: 12),
                          Text(item.label,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppTheme.sidebarText,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              )),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // ── Language Toggle ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      OfficerStrings.text('language', lang),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          letterSpacing: 0.8),
                    ),
                  ),
                  Row(children: [
                    _langBtn('en', 'EN', lang),
                    const SizedBox(width: 4),
                    _langBtn('hi', 'हि', lang),
                    const SizedBox(width: 4),
                    _langBtn('mr', 'म', lang),
                  ]),
                ],
              ),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Icon(Icons.logout_rounded,
                        color: Colors.red.shade300, size: 20),
                    const SizedBox(width: 12),
                    Text(OfficerStrings.text('logout', lang),
                        style: TextStyle(
                            color: Colors.red.shade300, fontSize: 14)),
                  ]),
                ),
              ),
            ),
          ]),
        ),

        // ── Main Content ──────────────────────────────────────────────────────
        Expanded(child: _currentScreen()),
      ]),
    );
  }

  Widget _langBtn(String code, String label, String currentLang) {
    final selected = currentLang == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeLanguage(code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? Colors.white.withOpacity(0.5)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              )),
        ),
      ),
    );
  }

  String _formatCategory(String cat) {
    return OfficerStrings.category(cat, _lang);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  final int badge;
  const _NavItem(this.icon, this.label, this.index, {this.badge = 0});
}