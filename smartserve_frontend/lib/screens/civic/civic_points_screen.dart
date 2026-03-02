import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/user_session.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CivicPointsScreen extends StatefulWidget {
  final String selectedLanguage;
  const CivicPointsScreen({Key? key, required this.selectedLanguage}) : super(key: key);

  @override
  State<CivicPointsScreen> createState() => _CivicPointsScreenState();
}

class _CivicPointsScreenState extends State<CivicPointsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _points = {};
  List<dynamic> _leaderboard = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final mobile = UserSession.mobile ?? '';
      if (mobile.isEmpty) {
        setState(() { _loading = false; _error = 'Not logged in'; });
        return;
      }
      final pts = await ApiService.getCivicPoints(mobile);
      final lb = await ApiService.getLeaderboard();
      setState(() {
        _points = pts;
        _leaderboard = lb;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case 'Champion': return Colors.purple;
      case 'Hero': return Colors.orange;
      case 'Active': return Colors.blue;
      case 'Regular': return Colors.green;
      case 'Starter': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _badgeIcon(String badge) {
    switch (badge) {
      case 'Champion': return Icons.emoji_events_rounded;
      case 'Hero': return Icons.military_tech_rounded;
      case 'Active': return Icons.verified_rounded;
      case 'Regular': return Icons.stars_rounded;
      case 'Starter': return Icons.star_rounded;
      default: return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppState>(context).language;
    final badge = _points['badge'] ?? 'Newcomer';
    final badgeColor = _badgeColor(badge);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Points'),
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]))),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'My Points'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Could not load points', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ]))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // MY POINTS TAB
                    RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [

                          // Points card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [badgeColor, badgeColor.withOpacity(0.7)]),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(
                                color: badgeColor.withOpacity(0.3),
                                blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: Column(children: [
                              Icon(_badgeIcon(badge), color: Colors.white, size: 60),
                              const SizedBox(height: 10),
                              Text(badge, style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 14),
                              Text('${_points['total_points'] ?? 0}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
                              const Text('Total Points',
                                  style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text('${UserSession.name ?? ''}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ]),
                          ),
                          const SizedBox(height: 20),

                          // Stats grid
                          Row(children: [
                            Expanded(child: _statCard(
                              Icons.report_rounded, 'Issues Reported',
                              '${_points['issues_reported'] ?? 0}',
                              Colors.blue, Colors.blue.shade50)),
                            const SizedBox(width: 12),
                            Expanded(child: _statCard(
                              Icons.check_circle_rounded, 'Issues Resolved',
                              '${_points['issues_resolved'] ?? 0}',
                              Colors.green, Colors.green.shade50)),
                          ]),
                          const SizedBox(height: 20),

                          // How to earn points
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('How to Earn Points',
                                    style: TextStyle(fontWeight: FontWeight.bold,
                                        fontSize: 15, color: AppTheme.primary)),
                                const SizedBox(height: 14),
                                _earnRow(Icons.add_circle_rounded, 'Report an issue', '+10 pts', Colors.blue),
                                _earnRow(Icons.check_circle_rounded, 'Issue gets resolved', '+20 pts', Colors.green),
                                _earnRow(Icons.star_rounded, 'Rate a resolved issue', '+5 pts', Colors.amber),
                              ]),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Badge progress
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Badge Progress',
                                    style: TextStyle(fontWeight: FontWeight.bold,
                                        fontSize: 15, color: AppTheme.primary)),
                                const SizedBox(height: 14),
                                _badgeProgressRow('Newcomer', 0, Colors.grey),
                                _badgeProgressRow('Starter', 10, Colors.teal),
                                _badgeProgressRow('Regular', 50, Colors.green),
                                _badgeProgressRow('Active', 100, Colors.blue),
                                _badgeProgressRow('Hero', 200, Colors.orange),
                                _badgeProgressRow('Champion', 500, Colors.purple),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                    ),

                    // LEADERBOARD TAB
                    RefreshIndicator(
                      onRefresh: _load,
                      child: _leaderboard.isEmpty
                          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.leaderboard_rounded, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('No leaderboard data yet',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            ]))
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _leaderboard.length,
                              itemBuilder: (ctx, i) {
                                final entry = _leaderboard[i];
                                final rank = entry['rank'];
                                final isMe = (UserSession.mobile ?? '').endsWith(
                                    entry['mobile']?.toString().replaceAll('0', '') ?? '____');
                                return Card(
                                  color: isMe ? AppTheme.primary.withOpacity(0.1) : null,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: rank == 1 ? Colors.amber :
                                          rank == 2 ? Colors.grey :
                                          rank == 3 ? Colors.brown :
                                          AppTheme.primary.withOpacity(0.2),
                                      child: Text('$rank',
                                          style: TextStyle(
                                              color: rank <= 3 ? Colors.white : AppTheme.primary,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(entry['name'] ?? 'User',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Row(children: [
                                      Icon(_badgeIcon(entry['badge'] ?? ''), size: 14,
                                          color: _badgeColor(entry['badge'] ?? '')),
                                      const SizedBox(width: 4),
                                      Text(entry['badge'] ?? '',
                                          style: TextStyle(
                                              color: _badgeColor(entry['badge'] ?? ''),
                                              fontSize: 12)),
                                    ]),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20)),
                                      child: Text('${entry['total_points']} pts',
                                          style: const TextStyle(
                                              color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _earnRow(IconData icon, String label, String pts, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: Text(pts, style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _badgeProgressRow(String name, int required, Color color) {
    final current = (_points['total_points'] ?? 0) as int;
    final achieved = current >= required;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(achieved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: achieved ? color : Colors.grey, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: TextStyle(
            fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
            color: achieved ? color : Colors.grey))),
        Text('$required pts', style: TextStyle(
            fontSize: 12,
            color: achieved ? color : Colors.grey,
            fontWeight: achieved ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}