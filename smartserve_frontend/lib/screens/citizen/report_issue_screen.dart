import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/localization/app_strings.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../core/user_session.dart';

class ReportIssueScreen extends StatefulWidget {
  final String selectedLanguage;
  const ReportIssueScreen(
      {Key? key, required this.selectedLanguage})
      : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _descCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _customTitleCtrl = TextEditingController();

  String  _selectedCategory  = "ROAD";
  String? _selectedTitleOption;
  bool    _isCustomTitle      = false;
  File?   _selectedImage;
  double? _lat;
  double? _lng;
  bool    _submitting         = false;
  bool    _geocoding          = false;
  String? _geocodedAddress;   // stores the human-readable address after GPS fetch

  final _picker = ImagePicker();

  // ── Translated problem lists per category per language ──────────────────
  // Each entry is parallel across EN / HI / MR
  // Index -1 (last item) is always "Other (type manually)" in that language

  static const Map<String, Map<String, List<String>>> _problems = {
    'ROAD': {
      'en': [
        'Pothole on road',
        'Road damage / crack',
        'Speed breaker needed',
        'Road waterlogging',
        'Encroachment on road',
        'Damaged footpath / pavement',
        'Missing road divider',
        'Missing road signs / signals',
        'Other (type manually)',
      ],
      'hi': [
        'सड़क पर गड्ढा',
        'सड़क क्षति / दरार',
        'स्पीड ब्रेकर की आवश्यकता',
        'सड़क पर जलभराव',
        'सड़क पर अतिक्रमण',
        'क्षतिग्रस्त फुटपाथ / पेवमेंट',
        'सड़क विभाजक नहीं है',
        'सड़क संकेत / सिग्नल नहीं है',
        'अन्य (स्वयं लिखें)',
      ],
      'mr': [
        'रस्त्यावर खड्डा',
        'रस्त्याचे नुकसान / तडा',
        'स्पीड ब्रेकर आवश्यक',
        'रस्त्यावर पाणी साचणे',
        'रस्त्यावर अतिक्रमण',
        'खराब पदपथ / फुटपाथ',
        'रस्त्याचा विभाजक नाही',
        'रस्ते चिन्हे / सिग्नल नाही',
        'इतर (स्वतः लिहा)',
      ],
    },
    'WATER': {
      'en': [
        'Water supply disruption',
        'Water leakage in pipe',
        'Low water pressure',
        'Contaminated / dirty water',
        'Borewell not working',
        'Drainage overflow',
        'Water meter issue',
        'Illegal water connection',
        'Other (type manually)',
      ],
      'hi': [
        'पानी की आपूर्ति बंद',
        'पाइप में रिसाव',
        'पानी का दबाव कम है',
        'दूषित / गंदा पानी',
        'बोरवेल काम नहीं कर रहा',
        'नाली ओवरफ्लो',
        'पानी मीटर की समस्या',
        'अवैध जल कनेक्शन',
        'अन्य (स्वयं लिखें)',
      ],
      'mr': [
        'पाणी पुरवठा बंद',
        'पाईपमध्ये गळती',
        'पाण्याचा दाब कमी आहे',
        'दूषित / घाण पाणी',
        'बोअरवेल काम करत नाही',
        'नाला ओव्हरफ्लो',
        'पाणी मीटर समस्या',
        'अवैध पाणी जोडणी',
        'इतर (स्वतः लिहा)',
      ],
    },
    'ELECTRICITY': {
      'en': [
        'Power outage in area',
        'Transformer fault',
        'Sparking / hanging wire',
        'Fallen electric pole',
        'High voltage fluctuation',
        'Electric shock hazard',
        'Street light power failure',
        'Meter tampering',
        'Other (type manually)',
      ],
      'hi': [
        'क्षेत्र में बिजली गुल',
        'ट्रांसफार्मर खराब',
        'चिंगारी / लटकता तार',
        'बिजली का खंभा गिरा',
        'उच्च वोल्टेज उतार-चढ़ाव',
        'बिजली का झटका लगने का खतरा',
        'स्ट्रीट लाइट बंद',
        'मीटर से छेड़छाड़',
        'अन्य (स्वयं लिखें)',
      ],
      'mr': [
        'परिसरात वीज नाही',
        'ट्रान्सफार्मर बिघडला',
        'स्पार्किंग / लटकणारी तार',
        'विद्युत खांब पडला',
        'उच्च व्होल्टेज चढ-उतार',
        'विजेचा धक्का बसण्याचा धोका',
        'पथदीप बंद',
        'मीटरशी छेडछाड',
        'इतर (स्वतः लिहा)',
      ],
    },
    'SANITATION': {
      'en': [
        'Garbage not collected',
        'Overflowing dustbin / dumpyard',
        'Open defecation area',
        'Blocked drain / nala',
        'Bad odour from drain',
        'Sanitation workers absent',
        'Mosquito / pest breeding site',
        'Other (type manually)',
      ],
      'hi': [
        'कचरा नहीं उठाया',
        'डस्टबिन / कूड़ाघर भरा है',
        'खुले में शौच की जगह',
        'नाली / नाला बंद है',
        'नाली से बदबू आ रही है',
        'सफाई कर्मचारी अनुपस्थित',
        'मच्छर / कीट प्रजनन स्थल',
        'अन्य (स्वयं लिखें)',
      ],
      'mr': [
        'कचरा उचलला नाही',
        'डस्टबिन / कचराकुंडी भरली आहे',
        'उघड्यावर शौच जागा',
        'नाली / नाला बंद आहे',
        'नाल्यातून दुर्गंधी येत आहे',
        'सफाई कर्मचारी अनुपस्थित',
        'डास / कीड पैदा होण्याची जागा',
        'इतर (स्वतः लिहा)',
      ],
    },
    'ENVIRONMENT': {
      'en': [
        'Illegal garbage dumping',
        'Tree fallen on road',
        'Air pollution from factory / vehicle',
        'Noise pollution',
        'Stray animal menace',
        'Encroachment on green belt / garden',
        'River / lake pollution',
        'Other (type manually)',
      ],
      'hi': [
        'अवैध कचरा डंपिंग',
        'पेड़ सड़क पर गिरा',
        'कारखाने / वाहन से वायु प्रदूषण',
        'ध्वनि प्रदूषण',
        'आवारा जानवरों का खतरा',
        'हरित पट्टी / बाग पर अतिक्रमण',
        'नदी / झील प्रदूषण',
        'अन्य (स्वयं लिखें)',
      ],
      'mr': [
        'बेकायदेशीर कचरा टाकणे',
        'रस्त्यावर झाड पडले',
        'कारखाना / वाहनातून वायू प्रदूषण',
        'ध्वनी प्रदूषण',
        'भटके प्राणी',
        'हरित पट्टी / बागेवर अतिक्रमण',
        'नदी / तलाव प्रदूषण',
        'इतर (स्वतः लिहा)',
      ],
    },
    'SAFETY': {
      'en': [
        'Suspicious activity / crime',
        'Road accident spot',
        'Fire hazard',
        'Missing person',
        'Illegal construction',
        'Drug / alcohol nuisance',
        'Street harassment',
        'Other (type manually)',
      ],
      'hi': [
        'संदिग्ध गतिविधि / अपराध',
        'सड़क दुर्घटना स्थल',
        'आग का खतरा',
        'लापता व्यक्ति',
        'अवैध निर्माण',
        'नशा / शराब की समस्या',
        'सड़क पर उत्पीड़न',
        'अन्य (स्वयं लिखें)',
      ],
      'mr': [
        'संशयास्पद क्रियाकलाप / गुन्हा',
        'रस्त्यावर अपघात स्थळ',
        'आग लागण्याचा धोका',
        'हरवलेली व्यक्ती',
        'बेकायदेशीर बांधकाम',
        'मद्य / व्यसन समस्या',
        'रस्त्यावर त्रास',
        'इतर (स्वतः लिहा)',
      ],
    },
    'STREET_LIGHT': {
      'en': [
        'Street light not working',
        'New street light needed',
        'Damaged light pole',
        'Flickering street light',
        'Light on during daytime (wastage)',
        'Wire exposed on light pole',
        'Other (type manually)',
      ],
      'hi': [
        'स्ट्रीट लाइट काम नहीं कर रही',
        'नई स्ट्रीट लाइट चाहिए',
        'लाइट पोल क्षतिग्रस्त',
        'स्ट्रीट लाइट टिमटिमा रही है',
        'दिन में लाइट जल रही है (बर्बादी)',
        'लाइट पोल पर तार उजागर',
        'अन्य (स्वयं लिखें)',
      ],
      'mr': [
        'पथदीप काम करत नाही',
        'नवीन पथदीप हवा आहे',
        'दिव्याचा खांब खराब झाला',
        'पथदीप लुकलुकत आहे',
        'दिवसा दिवा जळत आहे (वीज वाया)',
        'दिव्याच्या खांबावर उघडी तार',
        'इतर (स्वतः लिहा)',
      ],
    },
    'OTHER': {
      'en': [
        'Government property damage',
        'Public toilet issue',
        'Park / garden not maintained',
        'Bus stop damaged',
        'Encroachment on public land',
        'Stray cattle on road',
        'Other (type manually)',
      ],
      'hi': [
        'सरकारी संपत्ति को नुकसान',
        'सार्वजनिक शौचालय की समस्या',
        'पार्क / बगीचे की देखभाल नहीं',
        'बस स्टॉप क्षतिग्रस्त',
        'सार्वजनिक भूमि पर अतिक्रमण',
        'सड़क पर आवारा मवेशी',
        'अन्य (स्वयं लिखें)',
      ],
      'mr': [
        'सरकारी मालमत्तेचे नुकसान',
        'सार्वजनिक शौचालय समस्या',
        'उद्यान / बाग देखभाल नाही',
        'बस थांबा खराब झाला',
        'सार्वजनिक जागेवर अतिक्रमण',
        'रस्त्यावर भटकी जनावरे',
        'इतर (स्वतः लिहा)',
      ],
    },
  };

