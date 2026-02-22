import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_strings.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'issue_detail_screen.dart';

class MyIssuesScreen extends StatefulWidget {
  final String selectedLanguage;

  const MyIssuesScreen({Key? key, required this.selectedLanguage})
      : super(key: key);

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  final _mobileCtrl = TextEditingController();
  List<dynamic> _issues = [];
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchIssues() async {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10-digit mobile number')),
      );
      return;
    }

    setState(() { _loading = true; _hasSearched = false; });
    final result = await ApiService.getMyIssues(mobile);
    setState(() {
      _issues = result;
      _loading = false;
      _hasSearched = true;
    });
  }

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
    final lang = widget.selectedLanguage;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppStrings.text("my_issues", lang)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF003c8f)],
            ),
          ),
        ),
        actions: [
          if (_hasSearched)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchIssues,
            ),
        ],
      ),
      body: Column(
        children: [
          // Mobile Entry Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.text("save_mobile", lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          hintText: AppStrings.text("mobile_hint", lang),
                          prefixIcon: const Icon(Icons.phone_android_rounded,
                              color: AppTheme.primary, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _loading ? null : _fetchIssues,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.search_rounded, color: Colors.white),
                    )
                  ],
                ),
              ],
            ),
          ),

          // Issues List
          Expanded(
            child: !_hasSearched
                ? _emptyState(lang)
                : _issues.isEmpty
                    ? _noIssuesState(lang)
                    : RefreshIndicator(
                        onRefresh: _fetchIssues,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _issues.length,
                          itemBuilder: (ctx, i) => _issueCard(_issues[i], lang),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _issueCard(Map issue, String lang) {
    final status = issue['status'] ?? 'REPORTED';
    final category = issue['category'] ?? 'OTHER';
    final color = _statusColor(status);
    final catColor = AppTheme.getCategoryColor(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueDetailScreen(
                issue: Map<String, dynamic>.from(issue),
                selectedLanguage: widget.selectedLanguage,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon(category), color: catColor, size: 26),
              ),
              const SizedBox(width: 14),

              // Issue Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            issue['location'] ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue['created_at'] ?? '',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            AppStrings.text("save_mobile", lang),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _noIssuesState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            AppStrings.text("no_issues", lang),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}