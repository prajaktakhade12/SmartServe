import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'issue_detail_screen.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  List<dynamic> _issues = [];
  bool _loading = true;
  String _selectedStatus = '';
  final _searchCtrl = TextEditingController();

  final _statuses = ['', 'REPORTED', 'IN_PROGRESS', 'COMPLETED'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final issues = await ApiService.getOfficerIssues(
      OfficerSession.category ?? '',
      status: _selectedStatus,
      search: _searchCtrl.text.trim(),
    );
    setState(() { _issues = issues; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isHead = OfficerSession.isHead;
    final category = OfficerSession.category ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Issues', style: TextStyle(fontSize: 28,
                  fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
              Text(
                isHead ? 'All Categories — ${_issues.length} issues'
                    : '${_formatCat(category)} Department — ${_issues.length} issues',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ]),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Search + Filter Row
          Row(children: [
            // Search
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by title or citizen name...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear_rounded),
                          onPressed: () { _searchCtrl.clear(); _load(); })
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: Colors.white,
                ),
                onChanged: (_) => _load(),
              ),
            ),
            const SizedBox(width: 16),
            // Status filter
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    hint: const Text('Filter by Status'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All Status')),
                      ..._statuses.skip(1).map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(children: [
                          Icon(Icons.circle, size: 10,
                              color: AppTheme.getStatusColor(s)),
                          const SizedBox(width: 8),
                          Text(s.replaceAll('_', ' ')),
                        ]),
                      )),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedStatus = v ?? '');
                      _load();
                    },
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Status summary chips
          Row(children: [
            _summaryChip('All', _issues.length, Colors.grey),
            const SizedBox(width: 8),
            _summaryChip('Reported',
                _issues.where((i) => i['status'] == 'REPORTED').length,
                AppTheme.reported),
            const SizedBox(width: 8),
            _summaryChip('In Progress',
                _issues.where((i) => i['status'] == 'IN_PROGRESS').length,
                AppTheme.inProgress),
            const SizedBox(width: 8),
            _summaryChip('Completed',
                _issues.where((i) => i['status'] == 'COMPLETED').length,
                AppTheme.completed),
          ]),
          const SizedBox(height: 16),

          // Issues Table
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _issues.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.inbox_rounded, size: 80,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No issues found',
                              style: TextStyle(fontSize: 18,
                                  color: Colors.grey.shade500)),
                        ]))
                    : Card(
                        child: Column(children: [
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDark.withOpacity(0.05),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16))),
                            child: Row(children: [
                              _headerCell('ID', flex: 1),
                              _headerCell('Title', flex: 4),
                              if (isHead) _headerCell('Category', flex: 2),
                              _headerCell('Citizen', flex: 2),
                              _headerCell('Location', flex: 3),
                              _headerCell('Status', flex: 2),
                              _headerCell('Date', flex: 2),
                              _headerCell('Action', flex: 1),
                            ]),
                          ),
                          // Table rows
                          Expanded(
                            child: ListView.separated(
                              itemCount: _issues.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: Colors.grey.shade100),
                              itemBuilder: (ctx, i) =>
                                  _issueRow(_issues[i], isHead),
                            ),
                          ),
                        ]),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _issueRow(Map issue, bool isHead) {
    final status = issue['status'] ?? 'REPORTED';
    final statusColor = AppTheme.getStatusColor(status);
    final category = issue['category'] ?? '';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => IssueDetailScreen(issue: Map<String, dynamic>.from(issue),
            onUpdated: _load))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Expanded(flex: 1, child: Text('#${issue['id']}',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  color: AppTheme.primary))),
          Expanded(flex: 4, child: Text(issue['title'] ?? '',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500))),
          if (isHead) Expanded(flex: 2, child: Row(children: [
            Icon(AppTheme.getCategoryIcon(category),
                size: 14, color: AppTheme.getCategoryColor(category)),
            const SizedBox(width: 4),
            Text(_formatCat(category),
                style: TextStyle(fontSize: 12,
                    color: AppTheme.getCategoryColor(category),
                    fontWeight: FontWeight.w500)),
          ])),
          Expanded(flex: 2, child: Text(issue['name'] ?? '',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13))),
          Expanded(flex: 3, child: Text(issue['location'] ?? '',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
            child: Text(status.replaceAll('_', ' '),
                style: TextStyle(color: statusColor, fontSize: 11,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          )),
          Expanded(flex: 2, child: Text(issue['created_at'] ?? '',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
          Expanded(flex: 1, child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            color: AppTheme.primary,
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => IssueDetailScreen(
                  issue: Map<String, dynamic>.from(issue),
                  onUpdated: _load))),
          )),
        ]),
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) {
    return Expanded(flex: flex, child: Text(label,
        style: const TextStyle(fontWeight: FontWeight.bold,
            fontSize: 13, color: AppTheme.primaryDark)));
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text('$label: $count', style: TextStyle(color: color,
            fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  String _formatCat(String cat) {
    if (cat == 'STREET_LIGHT') return 'Street Light';
    if (cat.isEmpty) return '';
    return cat[0] + cat.substring(1).toLowerCase();
  }
}
