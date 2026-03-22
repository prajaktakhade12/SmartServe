import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String language;
  const ProfileScreen({super.key, required this.language});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result =
          await ApiService.getOfficerProfileStats(OfficerSession.id ?? 0);
      setState(() {
        _stats = result;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Role badge colour ──────────────────────────────────────────────────────
  Color get _roleColor {
    switch (OfficerSession.role) {
      case 'head':      return const Color(0xFFB8860B); // gold
      case 'dept_head': return AppTheme.primary;
      default:          return AppTheme.completed;
    }
  }

  String get _roleLabel {
    switch (OfficerSession.role) {
      case 'head':      return '🏛  Overall Head';
      case 'dept_head': return '👤  Department Head';
      default:          return '🔧  Field Officer';
    }
  }

  String get _statsLabel {
    switch (OfficerSession.role) {
      case 'head':      return 'Stats across all departments';
      case 'dept_head': return 'Stats for your department';
      default:          return 'Stats for your assigned issues';
    }
  }

  String _formatCategory(String cat) {
    if (cat == 'HEAD') return 'All Departments';
    if (cat == 'STREET_LIGHT') return 'Street Light';
    if (cat.isEmpty) return '';
    return cat[0] + cat.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Top Banner ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryDark, AppTheme.primary],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2),
                          ),
                          child: Center(
                            child: Text(
                              (OfficerSession.name ?? 'O')[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),

                        // Name & info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                OfficerSession.name ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                OfficerSession.designation ?? '',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                // Role badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _roleColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _roleLabel,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Department badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    _formatCategory(
                                        OfficerSession.category ?? ''),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),

                        // Refresh button
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white70),
                          onPressed: _load,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Account Details ────────────────────────────────
                        _sectionTitle('Account Details'),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(children: [
                              _detailRow(Icons.person_rounded,
                                  'Full Name', OfficerSession.name ?? ''),
                              _divider(),
                              _detailRow(Icons.account_circle_rounded,
                                  'Username', OfficerSession.username ?? '',
                                  mono: true),
                              _divider(),
                              _detailRow(Icons.badge_rounded,
                                  'Designation',
                                  OfficerSession.designation ?? ''),
                              _divider(),
                              _detailRow(Icons.security_rounded,
                                  'Role', _roleLabel),
                              _divider(),
                              _detailRow(Icons.category_rounded,
                                  'Department',
                                  _formatCategory(
                                      OfficerSession.category ?? '')),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── What Issues You Handle ─────────────────────────
                        _sectionTitle('What Issues You Handle'),
                        const SizedBox(height: 12),
                        _issueRoleCard(),

                        const SizedBox(height: 24),

                        // ── Performance Stats ──────────────────────────────
                        _sectionTitle('Performance  —  $_statsLabel'),
                        const SizedBox(height: 12),
                        if (_stats != null) ...[
                          Row(children: [
                            _statCard('Total',
                                '${_stats!['total'] ?? 0}',
                                AppTheme.primary,
                                Icons.list_alt_rounded),
                            const SizedBox(width: 12),
                            _statCard('Completed',
                                '${_stats!['completed'] ?? 0}',
                                AppTheme.completed,
                                Icons.check_circle_rounded),
                            const SizedBox(width: 12),
                            _statCard('In Progress',
                                '${_stats!['in_progress'] ?? 0}',
                                AppTheme.inProgress,
                                Icons.pending_rounded),
                            const SizedBox(width: 12),
                            _statCard('Pending',
                                '${_stats!['reported'] ?? 0}',
                                AppTheme.reported,
                                Icons.flag_rounded),
                          ]),
                          const SizedBox(height: 16),
                          _resolutionRateCard(
                              (_stats!['resolution_rate'] ?? 0.0)
                                  .toDouble()),
                        ] else
                          const Center(
                              child: Text('Could not load stats')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Issue role card — explains what this officer handles ──────────────────
  Widget _issueRoleCard() {
    final role = OfficerSession.role ?? '';
    final category = OfficerSession.category ?? '';

    // Build list of what this officer handles based on role + category
    final List<String> workItems = _getWorkItems(role, category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.work_rounded, color: _roleColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_roleLabel,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _roleColor,
                            fontSize: 14)),
                    Text(_formatCategory(category),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...workItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: _roleColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _getWorkItems(String role, String category) {
    if (role == 'head') {
      return [
        'View ALL issues across all 8 departments',
        'Monitor and compare department performance',
        'Reassign issues to any officer in any department',
        'Escalate high-priority issues',
        'View individual officer and department-level stats',
      ];
    }
    if (role == 'dept_head') {
      final Map<String, List<String>> deptWork = {
        'ROAD': [
          'Oversee all road-related complaints in your department',
          'Reassign issues to Road Inspectors, Engineers or Supervisors',
          'Monitor performance of 4 field officers under you',
          'Escalate urgent road issues to Municipal Commissioner',
        ],
        'WATER': [
          'Oversee all water-related complaints in your department',
          'Reassign pipe issues to Pipe Repair Engineer',
          'Reassign borewell/pump issues to Borewell Officer',
          'Monitor performance of 4 field officers under you',
        ],
        'ELECTRICITY': [
          'Oversee all electricity-related complaints in your department',
          'Reassign line/outage issues to Line Maintenance Officer',
          'Reassign transformer issues to Transformer Engineer',
          'Monitor performance of 3 field officers under you',
        ],
        'SANITATION': [
          'Oversee all sanitation-related complaints in your department',
          'Reassign garbage issues to Waste Management Officer',
          'Reassign drain issues to Drainage Supervisor',
          'Monitor performance of 5 field officers under you',
        ],
        'ENVIRONMENT': [
          'Oversee all environment-related complaints in your department',
          'Reassign pollution issues to Pollution Control Officer',
          'Reassign park/tree issues to Green Belt Officer',
          'Monitor performance of 3 field officers under you',
        ],
        'SAFETY': [
          'Oversee all safety-related complaints in your department',
          'Reassign accident/fire issues to Prevention Officer',
          'Reassign encroachment issues to Traffic Safety Officer',
          'Monitor performance of 3 field officers under you',
        ],
        'STREET_LIGHT': [
          'Oversee all street light complaints in your department',
          'Reassign maintenance issues to Electrical Maintenance Officer',
          'Reassign new installation requests to Installation Officer',
          'Monitor performance of 3 field officers under you',
        ],
        'OTHER': [
          'Oversee all general/miscellaneous complaints',
          'Reassign issues to appropriate field officers',
          'Monitor performance of 3 field officers under you',
          'Handle manually typed issues that don\'t fit other categories',
        ],
      };
      return deptWork[category] ?? ['Manage and oversee your department'];
    }

    // Regular officer — specific work based on designation
    final designation = OfficerSession.designation ?? '';
    final Map<String, List<String>> officerWork = {
      'Junior Engineer (Roads)': [
        'Handles: Road damage / crack',
        'Handles: Speed breaker needed',
        'Inspect road quality and assess repair needs',
        'Coordinate with contractors for road construction',
      ],
      'Pothole Repair Supervisor': [
        'Handles: Pothole on road',
        'Handles: Road waterlogging',
        'Supervise pothole filling teams',
        'Monitor repair quality and completion',
      ],
      'Road Survey Officer': [
        'Handles: Encroachment on road',
        'Handles: Missing road signs / signals',
        'Conduct road surveys and measurements',
        'Report encroachments and missing signage',
      ],
      'Bridge & Footpath Inspector': [
        'Handles: Damaged footpath / pavement',
        'Handles: Missing road divider',
        'Inspect bridges and footpaths for damage',
        'Coordinate repairs for dividers and pavements',
      ],
      'Pipe Repair Engineer': [
        'Handles: Water leakage in pipe',
        'Inspect and repair broken/leaking water pipes',
        'Coordinate with plumbing teams for urgent fixes',
      ],
      'Borewell & Pump Officer': [
        'Handles: Water supply disruption',
        'Handles: Low water pressure',
        'Handles: Borewell not working',
        'Maintain and repair borewells and pumping stations',
      ],
      'Drainage & Sewage Engineer': [
        'Handles: Drainage overflow',
        'Inspect and clear blocked sewage and drainage lines',
        'Coordinate with drainage cleaning teams',
      ],
      'Water Quality Inspector': [
        'Handles: Contaminated / dirty water',
        'Handles: Water meter issue',
        'Handles: Illegal water connection',
        'Test water quality and take corrective action',
        'Inspect meters and unauthorized connections',
      ],
      'Line Maintenance Officer': [
        'Handles: Power outage in area',
        'Handles: Sparking / hanging wire',
        'Handles: Fallen electric pole',
        'Handles: Electric shock hazard',
        'Handles: Street light power failure',
        'Restore power and fix dangerous wire situations',
      ],
      'Transformer & Sub-Station Engineer': [
        'Handles: Transformer fault',
        'Handles: High voltage fluctuation',
        'Repair and maintain transformers and substations',
      ],
      'Meter & Connection Inspector': [
        'Handles: Meter tampering',
        'Inspect meters and illegal connections',
        'Report and disconnect unauthorized electricity connections',
      ],
      'Solid Waste Management Officer': [
        'Handles: Garbage not collected',
        'Handles: Overflowing dustbin / dumpyard',
        'Coordinate garbage collection vehicles and schedules',
      ],
      'Drainage & Nala Supervisor': [
        'Handles: Blocked drain / nala',
        'Handles: Bad odour from drain',
        'Supervise drain cleaning and nala clearing operations',
      ],
      'Sweeping & Cleaning Supervisor': [
        'Handles: Open defecation area',
        'Handles: Sanitation workers absent',
        'Manage daily sweeping and cleaning schedules',
      ],
      'Public Toilet Maintenance Officer': [
        'Handles: Public toilet issue (Sanitation)',
        'Inspect and maintain public toilet facilities',
        'Ensure cleanliness and water availability in toilets',
      ],
      'Pest & Mosquito Control Officer': [
        'Handles: Mosquito / pest breeding site',
        'Conduct fogging and pest control operations',
        'Identify and treat mosquito breeding areas',
      ],
      'Pollution Control Officer': [
        'Handles: Illegal garbage dumping',
        'Handles: Air pollution from factory / vehicle',
        'Handles: Noise pollution',
        'Monitor pollution levels and take enforcement action',
      ],
      'Green Belt & Garden Officer': [
        'Handles: Tree fallen on road',
        'Handles: Encroachment on green belt / garden',
        'Maintain parks, gardens, and green zones',
        'Arrange tree removal/trimming when needed',
      ],
      'River & Lake Conservation Officer': [
        'Handles: Stray animal menace',
        'Handles: River / lake pollution',
        'Monitor rivers and lakes for pollution',
        'Coordinate with animal control for stray animals',
      ],
      'Field Safety Inspector': [
        'Handles: Road accident spot',
        'Inspect reported hazardous locations',
        'Coordinate with police and emergency services',
      ],
      'Fire & Accident Prevention Officer': [
        'Handles: Suspicious activity / crime',
        'Handles: Fire hazard',
        'Handles: Missing person',
        'Handles: Drug / alcohol nuisance',
        'Handles: Street harassment',
        'Inspect fire risks and coordinate prevention measures',
      ],
      'Traffic Safety & Encroachment Officer': [
        'Handles: Illegal construction',
        'Inspect traffic safety issues and road encroachments',
        'Coordinate with police for illegal constructions',
      ],
      'Electrical Maintenance Officer': [
        'Handles: Street light not working',
        'Handles: Flickering street light',
        'Handles: Wire exposed on light pole',
        'Repair and maintain electrical systems of street lights',
      ],
      'Light Pole & Fixture Inspector': [
        'Handles: Damaged light pole',
        'Handles: Light on during daytime (wastage)',
        'Inspect light poles for physical damage',
        'Fix or replace broken fixtures and timers',
      ],
      'New Installation & Wiring Officer': [
        'Handles: New street light needed',
        'Plan and install new street light poles and wiring',
        'Coordinate with contractors for new installations',
      ],
      'General Civic Officer': [
        'Handles: Government property damage',
        'Handles: Public toilet issue (Other)',
        'Handles: Stray cattle on road',
        'Handles manually typed issues in Other category',
      ],
      'Building & Encroachment Officer': [
        'Handles: Encroachment on public land',
        'Inspect and report illegal buildings and encroachments',
        'Initiate action against unauthorized constructions',
      ],
      'Public Property & Parks Officer': [
        'Handles: Park / garden not maintained',
        'Handles: Bus stop damaged',
        'Maintain public parks, bus stops, and civic property',
      ],
    };

    return officerWork[designation] ?? [
      'Handle issues assigned to you in the Issues screen',
      'Update issue status and add remarks',
      'Fill solver details when marking issues as completed',
    ];
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark));
  }

  Widget _detailRow(IconData icon, String label, String value,
      {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: mono ? 'Courier New' : null,
                color: mono ? AppTheme.primary : Colors.black87,
              )),
        ),
      ]),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.grey.shade100);

  Widget _statCard(String label, String value, Color color, IconData icon) {
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
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ]),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resolutionRateCard(double rate) {
    final color = rate >= 80
        ? AppTheme.completed
        : rate >= 50
            ? AppTheme.inProgress
            : AppTheme.reported;
    final message = rate >= 80
        ? '🌟 Excellent performance!'
        : rate >= 50
            ? '👍 Good — keep improving'
            : '⚠️ Needs attention';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          // Circular rate display
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
            ),
            child: Center(
              child: Text('$rate%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resolution Rate',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primaryDark)),
                const SizedBox(height: 4),
                Text(message,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Percentage of assigned issues marked as Completed',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}