import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/user_session.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  final String selectedLanguage;
  const NotificationScreen({Key? key, required this.selectedLanguage}) : super(key: key);
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    final result = await ApiService.getNotifications(UserSession.mobile ?? '');
    setState(() { _notifications = result; _loading = false; });
  }

  Future<void> _markRead(int id, int index) async {
    await ApiService.markNotificationRead(id);
    setState(() => _notifications[index]['is_read'] = true);
  }

  int get _unreadCount => _notifications.where((n) => n['is_read'] == false).length;

  @override
  Widget build(BuildContext context) {
    final lang = widget.selectedLanguage;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(AppStrings.text("notifications", lang)),
          if (!_loading && _unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: Text('$_unreadCount', style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ],
        ]),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF003c8f)]))),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchNotifications)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _emptyState(lang)
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) => _notifCard(_notifications[i], i),
                  ),
                ),
    );
  }

  Widget _notifCard(Map notif, int index) {
    final isRead = notif['is_read'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: isRead ? 1 : 3,
      color: isRead ? Colors.white : const Color(0xFFE3F2FD),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRead ? Colors.grey.shade100 : AppTheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
            color: isRead ? Colors.grey : AppTheme.primary,
          ),
        ),
        title: Text(notif['message'] ?? '', style: TextStyle(fontSize: 14, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(notif['created_at'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ),
        trailing: !isRead
            ? IconButton(icon: const Icon(Icons.done_all_rounded, color: AppTheme.primary, size: 22), onPressed: () => _markRead(notif['id'], index))
            : const Icon(Icons.check_rounded, color: Colors.grey, size: 18),
      ),
    );
  }

  Widget _emptyState(String lang) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.notifications_none_rounded, size: 70, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(AppStrings.text("no_notifications", lang), style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
    ]));
  }
}