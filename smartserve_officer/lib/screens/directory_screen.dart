import 'package:flutter/material.dart';
import '../core/officer_strings.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DirectoryScreen extends StatefulWidget {
  final String language;
  const DirectoryScreen({super.key, required this.language});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  // All officers loaded from backend, grouped by category
  Map<String, List<dynamic>> _byCategory = {};
  bool _loading = true;
  String _searchQuery = '';
  String _expandedCategory = ''; // which dept accordion is open
  final _searchCtrl = TextEditingController();

  String get _lang => widget.language;

  // Work descriptions per designation — same as profile_screen logic
  static const Map<String, List<String>> _workMap = {
    'Municipal Commissioner': [
      'Overall head of all departments',
      'Views all issues across all 8 categories',
      'Monitors department-wise performance',
      'Reassigns & escalates any issue',
    ],
    'Road Department Head': [
      'Oversees all road complaints',
      'Monitors performance of road officers',
      'Reassigns issues within road department',
    ],
    'Junior Engineer (Roads)': [
      'Handles: Road damage / crack',
      'Handles: Speed breaker needed',
      'Road construction & repair quality',
    ],
    'Pothole Repair Supervisor': [
      'Handles: Pothole on road',
      'Handles: Road waterlogging',
      'Supervises pothole filling teams',
    ],
    'Road Survey Officer': [
      'Handles: Encroachment on road',
      'Handles: Missing road signs / signals',
      'Surveys & reports road encroachments',
    ],
    'Bridge & Footpath Inspector': [
      'Handles: Damaged footpath / pavement',
      'Handles: Missing road divider',
      'Inspects bridges and footpaths',
    ],
    'Water Department Head': [
      'Oversees all water complaints',
      'Monitors performance of water officers',
      'Reassigns issues within water department',
    ],
    'Pipe Repair Engineer': [
      'Handles: Water leakage in pipe',
      'Inspects and repairs broken water pipes',
    ],
    'Borewell & Pump Officer': [
      'Handles: Water supply disruption',
      'Handles: Low water pressure',
      'Handles: Borewell not working',
      'Maintains borewells and pumping stations',
    ],
    'Drainage & Sewage Engineer': [
      'Handles: Drainage overflow',
      'Inspects and clears blocked sewage lines',
    ],
    'Water Quality Inspector': [
      'Handles: Contaminated / dirty water',
      'Handles: Water meter issue',
      'Handles: Illegal water connection',
    ],
    'Electricity Department Head': [
      'Oversees all electricity complaints',
      'Monitors performance of electricity officers',
      'Reassigns issues within electricity department',
    ],
    'Line Maintenance Officer': [
      'Handles: Power outage in area',
      'Handles: Sparking / hanging wire',
      'Handles: Fallen electric pole',
      'Handles: Electric shock hazard',
    ],
    'Transformer & Sub-Station Engineer': [
      'Handles: Transformer fault',
      'Handles: High voltage fluctuation',
    ],
    'Meter & Connection Inspector': [
      'Handles: Meter tampering',
      'Inspects illegal electricity connections',
    ],
    'Sanitation Department Head': [
      'Oversees all sanitation complaints',
      'Monitors performance of sanitation officers',
      'Reassigns issues within sanitation department',
    ],
    'Solid Waste Management Officer': [
      'Handles: Garbage not collected',
      'Handles: Overflowing dustbin / dumpyard',
    ],
    'Drainage & Nala Supervisor': [
      'Handles: Blocked drain / nala',
      'Handles: Bad odour from drain',
    ],
    'Sweeping & Cleaning Supervisor': [
      'Handles: Open defecation area',
      'Handles: Sanitation workers absent',
    ],
    'Public Toilet Maintenance Officer': [
      'Handles: Public toilet issues',
      'Maintains public toilet facilities',
    ],
    'Pest & Mosquito Control Officer': [
      'Handles: Mosquito / pest breeding site',
      'Conducts fogging and pest control operations',
    ],
    'Environment Department Head': [
      'Oversees all environment complaints',
      'Monitors performance of environment officers',
      'Reassigns issues within environment department',
    ],
    'Pollution Control Officer': [
      'Handles: Illegal garbage dumping',
      'Handles: Air pollution from factory / vehicle',
      'Handles: Noise pollution',
    ],
    'Green Belt & Garden Officer': [
      'Handles: Tree fallen on road',
      'Handles: Encroachment on green belt / garden',
    ],
    'River & Lake Conservation Officer': [
      'Handles: Stray animal menace',
      'Handles: River / lake pollution',
    ],
    'Safety Department Head': [
      'Oversees all safety complaints',
      'Monitors performance of safety officers',
      'Reassigns issues within safety department',
    ],
    'Field Safety Inspector': [
      'Handles: Road accident spot',
      'Inspects reported hazardous locations',
    ],
    'Fire & Accident Prevention Officer': [
      'Handles: Fire hazard',
      'Handles: Suspicious activity / crime',
      'Handles: Missing person',
      'Handles: Drug / alcohol nuisance',
    ],
    'Traffic Safety & Encroachment Officer': [
      'Handles: Illegal construction',
      'Handles: Street harassment',
      'Inspects traffic safety & road encroachments',
    ],
    'Street Light Department Head': [
      'Oversees all street light complaints',
      'Monitors performance of street light officers',
      'Reassigns issues within street light department',
    ],
    'Electrical Maintenance Officer': [
      'Handles: Street light not working',
      'Handles: Flickering street light',
      'Handles: Wire exposed on light pole',
    ],
    'Light Pole & Fixture Inspector': [
      'Handles: Damaged light pole',
      'Handles: Light on during daytime (wastage)',
    ],
    'New Installation & Wiring Officer': [
      'Handles: New street light needed',
      'Plans and installs new street light poles',
    ],
    'General Department Head': [
      'Oversees all general / other complaints',
      'Monitors performance of general officers',
      'Reassigns issues within general department',
    ],
    'General Civic Officer': [
      'Handles: Government property damage',
      'Handles: Public toilet issue (Other)',
      'Handles: Stray cattle on road',
      'Handles manually typed issues',
    ],
    'Building & Encroachment Officer': [
      'Handles: Encroachment on public land',
      'Inspects illegal buildings',
    ],
    'Public Property & Parks Officer': [
      'Handles: Park / garden not maintained',
      'Handles: Bus stop damaged',
    ],
  };

  static const List<String> _categoryOrder = [
    'ROAD', 'WATER', 'ELECTRICITY', 'SANITATION',
    'ENVIRONMENT', 'SAFETY', 'STREET_LIGHT', 'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getOfficerList('HEAD');
    // Group by category
    final Map<String, List<dynamic>> grouped = {};
    for (final o in list) {
      final cat = o['category'] as String? ?? 'OTHER';
      grouped.putIfAbsent(cat, () => []).add(o);
    }
    // Sort: dept_head first in each category
    for (final cat in grouped.keys) {
      grouped[cat]!.sort((a, b) {
        final ra = a['role'] == 'dept_head' ? 0 : 1;
        final rb = b['role'] == 'dept_head' ? 0 : 1;
        return ra.compareTo(rb);
      });
    }
    setState(() {
      _byCategory = grouped;
      _loading    = false;
      // expand first category by default
      if (grouped.isNotEmpty) _expandedCategory = _categoryOrder.first;
    });
  }

  List<dynamic> get _filteredOfficers {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    final result = <dynamic>[];
    for (final officers in _byCategory.values) {
      for (final o in officers) {
        if ((o['name'] as String).toLowerCase().contains(q) ||
            (o['designation'] as String).toLowerCase().contains(q) ||
            (o['username'] as String).toLowerCase().contains(q)) {
          result.add(o);
        }
      }
    }
    return result;
  }

  int get _totalOfficers =>
      _byCategory.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [

        // ── Header ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          color: Colors.white,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.contacts_rounded,
                  color: AppTheme.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _lang == 'hi' ? 'अधिकारी निर्देशिका'
                    : _lang == 'mr' ? 'अधिकारी निर्देशिका'
                    : 'Officer Directory',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark),
              ),
              Text(
                _loading
                    ? '...'
                    : _lang == 'hi'
                        ? 'सभी $_totalOfficers अधिकारी — 8 विभाग'
                        : _lang == 'mr'
                            ? 'सर्व $_totalOfficers अधिकारी — 8 विभाग'
                            : 'All $_totalOfficers officers across 8 departments',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
            ]),
            const Spacer(),
            // Search box
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: _lang == 'hi'
                      ? 'नाम या पदनाम खोजें...'
                      : _lang == 'mr'
                          ? 'नाव किंवा पदनाम शोधा...'
                          : 'Search by name or designation...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          })
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: OfficerStrings.text('refresh', _lang),
            ),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : _buildCategoryList(),
        ),
      ]),
    );
  }

  // ── Search results (flat list) ──────────────────────────────────────────
  Widget _buildSearchResults() {
    final results = _filteredOfficers;
    if (results.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _lang == 'hi' ? 'कोई अधिकारी नहीं मिला'
                : _lang == 'mr' ? 'कोणताही अधिकारी आढळला नाही'
                : 'No officers found',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _officerCard(results[i]),
    );
  }

  // ── Category accordion list ──────────────────────────────────────────────
  Widget _buildCategoryList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: _categoryOrder.map((cat) {
        final officers = _byCategory[cat] ?? [];
        if (officers.isEmpty) return const SizedBox.shrink();
        final isOpen = _expandedCategory == cat;
        final catColor = AppTheme.getCategoryColor(cat);
        final catLabel = OfficerStrings.category(cat, _lang);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: isOpen ? 3 : 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [

              // ── Department header row (tap to expand/collapse) ──────────
              InkWell(
                borderRadius: isOpen
                    ? const BorderRadius.vertical(top: Radius.circular(14))
                    : BorderRadius.circular(14),
                onTap: () => setState(() =>
                    _expandedCategory = isOpen ? '' : cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? catColor.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: isOpen
                        ? const BorderRadius.vertical(
                            top: Radius.circular(14))
                        : BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(AppTheme.getCategoryIcon(cat),
                          color: catColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(catLabel,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: catColor)),
                        Text(
                          _officerCountLabel(officers.length),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    )),
                    // Dept head name chip
                    _deptHeadChip(officers, catColor),
                    const SizedBox(width: 12),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ]),
                ),
              ),

              // ── Expanded officer cards ───────────────────────────────────
              if (isOpen) ...[
                Divider(height: 1, color: catColor.withOpacity(0.2)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: officers
                        .map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _officerCard(o,
                                  catColor: catColor),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Individual officer card ──────────────────────────────────────────────
  Widget _officerCard(dynamic o, {Color? catColor}) {
    final isDeptHead = o['role'] == 'dept_head';
    final isHead     = o['role'] == 'head';
    final designation = o['designation'] as String? ?? '';
    final workItems  = _workMap[designation] ?? [];
    final color      = catColor ?? AppTheme.getCategoryColor(
        o['category'] as String? ?? 'OTHER');

    return Container(
      decoration: BoxDecoration(
        color: isDeptHead || isHead
            ? color.withOpacity(0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDeptHead || isHead
              ? color.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isDeptHead || isHead
              ? color.withOpacity(0.15)
              : Colors.grey.shade200,
          child: Text(
            (o['name'] as String? ?? 'O')[0],
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDeptHead || isHead
                    ? color : Colors.grey.shade600),
          ),
        ),
        title: Row(children: [
          Expanded(
            child: Text(o['name'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          if (isDeptHead)
            _roleBadge(
              _lang == 'hi' ? 'विभाग प्रमुख'
                  : _lang == 'mr' ? 'विभाग प्रमुख'
                  : 'DEPT HEAD',
              color,
            ),
          if (isHead)
            _roleBadge(
              _lang == 'hi' ? 'मुख्य'
                  : _lang == 'mr' ? 'मुख्य'
                  : 'HEAD',
              const Color(0xFFB8860B),
            ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(designation,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Text(
            _lang == 'hi' ? 'कार्य जिम्मेदारियाँ:'
                : _lang == 'mr' ? 'कामाच्या जबाबदाऱ्या:'
                : 'Work Responsibilities:',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: color),
          ),
          const SizedBox(height: 6),
          if (workItems.isEmpty)
            Text(
              _lang == 'hi'
                  ? 'इस पद के लिए समस्याएं संभालें'
                  : _lang == 'mr'
                      ? 'या पदासाठी समस्या हाताळा'
                      : 'Handles issues assigned to this designation',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            )
          else
            ...workItems.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(w,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _deptHeadChip(List<dynamic> officers, Color color) {
    final head = officers.firstWhere(
        (o) => o['role'] == 'dept_head',
        orElse: () => null);
    if (head == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Text(head['name'] ?? '',
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }

  String _officerCountLabel(int count) {
    if (_lang == 'hi') return '$count अधिकारी';
    if (_lang == 'mr') return '$count अधिकारी';
    return '$count officers';
  }
}