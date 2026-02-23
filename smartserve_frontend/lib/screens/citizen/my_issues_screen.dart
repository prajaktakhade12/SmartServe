import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/user_session.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'issue_detail_screen.dart';

class MyIssuesScreen extends StatefulWidget {
  final String selectedLanguage;
  const MyIssuesScreen({Key? key, required this.selectedLanguage}) : super(key: key);
  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  List<dynamic> _issues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchIssues();
  }

  Future<void> _fetchIssues() async {
    setState(() => _loading = true);
    final result = await ApiService.getMyIssues(UserSession.mobile ?? '');
    setState(() { _issues = result; _loading = false; });
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toUpperCase()) {
      case 'ROAD': return Icons.directions_car_rounded;
      case 'WATER': return Icons.water_drop_rounded;
      case 'ELECTRICITY': return Icons.flash_on_rounded;
      case 'SANITATION': return Icons.cleaning_services_rounded;
      case 'ENVIRONMENT': return Icons.eco_rounded;
      case 'SAFETY': return Icons.security_rounded;
      case 'STREET_LIGHT': return Icons.lightbulb_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.selectedLanguage;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppStrings.text("my_issues", lang)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF003c8f)]))),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchIssues)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _issues.isEmpty
              ? _emptyState(lang)
              : RefreshIndicator(
                  onRefresh: _fetchIssues,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _issues.length,
                    itemBuilder: (ctx, i) => _issueCard(_issues[i], lang),
                  ),
                ),
    );
  }

  Widget _issueCard(Map issue, String lang) {
    final status = issue['status'] ?? 'REPORTED';
    final category = issue['category'] ?? 'OTHER';
    final color = AppTheme.getStatusColor(status);
    final catColor = AppTheme.getCategoryColor(category);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => IssueDetailScreen(issue: Map<String, dynamic>.from(issue), selectedLanguage: widget.selectedLanguage))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(_categoryIcon(category), color: catColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(issue['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 2),
                Expanded(child: Text(issue['location'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Text(issue['created_at'] ?? '', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ])),
            Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState(String lang) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_rounded, size: 70, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(AppStrings.text("no_issues", lang), style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
    ]));
  }
}