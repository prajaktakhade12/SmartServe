import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../core/officer_strings.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TeamScreen extends StatefulWidget {
  final String language;
  const TeamScreen({super.key, required this.language});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  bool _loading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  String get _lang => widget.language;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TeamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final result = await ApiService.getOfficerStats(
          OfficerSession.category ?? '');
      setState(() {
        _stats   = result is Map<String, dynamic>
            ? result
            : {'data': result};
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHead = OfficerSession.role == 'head';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [

        // ── Header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          color: Colors.white,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.groups_rounded,
                  color: AppTheme.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  OfficerStrings.text('my_team', _lang),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark),
                ),
                Text(
                  isHead
                      ? OfficerStrings.text(
                          'all_dept_overview', _lang)
                      : OfficerStrings.text(
                          'your_dept_officers', _lang),
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: OfficerStrings.text('refresh', _lang),
            ),
          ]),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(
                          '${OfficerStrings.text("error", _lang)}: $_error'))
                  : _buildContent(isHead),
        ),
      ]),
    );
  }

  Widget _buildContent(bool isHead) {
    if (isHead) {
      final List<dynamic> deptList = _stats?['data'] ?? [];
      if (deptList.isEmpty) {
        return Center(
            child: Text(OfficerStrings.text('no_data', _lang)));
      }
      return _buildDeptOverview(deptList);
    } else {
      return _buildDeptTeam();
    }
  }

  // ── Overall Head: Department comparison ───────────────────────
  Widget _buildDeptOverview(List<dynamic> depts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OfficerStrings.text('dept_overview_title', _lang),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 16),
          Card(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.0),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(0.8),
                3: FlexColumnWidth(0.8),
                4: FlexColumnWidth(0.8),
                5: FlexColumnWidth(0.8),
                6: FlexColumnWidth(1.2),
              },
              defaultVerticalAlignment:
                  TableCellVerticalAlignment.middle,
              children: [
                // Header row
                TableRow(
                  decoration:
                      BoxDecoration(color: AppTheme.primaryDark),
                  children: [
                    _th(OfficerStrings.text('department', _lang)),
                    _th(OfficerStrings.text('dept_head_col', _lang)),
                    _th(OfficerStrings.text('total_col', _lang)),
                    _th(OfficerStrings.text('done_col', _lang)),
                    _th(OfficerStrings.text('pending_col', _lang)),
                    _th(OfficerStrings.text('in_progress', _lang)),
                    _th(OfficerStrings.text('rate_col', _lang)),
                  ],
                ),
                ...depts.map((d) {
                  final rate =
                      (d['resolution_rate'] ?? 0.0) as num;
                  final rateColor = rate >= 80
                      ? AppTheme.completed
                      : rate >= 50
                          ? AppTheme.inProgress
                          : AppTheme.reported;
                  // Translate category label
                  final catLabel = OfficerStrings.category(
                      d['category'] ?? '', _lang);
                  return TableRow(
                    decoration: BoxDecoration(
                      color: depts.indexOf(d) % 2 == 0
                          ? Colors.grey.shade50
                          : Colors.white),
                    children: [
                      _td(catLabel),
                      _td(d['dept_head'] ?? ''),
                      _td('${d['total'] ?? 0}'),
                      _td('${d['completed'] ?? 0}'),
                      _td('${d['reported'] ?? 0}'),
                      _td('${d['in_progress'] ?? 0}'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rateColor.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(6)),
                          child: Text(
                            '$rate%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: rateColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dept Head: Their team ──────────────────────────────────────
  Widget _buildDeptTeam() {
    final officers   = (_stats?['officers'] as List?) ?? [];
    final total      = _stats?['total_issues']    ?? 0;
    final completed  = _stats?['completed_issues'] ?? 0;
    final pending    = _stats?['pending_issues']   ?? 0;
    final unassigned = _stats?['unassigned_issues'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Summary cards
          Row(children: [
            _summaryCard(
                OfficerStrings.text('total_issues', _lang),
                '$total',
                AppTheme.primary,
                Icons.list_alt_rounded),
            const SizedBox(width: 12),
            _summaryCard(
                OfficerStrings.text('completed', _lang),
                '$completed',
                AppTheme.completed,
                Icons.check_circle_rounded),
            const SizedBox(width: 12),
            _summaryCard(
                OfficerStrings.text('reported', _lang),
                '$pending',
                AppTheme.reported,
                Icons.flag_rounded),
            const SizedBox(width: 12),
            _summaryCard(
                OfficerStrings.text('unassigned', _lang),
                '$unassigned',
                Colors.orange,
                Icons.person_off_rounded),
          ]),
          const SizedBox(height: 24),

          Text(
            OfficerStrings.text('team_performance', _lang),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            OfficerStrings.text('your_dept_officers', _lang),
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),

          if (officers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                    OfficerStrings.text('no_data', _lang)),
              ),
            )
          else
            Card(
              child: Column(
                children: officers.map<Widget>((o) {
                  final rate =
                      (o['resolution_rate'] ?? 0.0) as num;
                  final isDeptHead = o['role'] == 'dept_head';
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade100))),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isDeptHead
                            ? AppTheme.primary.withOpacity(0.15)
                            : Colors.grey.shade100,
                        child: Text(
                          (o['name'] as String? ?? 'O')[0],
                          style: TextStyle(
                              color: isDeptHead
                                  ? AppTheme.primary
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(children: [
                        Text(o['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (isDeptHead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(4)),
                            child: Text(
                              OfficerStrings.text(
                                  'dept_head_label', _lang),
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ]),
                      subtitle: Text(
                        o['designation'] ?? '',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _miniStat(
                            '${o['total_handled'] ?? 0}',
                            OfficerStrings.text('handled', _lang),
                            Colors.grey.shade600,
                          ),
                          const SizedBox(width: 16),
                          _miniStat(
                            '${o['completed'] ?? 0}',
                            OfficerStrings.text('done_col', _lang),
                            AppTheme.completed,
                          ),
                          const SizedBox(width: 16),
                          _rateChip(rate.toDouble()),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          // Info note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200)),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  OfficerStrings.text('team_info_note', _lang),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _summaryCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color)),
      Text(label,
          style: TextStyle(
              fontSize: 10, color: Colors.grey.shade400)),
    ]);
  }

  Widget _rateChip(double rate) {
    final color = rate >= 80
        ? AppTheme.completed
        : rate >= 50
            ? AppTheme.inProgress
            : AppTheme.reported;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8)),
      child: Text('$rate%',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14)),
    );
  }

  Widget _th(String text) => Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 12),
    child: Text(text,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12)),
  );

  Widget _td(String text) => Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 10),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13, color: Color(0xFF333333))),
  );
}