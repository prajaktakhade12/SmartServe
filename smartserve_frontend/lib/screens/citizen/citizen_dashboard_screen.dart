import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CitizenDashboardScreen extends StatefulWidget {
  final String selectedLanguage;

  const CitizenDashboardScreen({Key? key, required this.selectedLanguage})
      : super(key: key);

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _data = await ApiService.getDashboard();
    setState(() => _loading = false);
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.selectedLanguage;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppStrings.text("dashboard", lang)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF003c8f)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42a5f5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              color: Colors.white, size: 40),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Issue Overview",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Total issues: ${_data['total'] ?? 0}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Statistics",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stat Cards Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _statCard(
                          AppStrings.text("total", lang),
                          _data["total"] ?? 0,
                          Icons.assignment_rounded,
                          const Color(0xFF1565C0),
                          const Color(0xFFE3F2FD),
                          delay: 0,
                        ),
                        _statCard(
                          AppStrings.text("reported", lang),
                          _data["reported"] ?? 0,
                          Icons.flag_rounded,
                          AppTheme.reported,
                          const Color(0xFFFFEBEE),
                          delay: 0.1,
                        ),
                        _statCard(
                          AppStrings.text("in_progress", lang),
                          _data["in_progress"] ?? 0,
                          Icons.pending_actions_rounded,
                          AppTheme.inProgress,
                          const Color(0xFFFFF8E1),
                          delay: 0.2,
                        ),
                        _statCard(
                          AppStrings.text("completed", lang),
                          _data["completed"] ?? 0,
                          Icons.check_circle_rounded,
                          AppTheme.completed,
                          const Color(0xFFE8F5E9),
                          delay: 0.3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Progress Bar Section
                    if ((_data['total'] ?? 0) > 0) ...[
                      Text(
                        "Resolution Progress",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _progressRow(
                                AppStrings.text("reported", lang),
                                _data["reported"] ?? 0,
                                _data["total"] ?? 1,
                                AppTheme.reported,
                              ),
                              const SizedBox(height: 16),
                              _progressRow(
                                AppStrings.text("in_progress", lang),
                                _data["in_progress"] ?? 0,
                                _data["total"] ?? 1,
                                AppTheme.inProgress,
                              ),
                              const SizedBox(height: 16),
                              _progressRow(
                                AppStrings.text("completed", lang),
                                _data["completed"] ?? 0,
                                _data["total"] ?? 1,
                                AppTheme.completed,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color,
      Color bgColor, {double delay = 0}) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Transform.scale(
        scale: 0.8 + 0.2 * anim.value,
        child: Opacity(
          opacity: anim.value,
          child: Card(
            color: bgColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressRow(String label, int value, int total, Color color) {
    final pct = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              "$value (${ (pct * 100).toStringAsFixed(0)}%)",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}