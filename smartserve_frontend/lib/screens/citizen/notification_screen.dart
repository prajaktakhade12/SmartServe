import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_strings.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  final String selectedLanguage;

  const NotificationScreen({Key? key, required this.selectedLanguage})
      : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _mobileCtrl = TextEditingController();
  List<dynamic> _notifications = [];
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10-digit mobile number')),
      );
      return;
    }
    setState(() { _loading = true; _hasSearched = false; });
    final result = await ApiService.getNotifications(mobile);
    setState(() {
      _notifications = result;
      _loading = false;
      _hasSearched = true;
    });
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.text("notifications", lang)),
            if (_hasSearched && _unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF003c8f)],
            ),
          ),
        ),
        actions: [
          if (_hasSearched)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchNotifications,
            ),
        ],
      ),
      body: Column(
        children: [
          // Mobile Entry
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      hintText: AppStrings.text("mobile_hint", lang),
                      prefixIcon: const Icon(Icons.phone_android_rounded,
                          color: AppTheme.primary, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loading ? null : _fetchNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search_rounded, color: Colors.white),
                ),
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: !_hasSearched
                ? _emptyState(lang)
                : _notifications.isEmpty
                    ? _noNotifState(lang)
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _notifications.length,
                          itemBuilder: (ctx, i) =>
                              _notifCard(_notifications[i], i),
                        ),
                      ),
          ),
        ],
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
            color: isRead
                ? Colors.grey.shade100
                : AppTheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRead
                ? Icons.notifications_none_rounded
                : Icons.notifications_active_rounded,
            color: isRead ? Colors.grey : AppTheme.primary,
          ),
        ),
        title: Text(
          notif['message'] ?? '',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            notif['created_at'] ?? '',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        trailing: !isRead
            ? IconButton(
                icon: const Icon(Icons.done_all_rounded,
                    color: AppTheme.primary, size: 22),
                tooltip: 'Mark as read',
                onPressed: () => _markRead(notif['id'], index),
              )
            : const Icon(Icons.check_rounded, color: Colors.grey, size: 18),
      ),
    );
  }

  Widget _emptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Enter mobile number to view notifications',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _noNotifState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            AppStrings.text("no_notifications", lang),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}