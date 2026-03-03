import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class IssueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> issue;
  final VoidCallback? onUpdated;
  const IssueDetailScreen({super.key, required this.issue, this.onUpdated});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  late Map<String, dynamic> _issue;
  bool _loading = false;
  String _selectedStatus = '';
  final _remarksCtrl = TextEditingController();
  final _solverNameCtrl = TextEditingController();
  final _solverMobileCtrl = TextEditingController();
  final _solverDesignationCtrl = TextEditingController();
  final _workDoneCtrl = TextEditingController();
  DateTime? _resolutionDate;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
    _selectedStatus = _issue['status'] ?? 'REPORTED';
    _remarksCtrl.text = _issue['officer_remarks'] ?? '';
    _solverNameCtrl.text = _issue['solver_name'] ?? '';
    _solverMobileCtrl.text = _issue['solver_mobile'] ?? '';
    _solverDesignationCtrl.text = _issue['solver_designation'] ?? '';
    _workDoneCtrl.text = _issue['work_done'] ?? '';
    final rd = _issue['resolution_date'] ?? '';
    if (rd.isNotEmpty) {
      try { _resolutionDate = DateTime.parse(rd); } catch (_) {}
    }
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    _solverNameCtrl.dispose();
    _solverMobileCtrl.dispose();
    _solverDesignationCtrl.dispose();
    _workDoneCtrl.dispose();
    super.dispose();
  }

  bool _validateSolverDetails() {
    if (_selectedStatus != 'COMPLETED') return true;
    if (_solverNameCtrl.text.trim().isEmpty) { _showSnack('Solver Name is required', Colors.orange); return false; }
    if (_solverMobileCtrl.text.trim().isEmpty) { _showSnack('Solver Mobile is required', Colors.orange); return false; }
    if (_solverDesignationCtrl.text.trim().isEmpty) { _showSnack('Solver Designation is required', Colors.orange); return false; }
    if (_workDoneCtrl.text.trim().isEmpty) { _showSnack('Work Done description is required', Colors.orange); return false; }
    if (_resolutionDate == null) { _showSnack('Resolution Date is required', Colors.orange); return false; }
    if (_remarksCtrl.text.trim().isEmpty) { _showSnack('Remarks are required', Colors.orange); return false; }
    return true;
  }

  Future<void> _updateStatus() async {
    if (!_validateSolverDetails()) return;
    if (_remarksCtrl.text.trim().isEmpty) {
      _showSnack('Please add remarks before updating', Colors.orange);
      return;
    }
    setState(() => _loading = true);

    Map<String, dynamic>? solverDetails;
    if (_selectedStatus == 'COMPLETED') {
      solverDetails = {
        'solver_name': _solverNameCtrl.text.trim(),
        'solver_mobile': _solverMobileCtrl.text.trim(),
        'solver_designation': _solverDesignationCtrl.text.trim(),
        'work_done': _workDoneCtrl.text.trim(),
        'resolution_date': _resolutionDate!.toIso8601String().split('T')[0],
      };
    }

    final result = await ApiService.updateIssueStatus(
      _issue['id'], _selectedStatus, _remarksCtrl.text.trim(),
      solverDetails: solverDetails);
    setState(() => _loading = false);

    if (result.containsKey('error')) {
      _showSnack(result['error'], Colors.red);
    } else {
      setState(() => _issue = result['issue']);
      _showSnack('Issue updated successfully!', AppTheme.completed);
      widget.onUpdated?.call();
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showPhoto(String url) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(children: [
        InteractiveViewer(
          minScale: 0.5, maxScale: 4.0,
          child: Image.network(url, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                  child: Text('Image not available',
                      style: TextStyle(color: Colors.white))))),
        Positioned(top: 10, right: 10,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context))),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final status = _issue['status'] ?? 'REPORTED';
    final category = _issue['category'] ?? '';
    final statusColor = AppTheme.getStatusColor(status);
    final catColor = AppTheme.getCategoryColor(category);
    final history = (_issue['history'] as List?) ?? [];
    final imageUrl = _issue['image'] != null
        ? '${ApiService.baseUrl.replaceAll('/api', '')}${_issue['image']}' : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Issue #${_issue['id']}',
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
              border: Border.all(color: statusColor)),
            child: Text(status.replaceAll('_', ' '),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // LEFT — Issue Info
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(AppTheme.getCategoryIcon(category), color: catColor, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_issue['title'] ?? '', style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  const SizedBox(height: 4),
                  Text(_formatCat(category),
                      style: TextStyle(color: catColor, fontWeight: FontWeight.w600)),
                ])),
              ]),
              const SizedBox(height: 24),

              // Info Cards
              Row(children: [
                _infoCard(Icons.person_rounded, 'Citizen', _issue['name'] ?? ''),
                const SizedBox(width: 12),
                _infoCard(Icons.phone_rounded, 'Mobile', _issue['mobile'] ?? ''),
                const SizedBox(width: 12),
                _infoCard(Icons.location_on_rounded, 'Location', _issue['location'] ?? ''),
                const SizedBox(width: 12),
                _infoCard(Icons.calendar_today_rounded, 'Reported', _issue['created_at'] ?? ''),
              ]),
              const SizedBox(height: 20),

              // Description
              Card(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Description', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark)),
                  const SizedBox(height: 12),
                  Text(_issue['description'] ?? '',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 14)),
                ]),
              )),

              // Photo
              if (imageUrl != null) ...[
                const SizedBox(height: 16),
                Card(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Photo Evidence', style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark)),
                      TextButton.icon(
                        onPressed: () => _showPhoto(imageUrl),
                        icon: const Icon(Icons.zoom_in_rounded),
                        label: const Text('View Full Size'),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showPhoto(imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(imageUrl, height: 220,
                            width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80, color: Colors.grey.shade100,
                              child: const Center(child: Text('Image not available')))),
                      ),
                    ),
                  ]),
                )),
              ],

              // Solver Details (if completed)
              if ((_issue['solver_name'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.verified_rounded, color: AppTheme.completed),
                        SizedBox(width: 8),
                        Text('Resolution Details', style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.completed)),
                      ]),
                      const SizedBox(height: 14),
                      _solverRow('Solved By', _issue['solver_name'] ?? ''),
                      _solverRow('Mobile', _issue['solver_mobile'] ?? ''),
                      _solverRow('Designation', _issue['solver_designation'] ?? ''),
                      _solverRow('Work Done', _issue['work_done'] ?? ''),
                      _solverRow('Resolution Date', _issue['resolution_date'] ?? ''),
                    ]),
                  ),
                ),
              ],

              // Timeline
              if (history.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Status Timeline', style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark)),
                    const SizedBox(height: 16),
                    ...history.asMap().entries.map((e) {
                      final h = e.value;
                      final isLast = e.key == history.length - 1;
                      final hColor = AppTheme.getStatusColor(h['status']);
                      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Column(children: [
                          Container(width: 14, height: 14,
                              decoration: BoxDecoration(color: hColor, shape: BoxShape.circle)),
                          if (!isLast) Container(width: 2, height: 40, color: Colors.grey.shade300),
                        ]),
                        const SizedBox(width: 14),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h['status'].replaceAll('_', ' '),
                                style: TextStyle(fontWeight: FontWeight.bold, color: hColor)),
                            if ((h['note'] ?? '').isNotEmpty)
                              Text(h['note'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            Text(h['changed_at'] ?? '',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                          ]),
                        )),
                      ]);
                    }).toList(),
                  ]),
                )),
              ],
            ]),
          ),
        ),

        // RIGHT — Update Panel
        Container(
          width: 360,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20, offset: const Offset(-5, 0))]),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Update Issue', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
              const SizedBox(height: 4),
              Text('Change status and add remarks',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const Divider(height: 32),

              // Status selection
              Text('Update Status', style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              ...[
                ('REPORTED', AppTheme.reported, Icons.flag_rounded),
                ('IN_PROGRESS', AppTheme.inProgress, Icons.pending_rounded),
                ('COMPLETED', AppTheme.completed, Icons.check_circle_rounded),
              ].map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _selectedStatus = s.$1),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedStatus == s.$1 ? s.$2.withOpacity(0.15) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedStatus == s.$1 ? s.$2 : Colors.grey.shade200,
                        width: _selectedStatus == s.$1 ? 2 : 1)),
                    child: Row(children: [
                      Icon(_selectedStatus == s.$1
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                          color: _selectedStatus == s.$1 ? s.$2 : Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Icon(s.$3, color: s.$2, size: 18),
                      const SizedBox(width: 8),
                      Text(s.$1.replaceAll('_', ' '), style: TextStyle(
                          fontWeight: _selectedStatus == s.$1 ? FontWeight.bold : FontWeight.normal,
                          color: _selectedStatus == s.$1 ? s.$2 : Colors.grey.shade700)),
                    ]),
                  ),
                ),
              )).toList(),

              const SizedBox(height: 16),

              // Remarks
              Text('Remarks *', style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              TextField(
                controller: _remarksCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe action taken...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: Colors.grey.shade50),
              ),

              // Solver Details (only for COMPLETED)
              if (_selectedStatus == 'COMPLETED') ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.engineering_rounded, color: AppTheme.completed, size: 18),
                      SizedBox(width: 8),
                      Text('Solver Details (Required)',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              color: AppTheme.completed, fontSize: 14)),
                    ]),
                    const SizedBox(height: 14),
                    _solverField('Solver Name *', _solverNameCtrl, Icons.person_rounded),
                    const SizedBox(height: 10),
                    _solverField('Solver Mobile *', _solverMobileCtrl, Icons.phone_rounded,
                        type: TextInputType.phone),
                    const SizedBox(height: 10),
                    _solverField('Designation/Role *', _solverDesignationCtrl,
                        Icons.badge_rounded),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _workDoneCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Work Done Description *',
                        prefixIcon: const Icon(Icons.build_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                : 'Resolution Date *',
                            style: TextStyle(
                              color: _resolutionDate != null
                                  ? Colors.black87 : Colors.grey.shade500)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _updateStatus,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: Text(_loading ? 'Updating...' : 'Update Issue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _solverField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true, fillColor: Colors.white),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  Widget _solverRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 13))),
        Expanded(child: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }

  String _formatCat(String cat) {
    if (cat == 'STREET_LIGHT') return 'Street Light';
    if (cat.isEmpty) return '';
    return cat[0] + cat.substring(1).toLowerCase();
  }
}
