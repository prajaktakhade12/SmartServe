import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/localization/app_strings.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../maps/map_picker_screen.dart';
import '../../core/user_session.dart';

class ReportIssueScreen extends StatefulWidget {
  final String selectedLanguage;

  const ReportIssueScreen({Key? key, required this.selectedLanguage})
      : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String _selectedCategory = "ROAD";
  File? _selectedImage;
  double? _lat;
  double? _lng;
  bool _submitting = false;

  final _picker = ImagePicker();

  final _categories = [
    {"key": "ROAD", "icon": Icons.directions_car_rounded, "label_key": "road"},
    {"key": "WATER", "icon": Icons.water_drop_rounded, "label_key": "water"},
    {"key": "ELECTRICITY", "icon": Icons.flash_on_rounded, "label_key": "electricity"},
    {"key": "SANITATION", "icon": Icons.cleaning_services_rounded, "label_key": "sanitation"},
    {"key": "ENVIRONMENT", "icon": Icons.eco_rounded, "label_key": "environment"},
    {"key": "SAFETY", "icon": Icons.security_rounded, "label_key": "safety"},
    {"key": "STREET_LIGHT", "icon": Icons.lightbulb_rounded, "label_key": "street_light"},
    {"key": "OTHER", "icon": Icons.more_horiz_rounded, "label_key": "other"},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text("Take Photo"),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: const Text("Choose from Gallery"),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
        _locationCtrl.text = result['address'] ?? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
      });
    }
  }

  Future<void> _detectLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationCtrl.text = LocationService.formatCoords(pos.latitude, pos.longitude);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not get location. Check permissions.")),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final result = await ApiService.createIssue(
  {
    'name': UserSession.name ?? _nameCtrl.text,
    'mobile': UserSession.mobile ?? '',
    'title': _titleCtrl.text.trim(),
    'category': _selectedCategory,
    'description': _descCtrl.text.trim(),
    'location': _locationCtrl.text.trim(),
    'latitude': _lat?.toString() ?? '',
    'longitude': _lng?.toString() ?? '',
  },
  image: _selectedImage,
);

    setState(() => _submitting = false);

    if (!mounted) return;

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      _showSuccessDialog();
      _resetForm();
    }
  }

  void _resetForm() {
    _nameCtrl.clear();
    _mobileCtrl.clear();
    _titleCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    setState(() {
      _selectedCategory = "ROAD";
      _selectedImage = null;
      _lat = null;
      _lng = null;
    });
  }

  void _showSuccessDialog() {
    final lang = widget.selectedLanguage;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.completed, size: 60),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.text("issue_submitted", lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.selectedLanguage;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(AppStrings.text("report_issue", lang)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF003c8f)],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Personal Info ──────────────────────
            _sectionCard(
              title: "Personal Info",
              icon: Icons.person_rounded,
              children: [
                _buildField(
                  controller: _nameCtrl,
                  label: AppStrings.text("name", lang),
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _mobileCtrl,
                  label: AppStrings.text("mobile", lang),
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Mobile is required';
                    if (v.trim().length != 10) return 'Enter 10-digit number';
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Category ──────────────────────────
            _sectionCard(
              title: AppStrings.text("select_category", lang),
              icon: Icons.category_rounded,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (ctx, i) {
                    final item = _categories[i];
                    final key = item["key"] as String;
                    final icon = item["icon"] as IconData;
                    final labelKey = item["label_key"] as String;
                    final selected = _selectedCategory == key;
                    final color = AppTheme.getCategoryColor(key);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon,
                                color: selected ? color : Colors.grey.shade500,
                                size: 26),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.text(labelKey, lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected ? color : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Issue Details ─────────────────────
            _sectionCard(
              title: "Issue Details",
              icon: Icons.description_rounded,
              children: [
                _buildField(
                  controller: _titleCtrl,
                  label: AppStrings.text("title", lang),
                  icon: Icons.title_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _descCtrl,
                  label: AppStrings.text("description", lang),
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required' : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Location ──────────────────────────
            _sectionCard(
              title: AppStrings.text("location", lang),
              icon: Icons.location_on_rounded,
              children: [
                _buildField(
                  controller: _locationCtrl,
                  label: AppStrings.text("location", lang),
                  icon: Icons.location_on_outlined,
                  readOnly: true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Location is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _detectLocation,
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text("Current Location", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickFromMap,
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text("Select on Map", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Photo ─────────────────────────────
            _sectionCard(
              title: AppStrings.text("photo", lang),
              icon: Icons.camera_alt_rounded,
              children: [
                if (_selectedImage != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6, right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showImageOptions,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(AppStrings.text("photo", lang)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Submit Button ─────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        AppStrings.text("submit", lang),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primary,
                ),
              ),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}