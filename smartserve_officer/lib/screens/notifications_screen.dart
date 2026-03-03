import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'issues_screen.dart';
import 'issue_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getOfficerNotifications(OfficerSession.category ?? '');
    setState(() { _notifs = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Alerts', style: TextStyle(fontSize: 28,
                  fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
              Text('Recent issues assigned to you',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ]),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ]),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notifs.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No new alerts', style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                      ]))
                    : ListView.separated(
                        itemCount: _notifs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final n = _notifs[i];
                          final status = n['status'] ?? 'REPORTED';
                          final statusColor = AppTheme.getStatusColor(status);
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.assignment_rounded,
                                    color: statusColor, size: 24)),
                              title: Text(n['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10)),
                                    child: Text(status.replaceAll('_', ' '),
                                        style: TextStyle(color: statusColor,
                                            fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(n['created_at'] ?? '',
                                      style: TextStyle(color: Colors.grey.shade500,
                                          fontSize: 12)),
                                ]),
                              ]),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16, color: AppTheme.primary),
                              onTap: () async {
                                final detail = await ApiService.getIssueDetail(n['id']);
                                if (!context.mounted) return;
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => IssueDetailScreen(
                                      issue: Map<String, dynamic>.from(detail),
                                      onUpdated: _load)));
                              },
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}
