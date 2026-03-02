import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
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
  String _selectedCategory = '';
  String _selectedStatus = '';
  final _searchCtrl = TextEditingController();

  final _categories = ['', 'ROAD', 'WATER', 'ELECTRICITY', 'SANITATION', 'ENVIRONMENT', 'SAFETY', 'STREET_LIGHT', 'OTHER'];
  final _statuses = ['', 'REPORTED', 'IN_PROGRESS', 'COMPLETED'];

  @override
  void initState() {
    super.initState();
    _fetchIssues();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchIssues() async {
    setState(() => _loading = true);
    final result = await ApiService.getMyIssues(
      UserSession.mobile ?? '',
      category: _selectedCategory,
      status: _selectedStatus,
      search: _searchCtrl.text.trim(),
    );
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
    // Use Provider so language updates instantly when toggled
    final lang = Provider.of<AppState>(context).language;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).cardColor,
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: AppStrings.text('search_issues', lang),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear_rounded),
                      onPressed: () { _searchCtrl.clear(); _fetchIssues(); })
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (_) => _fetchIssues(),
          ),
        ),

        // Filter chips
        Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Text('${AppStrings.text("filter_status", lang)}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ..._statuses.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      s.isEmpty
                          ? AppStrings.text('all', lang)
                          : AppStrings.text(s.toLowerCase(), lang),
                      style: const TextStyle(fontSize: 11)),
                    selected: _selectedStatus == s,
                    selectedColor: AppTheme.primary.withOpacity(0.2),
                    onSelected: (_) { setState(() => _selectedStatus = s); _fetchIssues(); },
                  ),
                )).toList(),
              ]),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Text('${AppStrings.text("filter_category", lang)}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ..._categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      c.isEmpty
                          ? AppStrings.text('all', lang)
                          : AppStrings.text(c.toLowerCase(), lang),
                      style: const TextStyle(fontSize: 11)),
                    selected: _selectedCategory == c,
                    selectedColor: AppTheme.primary.withOpacity(0.2),
                    onSelected: (_) { setState(() => _selectedCategory = c); _fetchIssues(); },
                  ),
                )).toList(),
              ]),
            ),
          ]),
        ),

        // Issues list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _issues.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox_rounded, size: 70, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(AppStrings.text("no_issues", lang),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetchIssues,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _issues.length,
                        itemBuilder: (ctx, i) => _issueCard(_issues[i], lang),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _issueCard(Map issue, String lang) {
    final status = issue['status'] ?? 'REPORTED';
    final category = issue['category'] ?? 'OTHER';
    final color = AppTheme.getStatusColor(status);
    final catColor = AppTheme.getCategoryColor(category);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => IssueDetailScreen(
            issue: Map<String, dynamic>.from(issue),
            selectedLanguage: lang))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(_categoryIcon(category), color: catColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(issue['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 2),
                Expanded(child: Text(issue['location'] ?? '',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Text(issue['created_at'] ?? '',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              if (issue['rating'] != null) ...[
                const SizedBox(height: 4),
                Row(children: List.generate(5, (i) => Icon(
                  i < (issue['rating'] as int) ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14, color: Colors.amber))),
              ],
            ])),
            Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  AppStrings.text(status.toLowerCase(), lang),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ]),
          ]),
        ),
      ),
    );
  }
}