import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/localization/app_strings.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CitizenDashboardScreen extends StatefulWidget {
  final String selectedLanguage;
  const CitizenDashboardScreen({Key? key, required this.selectedLanguage}) : super(key: key);

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  Map<String, dynamic> data = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    data = await ApiService.getDashboard();
    setState(() => loading = false);
  }

  Widget _statCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(children: [
          Icon(icon, size: 28, color: Colors.white70),
          const SizedBox(height: 8),
          Text(value.toString(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Provider so language updates instantly when toggled
    final lang = Provider.of<AppState>(context).language;
    final categories = data['categories'] as Map? ?? {};

    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Stats row 1
            Row(children: [
              _statCard(AppStrings.text("total", lang),
                  data["total"] ?? 0, Colors.blue.shade400, Icons.list_alt_rounded),
              _statCard(AppStrings.text("reported", lang),
                  data["reported"] ?? 0, Colors.orange.shade400, Icons.flag_rounded),
            ]),
            // Stats row 2
            Row(children: [
              _statCard(AppStrings.text("in_progress", lang),
                  data["in_progress"] ?? 0, Colors.yellow.shade700, Icons.pending_rounded),
              _statCard(AppStrings.text("completed", lang),
                  data["completed"] ?? 0, Colors.green.shade400, Icons.check_circle_rounded),
            ]),

            if (categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppStrings.text('select_category', lang),
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 15, color: AppTheme.primary)),
                    const SizedBox(height: 14),
                    ...categories.entries.map((e) {
                      final cat = e.key as String;
                      final count = (e.value as int?) ?? 0;
                      final total = (data['total'] as int?) ?? 1;
                      final pct = total > 0 ? count / total : 0.0;
                      final color = AppTheme.getCategoryColor(cat);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          SizedBox(width: 90,
                            child: Text(AppStrings.text(cat.toLowerCase(), lang),
                                style: const TextStyle(fontSize: 13))),
                          Expanded(child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          )),
                          const SizedBox(width: 8),
                          Text('$count', style: TextStyle(
                              fontWeight: FontWeight.bold, color: color)),
                        ]),
                      );
                    }).toList(),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}