  // The English value for "Other" — used for routing logic in backend
  static const _otherOption = 'Other (type manually)';

  // Detect if selected option is "Other" in any language
  bool _isOtherOption(String? val) {
    if (val == null) return false;
    for (final langMap in _problems.values) {
      for (final list in langMap.values) {
        if (list.isNotEmpty && val == list.last) return true;
      }
    }
    return false;
  }

  // Get English equivalent of selected problem (for backend routing)
  String _toEnglishTitle(String displayTitle) {
    final lang = widget.selectedLanguage;
    if (lang == 'en') return displayTitle;
    final catProblems = _problems[_selectedCategory];
    if (catProblems == null) return displayTitle;
    final langList = catProblems[lang] ?? [];
    final enList   = catProblems['en'] ?? [];
    final idx = langList.indexOf(displayTitle);
    if (idx >= 0 && idx < enList.length) return enList[idx];
    return displayTitle;
  }

  List<String> get _currentProblems {
    final lang = widget.selectedLanguage;
    return _problems[_selectedCategory]?[lang] ??
           _problems[_selectedCategory]?['en'] ?? [];
  }

  String get _otherLabel {
    switch (widget.selectedLanguage) {
      case 'hi': return 'अन्य (स्वयं लिखें)';
      case 'mr': return 'इतर (स्वतः लिहा)';
      default:   return 'Other (type manually)';
    }
  }

