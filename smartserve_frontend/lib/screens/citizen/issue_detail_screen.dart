import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../theme/app_theme.dart';

class IssueDetailScreen extends StatelessWidget {
  final Map<String, dynamic> issue;
  final String selectedLanguage;

  const IssueDetailScreen({
    Key? key,
    required this.issue,
    required this.selectedLanguage,
  }) : super(key: key);

  Color _statusColor(String status) => AppTheme.getStatusColor(status);

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
    final lang = selectedLanguage;
    final status = issue['status'] ?? 'REPORTED';
    final category = issue['category'] ?? 'OTHER';
    final statusColor = _statusColor(status);
    final catColor = AppTheme.getCategoryColor(category);
    final remarks = issue['officer_remarks'] ?? '';
    final imageUrl = issue['image'];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppStrings.text("issue_details", lang)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF003c8f)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == 'COMPLETED'
                          ? Icons.check_circle_rounded
                          : status == 'IN_PROGRESS'
                              ? Icons.pending_actions_rounded
                              : Icons.flag_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.text("status", lang),
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Text(
                        status.replaceAll('_', ' '),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Main Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_categoryIcon(category),
                              color: catColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                issue['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                category,
                                style: TextStyle(
                                    color: catColor,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    _infoRow(Icons.person_rounded, "Name", issue['name'] ?? ''),
                    _infoRow(Icons.phone_android_rounded, "Mobile", issue['mobile'] ?? ''),
                    _infoRow(Icons.location_on_rounded, "Location", issue['location'] ?? ''),
                    _infoRow(Icons.calendar_today_rounded,
                        AppStrings.text("submitted_on", lang),
                        issue['created_at'] ?? ''),

                    const Divider(height: 24),

                    _labelText("Description"),
                    const SizedBox(height: 6),
                    Text(
                      issue['description'] ?? '',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Image Card
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _labelText("Photo"),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Officer Remarks Card
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: const Color(0xFFF3E5F5),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.comment_rounded,
                              color: Color(0xFF7B1FA2), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.text("officer_remarks", lang),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B1FA2),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        remarks,
                        style: const TextStyle(
                            color: Color(0xFF4A148C), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
          fontSize: 14),
    );
  }
}