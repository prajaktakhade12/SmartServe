import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../core/officer_strings.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'issue_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String language;
  const NotificationsScreen({super.key, required this.language});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  String get _lang => widget.language;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getOfficerNotifications(
      OfficerSession.category ?? '',
      officerId: OfficerSession.id,
      role: OfficerSession.role ?? '',
    );
    setState(() {
      _notifs  = data is List ? data : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      OfficerStrings.text('alerts_title', _lang),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark),
                    ),
                    Text(
                      OfficerStrings.text('alerts_subtitle', _lang),
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(OfficerStrings.text('refresh', _lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                  Icons.notifications_none_rounded,
                                  size: 80,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                OfficerStrings.text(
                                    'no_alerts', _lang),
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _notifs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final n = _notifs[i];
                            final status =
                                n['status'] ?? 'REPORTED';
                            final statusColor =
                                AppTheme.getStatusColor(status);
                            return Card(
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12),
                                leading: Container(
                                  padding:
                                      const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                  child: Icon(
                                      Icons.assignment_rounded,
                                      color: statusColor,
                                      size: 24),
                                ),
                                title: Text(
                                  n['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 8,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10)),
                                        child: Text(
                                          // Use translated status
                                          OfficerStrings.status(
                                              status, _lang),
                                          style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        n['created_at'] ?? '',
                                        style: TextStyle(
                                            color:
                                                Colors.grey.shade500,
                                            fontSize: 12),
                                      ),
                                    ]),
                                  ],
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: AppTheme.primary),
                                onTap: () async {
                                  final detail = await ApiService
                                      .getIssueById(n['id']);
                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          IssueDetailScreen(
                                        issue: Map<String,
                                                dynamic>.from(
                                            detail),
                                        language: widget.language,
                                        onUpdated: _load,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}