  String get _customTitleHint {
    switch (widget.selectedLanguage) {
      case 'hi': return 'समस्या का शीर्षक लिखें';
      case 'mr': return 'समस्येचे शीर्षक लिहा';
      default:   return 'Describe your issue title';
    }
  }

  String get _locationHint {
    switch (widget.selectedLanguage) {
      case 'hi': return 'पता टाइप करें या नीचे GPS उपयोग करें';
      case 'mr': return 'पत्ता टाइप करा किंवा GPS वापरा';
      default:   return 'Type address or use GPS below';
    }
  }

  String get _gpsButtonLabel {
    if (_geocoding) {
      switch (widget.selectedLanguage) {
        case 'hi': return 'स्थान ढूंढ रहे हैं...';
        case 'mr': return 'स्थान शोधत आहे...';
        default:   return 'Fetching your location...';
      }
    }
    switch (widget.selectedLanguage) {
      case 'hi': return 'वर्तमान स्थान उपयोग करें (GPS)';
      case 'mr': return 'सध्याचे स्थान वापरा (GPS)';
      default:   return 'Use Current Location (GPS)';
    }
  }

  String get _selectProblemHint {
    switch (widget.selectedLanguage) {
      case 'hi': return 'समस्या प्रकार चुनें';
      case 'mr': return 'समस्येचा प्रकार निवडा';
      default:   return 'Select problem type';
    }
  }

