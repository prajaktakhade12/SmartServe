import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../core/officer_strings.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'issue_detail_screen.dart';

class IssuesScreen extends StatefulWidget {
  final String language;
  const IssuesScreen({super.key, required this.language});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  List<dynamic> _issues      = [];
  bool          _loading     = true;
  String        _selectedStatus = '';
  final _searchCtrl          = TextEditingController();

  String get _lang => widget.language;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(IssuesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final issues = await ApiService.getOfficerIssues(
      OfficerSession.category ?? '',
      status: _selectedStatus,
      search: _searchCtrl.text.trim(),
      officerId: OfficerSession.id,
      role: OfficerSession.role ?? '',
    );
    setState(() {
      _issues  = issues;
      _loading = false;
    });
  }

  void _openDetail(Map issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueDetailScreen(
          issue:    Map<String, dynamic>.from(issue),
          language: _lang,
          onUpdated: _load,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHead   = OfficerSession.isHead;
    final category = OfficerSession.category ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    OfficerStrings.text('issues', _lang),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark),
                  ),
                  Text(
                    isHead
                        ? '${OfficerStrings.text("cat_all", _lang)} — ${_issues.length} ${OfficerStrings.text("issues", _lang).toLowerCase()}'
                        : '${OfficerStrings.category(category, _lang)} — ${_issues.length} ${OfficerStrings.text("issues", _lang).toLowerCase()}',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14),
                  ),
                ]),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(OfficerStrings.text('refresh', _lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Search + Status Filter ──────────────────────────────────
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: OfficerStrings.text('search_issues', _lang),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              _load();
                            })
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => _load(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      hint: Text(
                          OfficerStrings.text('all_status', _lang)),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(OfficerStrings.text(
                              'all_status', _lang)),
                        ),
                        DropdownMenuItem(
                          value: 'REPORTED',
                          child: Row(children: [
                            Icon(Icons.circle,
                                size: 10,
                                color: AppTheme.getStatusColor(
                                    'REPORTED')),
                            const SizedBox(width: 8),
                            Text(OfficerStrings.text(
                                'status_reported', _lang)),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'IN_PROGRESS',
                          child: Row(children: [
                            Icon(Icons.circle,
                                size: 10,
                                color: AppTheme.getStatusColor(
                                    'IN_PROGRESS')),
                            const SizedBox(width: 8),
                            Text(OfficerStrings.text(
                                'status_inprogress', _lang)),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'COMPLETED',
                          child: Row(children: [
                            Icon(Icons.circle,
                                size: 10,
                                color: AppTheme.getStatusColor(
                                    'COMPLETED')),
                            const SizedBox(width: 8),
                            Text(OfficerStrings.text(
                                'status_completed', _lang)),
                          ]),
                        ),
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

            // ── Summary Chips ───────────────────────────────────────────
            Row(children: [
              _summaryChip(
                OfficerStrings.text('cat_all', _lang),
                _issues.length,
                Colors.grey,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                OfficerStrings.text('status_reported', _lang),
                _issues
                    .where((i) => i['status'] == 'REPORTED')
                    .length,
                AppTheme.reported,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                OfficerStrings.text('status_inprogress', _lang),
                _issues
                    .where((i) => i['status'] == 'IN_PROGRESS')
                    .length,
                AppTheme.inProgress,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                OfficerStrings.text('status_completed', _lang),
                _issues
                    .where((i) => i['status'] == 'COMPLETED')
                    .length,
                AppTheme.completed,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Issues Table ────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _issues.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 80,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                OfficerStrings.text(
                                    'no_issues', _lang),
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          child: Column(children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDark
                                    .withOpacity(0.05),
                                borderRadius:
                                    const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                              ),
                              child: Row(children: [
                                _hCell('Issue ID', flex: 2),
                                _hCell(OfficerStrings.text('issue_detail', _lang), flex: 4),
                                if (isHead) _hCell(OfficerStrings.text('department', _lang), flex: 2),
                                _hCell(OfficerStrings.text('citizen', _lang), flex: 2),
                                _hCell(OfficerStrings.text('location', _lang), flex: 3),
                                _hCell(OfficerStrings.text('assigned_to', _lang), flex: 2),
                                _hCell(OfficerStrings.text('all_status', _lang), flex: 2),
                                _hCell('📅', flex: 2),
                                _hCell('', flex: 1),
                              ]),
                            ),

                            // Table Rows
                            Expanded(
                              child: ListView.separated(
                                itemCount: _issues.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade100),
                                itemBuilder: (ctx, i) =>
                                    _issueRow(_issues[i], isHead),
                              ),
                            ),
                          ]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _issueRow(Map issue, bool isHead) {
    final status      = issue['status'] ?? 'REPORTED';
    final statusColor = AppTheme.getStatusColor(status);
    final category    = issue['category'] ?? '';
    final assignedName = issue['assigned_officer_name'] ?? '';

    return InkWell(
      onTap: () => _openDetail(issue),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        child: Row(children: [
          // ID
          Expanded(
            flex: 2,
            child: Text(
                (issue['display_id'] as String?) ?? '#',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppTheme.primary)),
          ),
          // Title
          Expanded(
            flex: 4,
            child: Text(issue['title'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w500)),
          ),
          // Category (head only)
          if (isHead)
            Expanded(
              flex: 2,
              child: Row(children: [
                Icon(AppTheme.getCategoryIcon(category),
                    size: 14,
                    color: AppTheme.getCategoryColor(category)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    OfficerStrings.category(category, _lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            AppTheme.getCategoryColor(category),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ),
          // Citizen
          Expanded(
            flex: 2,
            child: Text(issue['name'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ),
          // Location
          Expanded(
            flex: 3,
            child: Text(issue['location'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600)),
          ),
          // Assigned officer
          Expanded(
            flex: 2,
            child: Text(
              assignedName.isNotEmpty
                  ? assignedName
                  : OfficerStrings.text('unassigned', _lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: assignedName.isNotEmpty
                      ? AppTheme.primary
                      : Colors.grey.shade400,
                  fontStyle: assignedName.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal),
            ),
          ),
          // Status chip
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
              child: Text(
                OfficerStrings.status(status, _lang),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(issue['created_at'] ?? '',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500)),
          ),
          // Arrow
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16),
              color: AppTheme.primary,
              onPressed: () => _openDetail(issue),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _hCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.primaryDark)),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text('$label: $count',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ]),
    );
  }
}