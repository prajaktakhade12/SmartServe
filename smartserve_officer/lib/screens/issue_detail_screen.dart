import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../core/officer_session.dart';
import '../core/officer_strings.dart';

class IssueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> issue;
  final VoidCallback? onUpdated;
  final String language;

  const IssueDetailScreen({
    super.key,
    required this.issue,
    required this.language,
    this.onUpdated,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  late Map<String, dynamic> _issue;
  bool _loading = false;
  String _selectedStatus = '';
  final _remarksCtrl        = TextEditingController();
  final _solverNameCtrl     = TextEditingController();
  final _solverMobileCtrl   = TextEditingController();
  final _solverDesigCtrl    = TextEditingController();
  final _workDoneCtrl       = TextEditingController();
  DateTime? _resolutionDate;

  // For reassign dropdown
  List<dynamic> _officerList = [];
  int? _reassignOfficerId;

  String get _lang => widget.language;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
    _selectedStatus       = _issue['status'] ?? 'REPORTED';
    _remarksCtrl.text     = _issue['officer_remarks'] ?? '';
    _solverNameCtrl.text  = _issue['solver_name'] ?? '';
    _solverMobileCtrl.text= _issue['solver_mobile'] ?? '';
    _solverDesigCtrl.text = _issue['solver_designation'] ?? '';
    _workDoneCtrl.text    = _issue['work_done'] ?? '';
    final rd = _issue['resolution_date'] ?? '';
    if (rd.isNotEmpty) {
      try { _resolutionDate = DateTime.parse(rd); } catch (_) {}
    }
    _loadOfficerList();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    _solverNameCtrl.dispose();
    _solverMobileCtrl.dispose();
    _solverDesigCtrl.dispose();
    _workDoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOfficerList() async {
    if (!OfficerSession.canManageIssues) return;
    final category = OfficerSession.role == 'head'
        ? (_issue['category'] ?? '')
        : (OfficerSession.category ?? '');
    final list = await ApiService.getOfficerList(category);
    if (mounted) setState(() => _officerList = list);
  }

  bool _validateSolverDetails() {
    if (_selectedStatus != 'COMPLETED') return true;
    if (_solverNameCtrl.text.trim().isEmpty)  { _snack(OfficerStrings.text('solver_name_req',  _lang), Colors.orange); return false; }
    if (_solverMobileCtrl.text.trim().isEmpty){ _snack(OfficerStrings.text('solver_mobile_req',_lang), Colors.orange); return false; }
    if (_solverMobileCtrl.text.trim().length != 10){ _snack('Solver Mobile must be exactly 10 digits', Colors.orange); return false; }
    if (_solverDesigCtrl.text.trim().isEmpty) { _snack(OfficerStrings.text('solver_desig_req', _lang), Colors.orange); return false; }
    if (_workDoneCtrl.text.trim().isEmpty)    { _snack(OfficerStrings.text('work_done_req',    _lang), Colors.orange); return false; }
    if (_resolutionDate == null)              { _snack(OfficerStrings.text('date_req',          _lang), Colors.orange); return false; }
    if (_remarksCtrl.text.trim().isEmpty)     { _snack(OfficerStrings.text('remarks_required',  _lang), Colors.orange); return false; }
    return true;
  }

  Future<void> _updateStatus() async {
    if (!_validateSolverDetails()) return;
    if (_remarksCtrl.text.trim().isEmpty) {
      _snack(OfficerStrings.text('remarks_required', _lang), Colors.orange);
      return;
    }
    setState(() => _loading = true);

    Map<String, dynamic>? solverDetails;
    if (_selectedStatus == 'COMPLETED') {
      solverDetails = {
        'solver_name':        _solverNameCtrl.text.trim(),
        'solver_mobile':      _solverMobileCtrl.text.trim(),
        'solver_designation': _solverDesigCtrl.text.trim(),
        'work_done':          _workDoneCtrl.text.trim(),
        'resolution_date':    _resolutionDate!.toIso8601String().split('T')[0],
      };
    }

    final result = await ApiService.updateIssueStatus(
      _issue['id'],
      _selectedStatus,
      _remarksCtrl.text.trim(),
      solverDetails: solverDetails,
      officerId: OfficerSession.id,
      officerName: OfficerSession.name,
    );
    setState(() => _loading = false);

    if (result.containsKey('error')) {
      _snack(result['error'], Colors.red);
    } else {
      setState(() => _issue = result['issue']);
      _snack(OfficerStrings.text('updated_success', _lang), AppTheme.completed);
      widget.onUpdated?.call();
    }
  }

  Future<void> _reassign() async {
    if (_reassignOfficerId == null) return;
    final result = await ApiService.reassignIssue(
        _issue['id'], _reassignOfficerId!, OfficerSession.role ?? '');
    if (result.containsKey('error')) {
      _snack(result['error'], Colors.red);
    } else {
      setState(() => _issue = result['issue']);
      _snack('Issue reassigned successfully', AppTheme.completed);
      widget.onUpdated?.call();
    }
  }

  Future<void> _escalate() async {
    // Show a dialog to enter escalation note
    String note = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Text(_lang == 'hi' ? 'एस्केलेट करें'
              : _lang == 'mr' ? 'एस्केलेट करा'
              : 'Escalate Issue'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            _lang == 'hi'
                ? 'इस समस्या को उच्च प्राथमिकता पर चिह्नित करें। नागरिक को सूचित किया जाएगा।'
                : _lang == 'mr'
                    ? 'या समस्येला उच्च प्राधान्य म्हणून चिन्हांकित करा. नागरिकाला सूचित केले जाईल.'
                    : 'Mark this issue as high priority. The citizen will be notified.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              hintText: _lang == 'hi' ? 'एस्केलेशन कारण (वैकल्पिक)'
                  : _lang == 'mr' ? 'एस्केलेशन कारण (पर्यायी)'
                  : 'Reason for escalation (optional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (v) => note = v,
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_lang == 'hi' ? 'रद्द करें'
                : _lang == 'mr' ? 'रद्द करा' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(_lang == 'hi' ? 'एस्केलेट करें'
                : _lang == 'mr' ? 'एस्केलेट करा' : 'Escalate',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.escalateIssue(
      _issue['id'],
      note.isNotEmpty ? note : 'Issue escalated for priority resolution.',
      OfficerSession.role ?? '',
    );
    if (result.containsKey('error')) {
      _snack(result['error'], Colors.red);
    } else {
      setState(() => _issue = result['issue']);
      _snack(
        _lang == 'hi' ? 'समस्या एस्केलेट की गई!'
            : _lang == 'mr' ? 'समस्या एस्केलेट केली!'
            : 'Issue escalated successfully!',
        Colors.orange,
      );
      widget.onUpdated?.call();
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                    child: Text(OfficerStrings.text('image_unavailable', _lang),
                        style: const TextStyle(color: Colors.white)))),
          ),
          Positioned(
            top: 10, right: 10,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status   = _issue['status'] ?? 'REPORTED';
    final category = _issue['category'] ?? '';
    final statusColor = AppTheme.getStatusColor(status);
    final catColor    = AppTheme.getCategoryColor(category);
    final history     = (_issue['history'] as List?) ?? [];
    final imageUrl    = _issue['image'] != null
        ? '${ApiService.baseUrl.replaceAll('/api', '')}${_issue['image']}'
        : null;
    final assignedName = _issue['assigned_officer_name'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_issue['display_id'] ?? '${OfficerStrings.text("issue_id", _lang)}${_issue["id"]}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              OfficerStrings.status(status, _lang),
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
      body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── LEFT: Issue Info ────────────────────────────────────────────────
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Title row
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(AppTheme.getCategoryIcon(category),
                      color: catColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_issue['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark)),
                    const SizedBox(height: 4),
                    Text(OfficerStrings.category(category, _lang),
                        style: TextStyle(
                            color: catColor, fontWeight: FontWeight.w600)),
                  ],
                )),
              ]),
              const SizedBox(height: 24),

              // Info cards
              Row(children: [
                _infoCard(Icons.person_rounded,
                    OfficerStrings.text('citizen', _lang), _issue['name'] ?? ''),
                const SizedBox(width: 12),
                _infoCard(Icons.phone_rounded,
                    OfficerStrings.text('mobile', _lang), _issue['mobile'] ?? ''),
                const SizedBox(width: 12),
                _infoCard(Icons.location_on_rounded,
                    OfficerStrings.text('location', _lang), _issue['location'] ?? ''),
                const SizedBox(width: 12),
                _infoCard(Icons.calendar_today_rounded,
                    OfficerStrings.text('reported_on', _lang), _issue['created_at'] ?? ''),
              ]),

              // Assigned officer chip
              if (assignedName.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.engineering_rounded,
                        color: AppTheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${OfficerStrings.text('assigned_to', _lang)}: $assignedName',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 20),

              // Description
              Card(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(OfficerStrings.text('description', _lang),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.primaryDark)),
                  const SizedBox(height: 12),
                  Text(_issue['description'] ?? '',
                      style: TextStyle(
                          color: Colors.grey.shade700, height: 1.6, fontSize: 14)),
                ]),
              )),

              // Photo
              if (imageUrl != null) ...[
                const SizedBox(height: 16),
                Card(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(OfficerStrings.text('photo_evidence', _lang),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.primaryDark)),
                      TextButton.icon(
                        onPressed: () => _showPhoto(imageUrl),
                        icon: const Icon(Icons.zoom_in_rounded),
                        label: Text(OfficerStrings.text('view_full_size', _lang)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showPhoto(imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(imageUrl,
                            height: 220, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80, color: Colors.grey.shade100,
                              child: Center(child: Text(
                                OfficerStrings.text('image_unavailable', _lang))))),
                      ),
                    ),
                  ]),
                )),
              ],

              // Resolution details (if completed)
              if ((_issue['solver_name'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.completed),
                        const SizedBox(width: 8),
                        Text(OfficerStrings.text('resolution_details', _lang),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.completed)),
                      ]),
                      const SizedBox(height: 14),
                      _solverRow(OfficerStrings.text('solved_by', _lang),   _issue['solver_name'] ?? ''),
                      _solverRow(OfficerStrings.text('mobile', _lang),       _issue['solver_mobile'] ?? ''),
                      _solverRow(OfficerStrings.text('designation', _lang),  _issue['solver_designation'] ?? ''),
                      _solverRow(OfficerStrings.text('work_done', _lang),    _issue['work_done'] ?? ''),
                      _solverRow(OfficerStrings.text('resolution_date', _lang), _issue['resolution_date'] ?? ''),
                    ]),
                  ),
                ),
              ],

              // Status timeline
              if (history.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(OfficerStrings.text('status_timeline', _lang),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.primaryDark)),
                    const SizedBox(height: 16),
                    ...history.asMap().entries.map((e) {
                      final h = e.value;
                      final isLast = e.key == history.length - 1;
                      final hColor = AppTheme.getStatusColor(h['status']);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [
                            Container(width: 14, height: 14,
                                decoration: BoxDecoration(
                                    color: hColor, shape: BoxShape.circle)),
                            if (!isLast)
                              Container(width: 2, height: 40,
                                  color: Colors.grey.shade300),
                          ]),
                          const SizedBox(width: 14),
                          Expanded(child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(OfficerStrings.status(h['status'], _lang),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: hColor)),
                                if ((h['note'] ?? '').isNotEmpty)
                                  Text(h['note'],
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13)),
                                Text(h['changed_at'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11)),
                              ],
                            ),
                          )),
                        ],
                      );
                    }),
                  ]),
                )),
              ],
            ]),
          ),
        ),

        // ── RIGHT: Action Panel (role-based) ───────────────────────────────
        Container(
          width: 360,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20, offset: const Offset(-5, 0))],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: OfficerSession.isHead
                ? _buildHeadPanel()       // Head: Reassign + Escalate only
                : _buildOfficerPanel(),   // Dept head / Officer: Status update
          ),
        ),
      ]),
    );
  }

  // ── HEAD OFFICER panel — Reassign + Escalate ONLY ─────────────────────────
  Widget _buildHeadPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Header
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFB8860B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.admin_panel_settings_rounded,
              color: Color(0xFFB8860B), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _lang == 'hi' ? 'मुख्य अधिकारी नियंत्रण'
                  : _lang == 'mr' ? 'मुख्य अधिकारी नियंत्रण'
                  : 'Head Officer Controls',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark),
            ),
            Text(
              _lang == 'hi' ? 'पुनः आवंटित करें या एस्केलेट करें'
                  : _lang == 'mr' ? 'पुन्हा नियुक्त करा किंवा एस्केलेट करा'
                  : 'You can reassign or escalate issues',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        )),
      ]),

      const SizedBox(height: 12),

      // Info note explaining why head can't update status
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.blue.shade600, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _lang == 'hi'
                    ? 'स्थिति अपडेट केवल संबंधित विभाग के अधिकारी कर सकते हैं। आप समस्या को पुनः आवंटित या एस्केलेट कर सकते हैं।'
                    : _lang == 'mr'
                        ? 'स्थिती अपडेट केवळ संबंधित विभागाचे अधिकारी करू शकतात. तुम्ही समस्या पुन्हा नियुक्त किंवा एस्केलेट करू शकता.'
                        : 'Status updates are done by the assigned field officer. As Head Officer, you can reassign or escalate issues.',
                style: TextStyle(
                    fontSize: 11, color: Colors.blue.shade700),
              ),
            ),
          ],
        ),
      ),

      const Divider(height: 32),

      // ── Reassign ─────────────────────────────────────────────────────────
      Row(children: [
        const Icon(Icons.swap_horiz_rounded,
            color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          OfficerStrings.text('reassign', _lang),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15, color: AppTheme.primaryDark),
        ),
      ]),
      const SizedBox(height: 4),
      Text(
        _lang == 'hi' ? 'किसी भी विभाग के अधिकारी को आवंटित करें'
            : _lang == 'mr' ? 'कोणत्याही विभागाच्या अधिकाऱ्याला नियुक्त करा'
            : 'Assign to any officer in this category',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      const SizedBox(height: 10),

      if (_officerList.isEmpty)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _lang == 'hi' ? 'अधिकारी लोड हो रहे हैं...'
                  : _lang == 'mr' ? 'अधिकारी लोड होत आहेत...'
                  : 'Loading officers...',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        )
      else ...[
        DropdownButtonFormField<int>(
          value: _reassignOfficerId,
          isExpanded: true,
          hint: Text(OfficerStrings.text('select_officer', _lang)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_search_rounded),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _officerList
              .where((o) => o['role'] == 'officer')
              .map<DropdownMenuItem<int>>((o) => DropdownMenuItem(
                    value: o['id'] as int,
                    child: Text(
                      '${o['name']} — ${o['designation']}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _reassignOfficerId = v),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _reassignOfficerId == null ? null : _reassign,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(OfficerStrings.text('reassign', _lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],

      const Divider(height: 36),

      // ── Escalate ──────────────────────────────────────────────────────────
      Row(children: [
        const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 18),
        const SizedBox(width: 8),
        Text(
          OfficerStrings.text('escalate', _lang),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15, color: AppTheme.primaryDark),
        ),
      ]),
      const SizedBox(height: 4),
      Text(
        _lang == 'hi' ? 'उच्च प्राथमिकता के रूप में चिह्नित करें — नागरिक को सूचित किया जाएगा'
            : _lang == 'mr' ? 'उच्च प्राधान्य म्हणून चिन्हांकित करा — नागरिकाला सूचित केले जाईल'
            : 'Mark as high priority — citizen will be notified',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _escalate,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          label: Text(
            OfficerStrings.text('escalate', _lang),
            style: const TextStyle(color: Colors.orange),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    ]);
  }

  // ── DEPT HEAD / OFFICER panel — Status update + optional reassign ─────────
  Widget _buildOfficerPanel() {
    final isDeptHead = OfficerSession.isDeptHead;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Text(OfficerStrings.text('update_issue', _lang),
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark)),
      const SizedBox(height: 4),
      Text(OfficerStrings.text('change_status', _lang),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      const Divider(height: 32),

      // Status selection
      Text(OfficerStrings.text('update_status', _lang),
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13,
              color: Colors.grey.shade600)),
      const SizedBox(height: 8),

      ...[
        ('REPORTED',    AppTheme.reported,   Icons.flag_rounded),
        ('IN_PROGRESS', AppTheme.inProgress, Icons.pending_rounded),
        ('COMPLETED',   AppTheme.completed,  Icons.check_circle_rounded),
      ].map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedStatus = s.$1),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedStatus == s.$1
                  ? s.$2.withOpacity(0.15) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedStatus == s.$1
                    ? s.$2 : Colors.grey.shade200,
                width: _selectedStatus == s.$1 ? 2 : 1),
            ),
            child: Row(children: [
              Icon(
                _selectedStatus == s.$1
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: _selectedStatus == s.$1 ? s.$2 : Colors.grey,
                size: 20),
              const SizedBox(width: 10),
              Icon(s.$3, color: s.$2, size: 18),
              const SizedBox(width: 8),
              Text(
                OfficerStrings.status(s.$1, _lang),
                style: TextStyle(
                  fontWeight: _selectedStatus == s.$1
                      ? FontWeight.bold : FontWeight.normal,
                  color: _selectedStatus == s.$1
                      ? s.$2 : Colors.grey.shade700),
              ),
            ]),
          ),
        ),
      )),

      const SizedBox(height: 16),

      // Remarks
      Text(OfficerStrings.text('remarks', _lang),
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13,
              color: Colors.grey.shade600)),
      const SizedBox(height: 8),
      TextField(
        controller: _remarksCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: OfficerStrings.text('remarks_hint', _lang),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          filled: true, fillColor: Colors.grey.shade50),
      ),

      // Solver details — only for COMPLETED
      if (_selectedStatus == 'COMPLETED') ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.engineering_rounded,
                  color: AppTheme.completed, size: 18),
              const SizedBox(width: 8),
              Text(OfficerStrings.text('solver_details', _lang),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.completed, fontSize: 14)),
            ]),
            const SizedBox(height: 14),
            _solverField(OfficerStrings.text('solver_name', _lang),
                _solverNameCtrl, Icons.person_rounded),
            const SizedBox(height: 10),
            _solverField(OfficerStrings.text('solver_mobile', _lang),
                _solverMobileCtrl, Icons.phone_rounded,
                type: TextInputType.phone),
            const SizedBox(height: 10),
            _solverField(OfficerStrings.text('solver_designation', _lang),
                _solverDesigCtrl, Icons.badge_rounded),
            const SizedBox(height: 10),
            TextField(
              controller: _workDoneCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: OfficerStrings.text('work_done', _lang),
                prefixIcon: const Icon(Icons.build_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _resolutionDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _resolutionDate != null
                        ? '${_resolutionDate!.day}/${_resolutionDate!.month}/${_resolutionDate!.year}'
                        : OfficerStrings.text('resolution_date', _lang),
                    style: TextStyle(
                      color: _resolutionDate != null
                          ? Colors.black87 : Colors.grey.shade500),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ],

      // Reassign — only for dept_head (NOT for regular officer)
      if (isDeptHead && _officerList.isNotEmpty) ...[
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Text(OfficerStrings.text('reassign', _lang),
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13,
                color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _reassignOfficerId,
          isExpanded: true,
          hint: Text(OfficerStrings.text('select_officer', _lang)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_search_rounded),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            filled: true, fillColor: Colors.grey.shade50),
          items: _officerList
              .where((o) => o['role'] == 'officer')
              .map<DropdownMenuItem<int>>((o) => DropdownMenuItem(
                    value: o['id'] as int,
                    child: Text('${o['name']} — ${o['designation']}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _reassignOfficerId = v),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _reassignOfficerId == null ? null : _reassign,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(OfficerStrings.text('reassign', _lang)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],

      const SizedBox(height: 20),

      // Update button
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _updateStatus,
          icon: _loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_rounded),
          label: Text(
            _loading
                ? OfficerStrings.text('updating', _lang)
                : OfficerStrings.text('update_issue', _lang),
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────
  Widget _solverField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text}) {
    final isPhone = type == TextInputType.phone;
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLength: isPhone ? 10 : null,
      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        counterText: isPhone ? '' : null, // hide the "0/10" counter text
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        // Show red hint when length < 10 on phone fields
        helperText: isPhone ? '10 digits required' : null,
        helperStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  Widget _solverRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ),
        Expanded(child: Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}