  final _categories = [
    {"key": "ROAD",         "icon": Icons.directions_car_rounded,    "label_key": "road"},
    {"key": "WATER",        "icon": Icons.water_drop_rounded,         "label_key": "water"},
    {"key": "ELECTRICITY",  "icon": Icons.flash_on_rounded,           "label_key": "electricity"},
    {"key": "SANITATION",   "icon": Icons.cleaning_services_rounded,  "label_key": "sanitation"},
    {"key": "ENVIRONMENT",  "icon": Icons.eco_rounded,                "label_key": "environment"},
    {"key": "SAFETY",       "icon": Icons.security_rounded,           "label_key": "safety"},
    {"key": "STREET_LIGHT", "icon": Icons.lightbulb_rounded,          "label_key": "street_light"},
    {"key": "OTHER",        "icon": Icons.more_horiz_rounded,         "label_key": "other"},
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _customTitleCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String newCat) {
    setState(() {
      _selectedCategory   = newCat;
      _selectedTitleOption = null;
      _isCustomTitle      = false;
      _customTitleCtrl.clear();
    });
  }

  void _onTitleDropdownChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedTitleOption = value;
      _isCustomTitle       = _isOtherOption(value);
      if (!_isCustomTitle) _customTitleCtrl.clear();
    });
  }

  // Final title sent to backend — always in English for routing logic
  String get _finalTitle {
    if (_isCustomTitle) return _customTitleCtrl.text.trim();
    return _toEnglishTitle(_selectedTitleOption ?? '');
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded,
                color: AppTheme.primary),
            title: const Text("Take Photo"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded,
                color: AppTheme.primary),
            title: const Text("Choose from Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _geocoding = true);
    final pos = await LocationService.getCurrentLocation();
    if (pos == null) {
      setState(() => _geocoding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Could not get location. Check GPS permissions.")));
      }
      return;
    }

    _lat = pos.latitude;
    _lng = pos.longitude;
    _locationCtrl.text =
        LocationService.formatCoords(pos.latitude, pos.longitude);

    final address =
        await LocationService.reverseGeocode(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _geocoding = false;
        if (address != null && address.isNotEmpty) {
          _locationCtrl.text = address;
          _geocodedAddress   = address;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_finalTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_selectProblemHint),
          backgroundColor: Colors.orange));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final result = await ApiService.createIssue(
      {
        'name':        UserSession.name ?? '',
        'mobile':      UserSession.mobile ?? '',
        'title':       _finalTitle,
        'category':    _selectedCategory,
        'description': _descCtrl.text.trim(),
        'location':    _locationCtrl.text.trim(),
        'latitude':    _lat?.toString() ?? '',
        'longitude':   _lng?.toString() ?? '',
      },
      image: _selectedImage,
    );

    setState(() => _submitting = false);
    if (!mounted) return;

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red));
    } else {
      _showSuccessDialog();
      _resetForm();
    }
  }

  void _resetForm() {
    _descCtrl.clear();
    _locationCtrl.clear();
    _customTitleCtrl.clear();
    setState(() {
      _selectedCategory    = "ROAD";
      _selectedTitleOption = null;
      _isCustomTitle       = false;
      _selectedImage       = null;
      _lat = null;
      _lng = null;
      _geocodedAddress = null;
    });
  }

  void _showSuccessDialog() {
    final lang = widget.selectedLanguage;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.completed, size: 60),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.text("issue_submitted", lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('+10 Civic Points Earned! 🌟',
              style: TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK")),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang     = widget.selectedLanguage;
    final problems = _currentProblems;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // User banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    (UserSession.name ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(UserSession.name ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('+91 ${UserSession.mobile ?? ''}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12)),
                ]),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Category grid ────────────────────────────────────────────
            _sectionCard(
              title: AppStrings.text("select_category", lang),
              icon: Icons.category_rounded,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (ctx, i) {
                    final item     = _categories[i];
                    final key      = item["key"] as String;
                    final icon     = item["icon"] as IconData;
                    final labelKey = item["label_key"] as String;
                    final selected = _selectedCategory == key;
                    final color    = AppTheme.getCategoryColor(key);
                    return GestureDetector(
                      onTap: () => _onCategoryChanged(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selected
                                  ? color : Colors.transparent,
                              width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon,
                                color: selected
                                    ? color : Colors.grey.shade500,
                                size: 26),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.text(labelKey, lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.bold : FontWeight.normal,
                                color: selected
                                    ? color : Colors.grey.shade600,
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

            // ── Issue Details ────────────────────────────────────────────
            _sectionCard(
              title: AppStrings.text("title", lang),
              icon: Icons.description_rounded,
              children: [

                // Problem type dropdown — translated
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.text("title", lang),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedTitleOption,
                      isExpanded: true,
                      hint: Text(_selectProblemHint,
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14)),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.list_alt_rounded,
                            color: AppTheme.primary, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primary, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                      ),
                      items: problems.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          )).toList(),
                      onChanged: _onTitleDropdownChanged,
                      validator: (_) => _finalTitle.isEmpty
                          ? _selectProblemHint : null,
                    ),
                  ],
                ),

                // Custom title — shown when "Other" selected
                if (_isCustomTitle) ...[
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _customTitleCtrl,
                    label: _customTitleHint,
                    icon: Icons.edit_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _customTitleHint : null,
                  ),
                ],

                const SizedBox(height: 14),

                // Description
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

            // ── Location ─────────────────────────────────────────────────
            _sectionCard(
              title: AppStrings.text("location", lang),
              icon: Icons.location_on_rounded,
              children: [
                TextFormField(
                  controller: _locationCtrl,
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Location is required' : null,
                  decoration: InputDecoration(
                    labelText: _locationHint,
                    prefixIcon: Icon(Icons.location_on_outlined,
                        color: AppTheme.primary, size: 20),
                    suffixIcon: _locationCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _locationCtrl.clear();
                              _lat = null;
                              _lng = null;
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 2)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _geocoding ? null : _detectLocation,
                    icon: _geocoding
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded,
                            size: 18),
                    label: Text(_gpsButtonLabel,
                        style: const TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                if (_lat != null && _lng != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.gps_fixed_rounded,
                            size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _geocodedAddress != null
                              ? Text(
                                  _geocodedAddress!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w500),
                                )
                              : Text(
                                  '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ── Photo ────────────────────────────────────────────────────
            _sectionCard(
              title: AppStrings.text("photo", lang),
              icon: Icons.camera_alt_rounded,
              children: [
                if (_selectedImage != null) ...[
                  Stack(children: [
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
                        onTap: () => setState(
                            () => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showImageOptions,
                    icon: const Icon(
                        Icons.add_photo_alternate_rounded),
                    label: Text(AppStrings.text("photo", lang)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(
                          color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Submit ───────────────────────────────────────────────────
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
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(AppStrings.text("submit", lang),
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primary)),
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
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppTheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }
}