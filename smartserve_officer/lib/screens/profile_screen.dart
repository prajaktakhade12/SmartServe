import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getOfficerDashboard(OfficerSession.category ?? '');
    setState(() { _stats = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final name = OfficerSession.name ?? '';
    final username = OfficerSession.username ?? '';
    final category = OfficerSession.category ?? '';
    final role = OfficerSession.role ?? '';
    final isHead = OfficerSession.isHead;
    final catColor = isHead ? Colors.amber : AppTheme.getCategoryColor(category);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('My Profile', style: TextStyle(fontSize: 28,
                    fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                Text('Your account details and performance',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 28),

                // Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Row(children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: catColor.withOpacity(0.15),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'O',
                            style: TextStyle(fontSize: 40,
                                fontWeight: FontWeight.bold, color: catColor)),
                      ),
                      const SizedBox(width: 28),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontSize: 24,
                            fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.account_circle_rounded,
                              size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text('@$username',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        ]),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: catColor.withOpacity(0.3))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(isHead ? Icons.stars_rounded
                                : AppTheme.getCategoryIcon(category),
                                color: catColor, size: 16),
                            const SizedBox(width: 8),
                            Text(isHead ? 'Head Officer — All Categories'
                                : '${_formatCat(category)} Department Officer',
                                style: TextStyle(color: catColor,
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(role.toUpperCase(),
                              style: const TextStyle(color: AppTheme.primary,
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ])),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Performance Stats
                const Text('Performance Stats', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark)),
                const SizedBox(height: 14),
                Row(children: [
                  _statBox('Total Issues', '${_stats['total'] ?? 0}',
                      Icons.list_alt_rounded, AppTheme.primary),
                  const SizedBox(width: 16),
                  _statBox('Pending', '${_stats['reported'] ?? 0}',
                      Icons.flag_rounded, AppTheme.reported),
                  const SizedBox(width: 16),
                  _statBox('In Progress', '${_stats['in_progress'] ?? 0}',
                      Icons.pending_rounded, AppTheme.inProgress),
                  const SizedBox(width: 16),
                  _statBox('Resolved', '${_stats['completed'] ?? 0}',
                      Icons.check_circle_rounded, AppTheme.completed),
                ]),
                const SizedBox(height: 20),

                // Resolution Rate
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Resolution Rate', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark)),
                      const SizedBox(height: 16),
                      Builder(builder: (_) {
                        final total = (_stats['total'] ?? 0) as int;
                        final completed = (_stats['completed'] ?? 0) as int;
                        final pct = total > 0 ? completed / total : 0.0;
                        return Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                            Text('$completed of $total issues resolved',
                                style: TextStyle(color: Colors.grey.shade600)),
                            Text('${(pct * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    color: AppTheme.completed,
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ]),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pct, minHeight: 16,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.completed),
                            ),
                          ),
                        ]);
                      }),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Account Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Account Information', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark)),
                      const SizedBox(height: 16),
                      _infoRow(Icons.badge_rounded, 'Full Name', name),
                      _infoRow(Icons.account_circle_rounded, 'Username', username),
                      _infoRow(Icons.category_rounded, 'Department',
                          isHead ? 'All Categories (Head)' : _formatCat(category)),
                      _infoRow(Icons.admin_panel_settings_rounded, 'Role',
                          role[0].toUpperCase() + role.substring(1)),
                    ]),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 30,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600,
              fontSize: 12), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 14),
        SizedBox(width: 120,
            child: Text(label, style: TextStyle(
                color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: const TextStyle(
            fontWeight: FontWeight.w600))),
      ]),
    );
  }

  String _formatCat(String cat) {
    if (cat == 'STREET_LIGHT') return 'Street Light';
    if (cat.isEmpty) return '';
    return cat[0] + cat.substring(1).toLowerCase();
  }
}
