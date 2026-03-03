import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'issues_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _notifCount = 0;

  final _screens = const [
    DashboardScreen(),
    IssuesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifCount();
  }

  Future<void> _loadNotifCount() async {
    final notifs = await ApiService.getOfficerNotifications(OfficerSession.category ?? '');
    setState(() => _notifCount = notifs.length);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirm == true) {
      await OfficerSession.logout();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHead = OfficerSession.isHead;
    final category = OfficerSession.category ?? '';
    final name = OfficerSession.name ?? '';

    final navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.assignment_rounded, 'label': 'Issues'},
      {'icon': Icons.notifications_rounded, 'label': 'Alerts'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Scaffold(
      body: Row(children: [
        Container(
          width: 240,
          color: AppTheme.sidebar,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black.withOpacity(0.2),
              child: Column(children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primary,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'O',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHead ? Colors.amber.withOpacity(0.3) : AppTheme.getCategoryColor(category).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isHead ? Icons.stars_rounded : AppTheme.getCategoryIcon(category),
                        color: isHead ? Colors.amber : AppTheme.getCategoryColor(category), size: 14),
                    const SizedBox(width: 6),
                    Text(isHead ? 'Head Officer' : '\${_formatCat(category)} Officer',
                        style: TextStyle(
                            color: isHead ? Colors.amber : AppTheme.getCategoryColor(category),
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            ...List.generate(navItems.length, (i) {
              final item = navItems[i];
              final selected = _selectedIndex == i;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Material(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () { setState(() => _selectedIndex = i); if (i == 2) _loadNotifCount(); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Stack(children: [
                          Icon(item['icon'] as IconData,
                              color: selected ? Colors.white : AppTheme.sidebarText, size: 22),
                          if (i == 2 && _notifCount > 0)
                            Positioned(right: 0, top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text('\$_notifCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              )),
                        ]),
                        const SizedBox(width: 14),
                        Text(item['label'] as String,
                            style: TextStyle(
                                color: selected ? Colors.white : AppTheme.sidebarText,
                                fontSize: 15,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      ]),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: AppTheme.sidebarText, size: 20),
                  title: Text('SmartServe v1.0', style: TextStyle(color: AppTheme.sidebarText, fontSize: 12)),
                  dense: true,
                ),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _logout,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                        SizedBox(width: 14),
                        Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ]),
        ),
        Expanded(child: _screens[_selectedIndex]),
      ]),
    );
  }

  String _formatCat(String cat) {
    if (cat == 'STREET_LIGHT') return 'Street Light';
    if (cat.isEmpty) return '';
    return cat[0] + cat.substring(1).toLowerCase();
  }
}
