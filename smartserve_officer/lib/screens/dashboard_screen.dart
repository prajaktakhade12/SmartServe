import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../core/officer_strings.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final String language;
  const DashboardScreen({super.key, required this.language});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  String get _lang => widget.language;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Reload when language changes
  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getOfficerDashboard(
      OfficerSession.category ?? '',
      officerId: OfficerSession.id,
      role: OfficerSession.role ?? '',
    );
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return OfficerStrings.text('good_morning', _lang);
    if (h < 17) return OfficerStrings.text('good_afternoon', _lang);
    return OfficerStrings.text('good_evening', _lang);
  }

  String _formatCategory(String cat) {
    return OfficerStrings.category(cat, _lang);
  }

  String _now() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}  ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isHead     = OfficerSession.isHead;
    final category   = OfficerSession.category ?? '';
    final categories = _data['categories'] as Map? ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            '${_greeting()}, ${OfficerSession.name?.split(' ').first ?? ''}!',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isHead
                                ? OfficerStrings.text('all_dept_overview', _lang)
                                : '${_formatCategory(category)} — ${OfficerStrings.text('overview', _lang)}',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14),
                          ),
                        ],
                      ),
                      Row(children: [
                        Text(
                          _now(),
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
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
                      ]),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Stat Cards ───────────────────────────────────────────
                  Row(children: [
                    _statCard(
                      OfficerStrings.text('total_issues', _lang),
                      _data['total'] ?? 0,
                      Icons.list_alt_rounded,
                      AppTheme.primary,
                      Colors.blue.shade50,
                    ),
                    const SizedBox(width: 16),
                    _statCard(
                      OfficerStrings.text('reported', _lang),
                      _data['reported'] ?? 0,
                      Icons.flag_rounded,
                      AppTheme.reported,
                      Colors.orange.shade50,
                    ),
                    const SizedBox(width: 16),
                    _statCard(
                      OfficerStrings.text('in_progress', _lang),
                      _data['in_progress'] ?? 0,
                      Icons.pending_rounded,
                      AppTheme.inProgress,
                      Colors.amber.shade50,
                    ),
                    const SizedBox(width: 16),
                    _statCard(
                      OfficerStrings.text('completed', _lang),
                      _data['completed'] ?? 0,
                      Icons.check_circle_rounded,
                      AppTheme.completed,
                      Colors.green.shade50,
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Resolution Rate ───────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            OfficerStrings.text('resolution_rate', _lang),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark),
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                              child: _progressBar(
                                OfficerStrings.text('reported', _lang),
                                _data['reported'] ?? 0,
                                _data['total'] ?? 1,
                                AppTheme.reported,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _progressBar(
                                OfficerStrings.text('in_progress', _lang),
                                _data['in_progress'] ?? 0,
                                _data['total'] ?? 1,
                                AppTheme.inProgress,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _progressBar(
                                OfficerStrings.text('completed', _lang),
                                _data['completed'] ?? 0,
                                _data['total'] ?? 1,
                                AppTheme.completed,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),

                  // ── Category Breakdown (Head Only) ───────────────────────
                  if (isHead && categories.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              OfficerStrings.text('dept_wise', _lang),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDark),
                            ),
                            const SizedBox(height: 20),
                            ...categories.entries.map((e) {
                              final cat   = e.key as String;
                              final count = (e.value as int?) ?? 0;
                              final total = (_data['total'] as int?) ?? 1;
                              final pct   = total > 0 ? count / total : 0.0;
                              final color = AppTheme.getCategoryColor(cat);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(children: [
                                  Icon(AppTheme.getCategoryIcon(cat),
                                      color: color, size: 20),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      _formatCategory(cat),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 12,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation(color),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 30,
                                    child: Text('$count',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color)),
                                  ),
                                ]),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, int value, IconData icon,
      Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: color, size: 32),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
            ]),
            const SizedBox(height: 16),
            Text('$value',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _progressBar(
      String label, int value, int total, Color color) {
    final pct = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          Text('${(pct * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 14,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value ${OfficerStrings.text("issues", _lang).toLowerCase()}',
          style: TextStyle(
              fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}