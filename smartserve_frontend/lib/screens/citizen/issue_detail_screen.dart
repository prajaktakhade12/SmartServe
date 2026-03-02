import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/user_session.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class IssueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> issue;
  final String selectedLanguage;
  const IssueDetailScreen({Key? key, required this.issue, required this.selectedLanguage}) : super(key: key);

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  late Map<String, dynamic> _issue;
  int _selectedRating = 0;
  final _commentCtrl = TextEditingController();
  bool _submittingRating = false;
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
    _selectedRating = _issue['rating'] ?? 0;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) return;
    setState(() => _submittingRating = true);
    final result = await ApiService.rateIssue(_issue['id'], _selectedRating);
    setState(() => _submittingRating = false);
    if (!mounted) return;
    if (result['error'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted! +5 Civic Points 🌟'), backgroundColor: Colors.green));
      setState(() => _issue['rating'] = _selectedRating);
    }
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _submittingComment = true);
    final result = await ApiService.addComment(
      _issue['id'],
      UserSession.mobile ?? '',
      UserSession.name ?? '',
      _commentCtrl.text.trim(),
    );
    setState(() => _submittingComment = false);
    if (!mounted) return;
    if (result['error'] == null) {
      _commentCtrl.clear();
      final updated = await ApiService.getIssueDetail(_issue['id']);
      if (updated['error'] == null) setState(() => _issue = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added!'), backgroundColor: Colors.green));
    }
  }

  void _shareIssue() {
    final text = '''
SmartServe Issue Report
📋 Title: ${_issue['title']}
📂 Category: ${_issue['category']}
📍 Location: ${_issue['location']}
🚦 Status: ${_issue['status']}
📅 Reported: ${_issue['created_at']}
${_issue['description']}
''';
    Share.share(text, subject: 'Issue Report: ${_issue['title']}');
  }

  @override
  Widget build(BuildContext context) {
    final status = _issue['status'] ?? 'REPORTED';
    final category = _issue['category'] ?? 'OTHER';
    final color = AppTheme.getStatusColor(status);
    final catColor = AppTheme.getCategoryColor(category);
    final history = _issue['history'] as List? ?? [];
    final comments = _issue['comments'] as List? ?? [];
    final isCompleted = status == 'COMPLETED';
    final hasRating = _issue['rating'] != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]))),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareIssue,
            tooltip: 'Share Issue',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Row(children: [
                Icon(_statusIcon(status), color: color, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Status', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(status.replaceAll('_', ' '),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // Main info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                      child: Icon(_categoryIcon(category), color: catColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_issue['title'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(category.replaceAll('_', ' '), style: TextStyle(color: catColor, fontSize: 13)),
                    ])),
                  ]),
                  const Divider(height: 24),
                  _detailRow(Icons.person_rounded, 'Name', _issue['name'] ?? ''),
                  _detailRow(Icons.phone_rounded, 'Mobile', _issue['mobile'] ?? ''),
                  _detailRow(Icons.location_on_rounded, 'Location', _issue['location'] ?? ''),
                  _detailRow(Icons.calendar_today_rounded, 'Submitted', _issue['created_at'] ?? ''),
                  _detailRow(Icons.update_rounded, 'Updated', _issue['updated_at'] ?? ''),
                  const Divider(height: 24),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  Text(_issue['description'] ?? '', style: const TextStyle(fontSize: 14, height: 1.6)),
                ]),
              ),
            ),

            // Image
            if (_issue['image'] != null) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${ApiService.baseUrl.replaceAll('/api', '')}${_issue['image']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 60),
                      ),
                    ),
                  ]),
                ),
              ),
            ],

            // Officer remarks
            if ((_issue['officer_remarks'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.comment_rounded, color: Colors.purple.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text('Officer Remarks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                  ]),
                  const SizedBox(height: 8),
                  Text(_issue['officer_remarks'], style: TextStyle(color: Colors.purple.shade900, fontSize: 13, height: 1.5)),
                ]),
              ),
            ],

            // Status Timeline
            if (history.isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
                    const SizedBox(height: 14),
                    ...history.asMap().entries.map((e) {
                      final h = e.value;
                      final isLast = e.key == history.length - 1;
                      final hColor = AppTheme.getStatusColor(h['status']);
                      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Column(children: [
                          Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(color: hColor, shape: BoxShape.circle)),
                          if (!isLast) Container(width: 2, height: 40, color: Colors.grey.shade300),
                        ]),
                        const SizedBox(width: 12),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h['status'].replaceAll('_', ' '),
                                style: TextStyle(fontWeight: FontWeight.bold, color: hColor)),
                            if ((h['note'] ?? '').isNotEmpty)
                              Text(h['note'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(h['changed_at'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ]),
                        )),
                      ]);
                    }).toList(),
                  ]),
                ),
              ),
            ],

            // Rating (only if completed and not yet rated)
            if (isCompleted) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Rate Resolution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
                    const SizedBox(height: 4),
                    Text(hasRating ? 'You rated this issue' : 'How satisfied are you with the resolution?',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
                      IconButton(
                        icon: Icon(
                          i < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber, size: 36),
                        onPressed: hasRating ? null : () => setState(() => _selectedRating = i + 1),
                      ),
                    )),
                    if (!hasRating && _selectedRating > 0) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submittingRating ? null : _submitRating,
                          child: _submittingRating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Submit Rating (+5 pts)'),
                        ),
                      ),
                    ],
                    if (hasRating) ...[
                      const SizedBox(height: 8),
                      Center(child: Text('You gave ${_issue['rating']} ⭐',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber))),
                    ],
                  ]),
                ),
              ),
            ],

            // Comments section - only visible after officer posts remarks
            if ((_issue['officer_remarks'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.question_answer_rounded, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Comments on Officer\'s Solution (${comments.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
                    ]),
                    const SizedBox(height: 4),
                    const Text('Reply to the officer\'s solution below',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),

                    // Add comment
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Reply to officer\'s solution...',
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submittingComment ? null : _submitComment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(14),
                          shape: const CircleBorder()),
                        child: _submittingComment
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 18),
                      ),
                    ]),

                    if (comments.isNotEmpty) ...[
                      const Divider(height: 24),
                      ...comments.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primary.withOpacity(0.15),
                            child: Text((c['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(c['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(c['created_at'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ]),
                            const SizedBox(height: 4),
                            Text(c['comment'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4)),
                          ])),
                        ]),
                      )).toList(),
                    ],
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'COMPLETED': return Icons.check_circle_rounded;
      case 'IN_PROGRESS': return Icons.pending_rounded;
      default: return Icons.flag_rounded;
    }
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
}