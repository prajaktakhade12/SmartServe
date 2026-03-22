/// Complete localization for the SmartServe Officer Desktop App.
/// Supports: English (en), Hindi (hi), Marathi (mr)
/// Usage: OfficerStrings.text('key', lang)
class OfficerStrings {
  static String text(String key, String lang) {
    return _s[key]?[lang] ?? _s[key]?['en'] ?? key;
  }

  static const Map<String, Map<String, String>> _s = {

    // ── App / General ──────────────────────────────────────────────────────
    'app_name':           {'en': 'SmartServe',           'hi': 'स्मार्टसर्व',          'mr': 'स्मार्टसर्व'},
    'officer_portal':     {'en': 'Officer Portal',        'hi': 'अधिकारी पोर्टल',       'mr': 'अधिकारी पोर्टल'},
    'loading':            {'en': 'Loading...',            'hi': 'लोड हो रहा है...',      'mr': 'लोड होत आहे...'},
    'refresh':            {'en': 'Refresh',               'hi': 'ताज़ा करें',             'mr': 'रिफ्रेश करा'},
    'save':               {'en': 'Save',                  'hi': 'सहेजें',                'mr': 'जतन करा'},
    'cancel':             {'en': 'Cancel',                'hi': 'रद्द करें',              'mr': 'रद्द करा'},
    'close':              {'en': 'Close',                 'hi': 'बंद करें',               'mr': 'बंद करा'},
    'yes':                {'en': 'Yes',                   'hi': 'हाँ',                   'mr': 'होय'},
    'no':                 {'en': 'No',                    'hi': 'नहीं',                   'mr': 'नाही'},
    'ok':                 {'en': 'OK',                    'hi': 'ठीक है',                'mr': 'ठीक आहे'},
    'error':              {'en': 'Error',                 'hi': 'त्रुटि',                 'mr': 'त्रुटी'},
    'success':            {'en': 'Success',               'hi': 'सफलता',                 'mr': 'यशस्वी'},
    'no_data':            {'en': 'No data available',     'hi': 'कोई डेटा उपलब्ध नहीं', 'mr': 'डेटा उपलब्ध नाही'},
    'version':            {'en': 'SmartServe Officer Portal v2.0', 'hi': 'स्मार्टसर्व अधिकारी पोर्टल v2.0', 'mr': 'स्मार्टसर्व अधिकारी पोर्टल v2.0'},

    // ── Language ───────────────────────────────────────────────────────────
    'language':           {'en': 'LANGUAGE',              'hi': 'भाषा',                  'mr': 'भाषा'},
    'lang_en':            {'en': 'English',               'hi': 'अंग्रेज़ी',               'mr': 'इंग्रजी'},
    'lang_hi':            {'en': 'Hindi',                 'hi': 'हिंदी',                  'mr': 'हिंदी'},
    'lang_mr':            {'en': 'Marathi',               'hi': 'मराठी',                  'mr': 'मराठी'},
    'select_language':    {'en': 'Select Language',       'hi': 'भाषा चुनें',             'mr': 'भाषा निवडा'},

    // ── Login Screen ───────────────────────────────────────────────────────
    'welcome_back':       {'en': 'Welcome Back',          'hi': 'वापस स्वागत है',         'mr': 'पुन्हा स्वागत'},
    'sign_in_subtitle':   {'en': 'Sign in to your officer account', 'hi': 'अपने अधिकारी खाते में साइन इन करें', 'mr': 'आपल्या अधिकारी खात्यात साइन इन करा'},
    'username':           {'en': 'Username',              'hi': 'उपयोगकर्ता नाम',         'mr': 'वापरकर्ता नाव'},
    'username_hint':      {'en': 'Enter your username',   'hi': 'अपना उपयोगकर्ता नाम दर्ज करें', 'mr': 'आपले वापरकर्ता नाव प्रविष्ट करा'},
    'password':           {'en': 'Password',              'hi': 'पासवर्ड',                'mr': 'पासवर्ड'},
    'password_hint':      {'en': 'Enter your password',   'hi': 'अपना पासवर्ड दर्ज करें', 'mr': 'आपला पासवर्ड प्रविष्ट करा'},
    'sign_in':            {'en': 'Sign In',               'hi': 'साइन इन करें',            'mr': 'साइन इन करा'},
    'signing_in':         {'en': 'Signing in...',         'hi': 'साइन इन हो रहा है...',   'mr': 'साइन इन होत आहे...'},
    'invalid_credentials':{'en': 'Invalid username or password', 'hi': 'गलत उपयोगकर्ता नाम या पासवर्ड', 'mr': 'चुकीचे वापरकर्ता नाव किंवा पासवर्ड'},
    'enter_credentials':  {'en': 'Please enter username and password', 'hi': 'कृपया उपयोगकर्ता नाम और पासवर्ड दर्ज करें', 'mr': 'कृपया वापरकर्ता नाव आणि पासवर्ड प्रविष्ट करा'},
    'feature_manage':     {'en': 'Manage Assigned Issues',    'hi': 'समस्याएं प्रबंधित करें',    'mr': 'समस्या व्यवस्थापित करा'},
    'feature_update':     {'en': 'Update Issue Status',       'hi': 'स्थिति अपडेट करें',         'mr': 'स्थिती अपडेट करा'},
    'feature_stats':      {'en': 'View Statistics',           'hi': 'आंकड़े देखें',               'mr': 'आकडेवारी पहा'},
    'feature_team':       {'en': 'Team Performance Tracking', 'hi': 'टीम प्रदर्शन ट्रैकिंग',     'mr': 'टीम कामगिरी ट्रॅकिंग'},

    // ── Sidebar / Navigation ───────────────────────────────────────────────
    'dashboard':          {'en': 'Dashboard',             'hi': 'डैशबोर्ड',               'mr': 'डॅशबोर्ड'},
    'issues':             {'en': 'Issues',                'hi': 'समस्याएं',               'mr': 'समस्या'},
    'alerts':             {'en': 'Alerts',                'hi': 'अलर्ट',                  'mr': 'सूचना'},
    'profile':            {'en': 'Profile',               'hi': 'प्रोफ़ाइल',               'mr': 'प्रोफाइल'},
    'my_team':            {'en': 'My Team',               'hi': 'मेरी टीम',               'mr': 'माझी टीम'},
    'logout':             {'en': 'Logout',                'hi': 'लॉग आउट',                'mr': 'लॉग आउट'},
    'all_departments':    {'en': 'All Departments',       'hi': 'सभी विभाग',              'mr': 'सर्व विभाग'},

    // ── Dashboard Screen ───────────────────────────────────────────────────
    'good_morning':       {'en': 'Good Morning',          'hi': 'सुप्रभात',               'mr': 'शुभ सकाळ'},
    'good_afternoon':     {'en': 'Good Afternoon',        'hi': 'नमस्कार',                'mr': 'शुभ दुपार'},
    'good_evening':       {'en': 'Good Evening',          'hi': 'शुभ संध्या',              'mr': 'शुभ संध्याकाळ'},
    'total_issues':       {'en': 'Total Issues',          'hi': 'कुल समस्याएं',            'mr': 'एकूण समस्या'},
    'reported':           {'en': 'Reported',              'hi': 'रिपोर्ट',                 'mr': 'नोंदवले'},
    'in_progress':        {'en': 'In Progress',           'hi': 'प्रगति में',              'mr': 'प्रगतीत'},
    'completed':          {'en': 'Completed',             'hi': 'पूर्ण',                  'mr': 'पूर्ण केलेल्या'},
    'overview':           {'en': 'Overview',              'hi': 'अवलोकन',                 'mr': 'आढावा'},
    'dept_wise':          {'en': 'Department-wise Issues','hi': 'विभागवार समस्याएं',       'mr': 'विभागनिहाय समस्या'},
    'recent_activity':    {'en': 'Recent Activity',       'hi': 'हालिया गतिविधि',          'mr': 'अलीकडील क्रियाकलाप'},
    'no_activity':        {'en': 'No recent activity',    'hi': 'कोई हालिया गतिविधि नहीं', 'mr': 'अलीकडील क्रियाकलाप नाही'},

    // ── Issues Screen ──────────────────────────────────────────────────────
    'search_issues':      {'en': 'Search issues...',      'hi': 'समस्या खोजें...',        'mr': 'समस्या शोधा...'},
    'all_status':         {'en': 'All Status',            'hi': 'सभी स्थिति',             'mr': 'सर्व स्थिती'},
    'filter_status':      {'en': 'Filter by Status',      'hi': 'स्थिति के अनुसार',       'mr': 'स्थितीनुसार'},
    'no_issues':          {'en': 'No issues found',       'hi': 'कोई समस्या नहीं मिली',   'mr': 'कोणत्याही समस्या आढळल्या नाहीत'},
    'issue_id':           {'en': 'Issue #',               'hi': 'समस्या #',               'mr': 'समस्या #'},
    'tap_to_open':        {'en': 'Tap to open',           'hi': 'खोलने के लिए टैप करें',  'mr': 'उघडण्यासाठी टॅप करा'},
    'assigned_to':        {'en': 'Assigned to',           'hi': 'को आवंटित',              'mr': 'नियुक्त'},
    'unassigned':         {'en': 'Unassigned',            'hi': 'अनिर्दिष्ट',              'mr': 'नियुक्त नाही'},

    // ── Issue Detail Screen ────────────────────────────────────────────────
    'issue_detail':       {'en': 'Issue Detail',          'hi': 'समस्या विवरण',           'mr': 'समस्या तपशील'},
    'update_issue':       {'en': 'Update Issue',          'hi': 'अपडेट करें',              'mr': 'अपडेट करा'},
    'change_status':      {'en': 'Change status and add remarks', 'hi': 'स्थिति बदलें और टिप्पणी जोड़ें', 'mr': 'स्थिती बदला आणि टिप्पणी जोडा'},
    'update_status':      {'en': 'Update Status',         'hi': 'स्थिति अपडेट करें',      'mr': 'स्थिती अपडेट करा'},
    'remarks':            {'en': 'Remarks *',             'hi': 'टिप्पणी *',               'mr': 'टिप्पणी *'},
    'remarks_hint':       {'en': 'Describe action taken...','hi': 'की गई कार्रवाई बताएं...','mr': 'केलेली कृती वर्णन करा...'},
    'citizen':            {'en': 'Citizen',               'hi': 'नागरिक',                 'mr': 'नागरिक'},
    'mobile':             {'en': 'Mobile',                'hi': 'मोबाइल',                  'mr': 'मोबाइल'},
    'location':           {'en': 'Location',              'hi': 'स्थान',                   'mr': 'स्थान'},
    'description':        {'en': 'Description',           'hi': 'विवरण',                   'mr': 'वर्णन'},
    'photo_evidence':     {'en': 'Photo Evidence',        'hi': 'फोटो प्रमाण',             'mr': 'फोटो पुरावा'},
    'view_full_size':     {'en': 'View Full Size',        'hi': 'पूर्ण आकार देखें',        'mr': 'पूर्ण आकारात पहा'},
    'image_unavailable':  {'en': 'Image not available',   'hi': 'छवि उपलब्ध नहीं',        'mr': 'प्रतिमा उपलब्ध नाही'},
    'status_timeline':    {'en': 'Status Timeline',       'hi': 'स्थिति टाइमलाइन',        'mr': 'स्थिती टाइमलाइन'},
    'resolution_details': {'en': 'Resolution Details',    'hi': 'समाधान विवरण',            'mr': 'निराकरण तपशील'},
    'solver_details':     {'en': 'Solver Details (Required)', 'hi': 'समाधानकर्ता विवरण (आवश्यक)', 'mr': 'निराकरणकर्ता तपशील (आवश्यक)'},
    'solver_name':        {'en': 'Solver Name *',         'hi': 'समाधानकर्ता का नाम *',   'mr': 'निराकरणकर्त्याचे नाव *'},
    'solver_mobile':      {'en': 'Solver Mobile *',       'hi': 'समाधानकर्ता का मोबाइल *','mr': 'निराकरणकर्त्याचा मोबाइल *'},
    'solver_designation': {'en': 'Designation/Role *',    'hi': 'पद/भूमिका *',             'mr': 'पद/भूमिका *'},
    'work_done':          {'en': 'Work Done Description *','hi': 'किया गया कार्य विवरण *',  'mr': 'केलेल्या कामाचे वर्णन *'},
    'resolution_date':    {'en': 'Resolution Date *',     'hi': 'समाधान तिथि *',           'mr': 'निराकरण तारीख *'},
    'updating':           {'en': 'Updating...',           'hi': 'अपडेट हो रहा है...',      'mr': 'अपडेट होत आहे...'},
    'updated_success':    {'en': 'Issue updated successfully!','hi': 'समस्या सफलतापूर्वक अपडेट हुई!','mr': 'समस्या यशस्वीरित्या अपडेट केली!'},
    'reported_on':        {'en': 'Reported',              'hi': 'रिपोर्ट किया',            'mr': 'नोंदवले'},
    'solved_by':          {'en': 'Solved By',             'hi': 'समाधान किया',              'mr': 'सोडवले'},
    'reassign':           {'en': 'Reassign',              'hi': 'पुनः आवंटित करें',         'mr': 'पुन्हा नियुक्त करा'},
    'escalate':           {'en': 'Escalate',              'hi': 'एस्केलेट करें',            'mr': 'एस्केलेट करा'},
    'select_officer':     {'en': 'Select Officer',        'hi': 'अधिकारी चुनें',            'mr': 'अधिकारी निवडा'},

    // ── Status Labels ──────────────────────────────────────────────────────
    'status_reported':    {'en': 'REPORTED',              'hi': 'रिपोर्ट',                 'mr': 'नोंदवले'},
    'status_inprogress':  {'en': 'IN PROGRESS',           'hi': 'प्रगतीत',                 'mr': 'प्रगतीत'},
    'status_completed':   {'en': 'COMPLETED',             'hi': 'पूर्ण',                   'mr': 'पूर्ण'},

    // ── Validation / Snackbar messages ────────────────────────────────────
    'remarks_required':   {'en': 'Please add remarks before updating', 'hi': 'अपडेट से पहले टिप्पणी जोड़ें', 'mr': 'अपडेट करण्यापूर्वी टिप्पणी जोडा'},
    'solver_name_req':    {'en': 'Solver Name is required',     'hi': 'समाधानकर्ता का नाम आवश्यक है', 'mr': 'निराकरणकर्त्याचे नाव आवश्यक आहे'},
    'solver_mobile_req':  {'en': 'Solver Mobile is required',   'hi': 'समाधानकर्ता का मोबाइल आवश्यक है', 'mr': 'निराकरणकर्त्याचा मोबाइल आवश्यक आहे'},
    'solver_desig_req':   {'en': 'Solver Designation is required','hi': 'समाधानकर्ता का पद आवश्यक है', 'mr': 'निराकरणकर्त्याचे पद आवश्यक आहे'},
    'work_done_req':      {'en': 'Work Done description is required','hi': 'किया गया कार्य विवरण आवश्यक है', 'mr': 'केलेल्या कामाचे वर्णन आवश्यक आहे'},
    'date_req':           {'en': 'Resolution Date is required', 'hi': 'समाधान तिथि आवश्यक है', 'mr': 'निराकरण तारीख आवश्यक आहे'},

    // ── Notifications / Alerts Screen ─────────────────────────────────────
    'alerts_title':       {'en': 'Alerts',                'hi': 'अलर्ट',                  'mr': 'सूचना'},
    'alerts_subtitle':    {'en': 'Recent issues assigned to you', 'hi': 'आपको आवंटित हालिया समस्याएं', 'mr': 'तुम्हाला नियुक्त केलेल्या अलीकडील समस्या'},
    'no_alerts':          {'en': 'No new alerts',         'hi': 'कोई नए अलर्ट नहीं',      'mr': 'कोणतेही नवीन अलर्ट नाहीत'},

    // ── Profile Screen ─────────────────────────────────────────────────────
    'account_details':    {'en': 'Account Details',       'hi': 'खाता विवरण',              'mr': 'खाते तपशील'},
    'full_name':          {'en': 'Full Name',             'hi': 'पूरा नाम',                'mr': 'पूर्ण नाव'},
    'designation':        {'en': 'Designation',           'hi': 'पदनाम',                   'mr': 'पदनाम'},
    'role':               {'en': 'Role',                  'hi': 'भूमिका',                  'mr': 'भूमिका'},
    'department':         {'en': 'Department',            'hi': 'विभाग',                   'mr': 'विभाग'},
    'what_you_handle':    {'en': 'What Issues You Handle','hi': 'आप कौनसी समस्याएं संभालते हैं','mr': 'तुम्ही कोणत्या समस्या हाताळता'},
    'performance':        {'en': 'Performance',           'hi': 'प्रदर्शन',                 'mr': 'कामगिरी'},
    'resolution_rate':    {'en': 'Resolution Rate',       'hi': 'समाधान दर',               'mr': 'निराकरण दर'},
    'excellent_perf':     {'en': '🌟 Excellent performance!', 'hi': '🌟 उत्कृष्ट प्रदर्शन!', 'mr': '🌟 उत्कृष्ट कामगिरी!'},
    'good_perf':          {'en': '👍 Good — keep improving',  'hi': '👍 अच्छा — बेहतर करते रहें', 'mr': '👍 चांगले — सुधारत राहा'},
    'needs_attention':    {'en': '⚠️ Needs attention',       'hi': '⚠️ ध्यान देने की जरूरत', 'mr': '⚠️ लक्ष देणे आवश्यक'},
    'rate_description':   {'en': 'Percentage of assigned issues marked as Completed', 'hi': 'आवंटित समस्याओं का प्रतिशत जो पूर्ण हुईं', 'mr': 'नियुक्त समस्यांपैकी पूर्ण झालेल्यांची टक्केवारी'},
    'role_overall_head':  {'en': '🏛  Overall Head',      'hi': '🏛  मुख्य अधिकारी',        'mr': '🏛  मुख्य अधिकारी'},
    'role_dept_head':     {'en': '👤  Department Head',   'hi': '👤  विभाग प्रमुख',          'mr': '👤  विभाग प्रमुख'},
    'role_officer':       {'en': '🔧  Field Officer',     'hi': '🔧  फील्ड अधिकारी',         'mr': '🔧  क्षेत्र अधिकारी'},

    // ── Team Screen ────────────────────────────────────────────────────────
    'team_performance':   {'en': 'Team Performance',      'hi': 'टीम प्रदर्शन',            'mr': 'टीम कामगिरी'},
    'all_dept_overview':  {'en': 'All department performance overview', 'hi': 'सभी विभागों का प्रदर्शन अवलोकन', 'mr': 'सर्व विभागांचा कामगिरी आढावा'},
    'dept_overview_title':{'en': 'Department-wise Overview','hi': 'विभागवार अवलोकन',        'mr': 'विभागनिहाय आढावा'},
    'dept_head_col':      {'en': 'Dept Head',             'hi': 'विभाग प्रमुख',             'mr': 'विभाग प्रमुख'},
    'total_col':          {'en': 'Total',                 'hi': 'कुल',                     'mr': 'एकूण'},
    'done_col':           {'en': 'Done',                  'hi': 'पूर्ण',                   'mr': 'पूर्ण'},
    'pending_col':        {'en': 'Pending',               'hi': 'बाकी',                    'mr': 'प्रलंबित'},
    'rate_col':           {'en': 'Rate %',                'hi': 'दर %',                    'mr': 'दर %'},
    'officer_name':       {'en': 'Officer Name',          'hi': 'अधिकारी नाम',             'mr': 'अधिकाऱ्याचे नाव'},
    'handled':            {'en': 'Handled',               'hi': 'संभाला',                  'mr': 'हाताळले'},
    'team_info_note':     {'en': 'Performance is based on issues assigned to each officer. You can reassign issues from the Issues screen.', 'hi': 'प्रदर्शन प्रत्येक अधिकारी को आवंटित समस्याओं पर आधारित है।', 'mr': 'कामगिरी प्रत्येक अधिकाऱ्याला नियुक्त केलेल्या समस्यांवर आधारित आहे.'},
    'dept_head_label':    {'en': 'DEPT HEAD',             'hi': 'विभाग प्रमुख',             'mr': 'विभाग प्रमुख'},
    'your_dept_officers': {'en': 'Performance of officers in your department', 'hi': 'आपके विभाग के अधिकारियों का प्रदर्शन', 'mr': 'तुमच्या विभागातील अधिकाऱ्यांची कामगिरी'},

    // ── Categories ────────────────────────────────────────────────────────
    'cat_road':           {'en': 'Road',                  'hi': 'सड़क',                    'mr': 'रस्ता'},
    'cat_water':          {'en': 'Water',                 'hi': 'पानी',                    'mr': 'पाणी'},
    'cat_electricity':    {'en': 'Electricity',           'hi': 'बिजली',                   'mr': 'वीज'},
    'cat_sanitation':     {'en': 'Sanitation',            'hi': 'सफाई',                    'mr': 'स्वच्छता'},
    'cat_environment':    {'en': 'Environment',           'hi': 'पर्यावरण',                 'mr': 'पर्यावरण'},
    'cat_safety':         {'en': 'Safety',                'hi': 'सुरक्षा',                  'mr': 'सुरक्षा'},
    'cat_street_light':   {'en': 'Street Light',          'hi': 'स्ट्रीट लाइट',             'mr': 'पथदीप'},
    'cat_other':          {'en': 'Other',                 'hi': 'अन्य',                    'mr': 'इतर'},
    'cat_all':            {'en': 'All',                   'hi': 'सभी',                     'mr': 'सर्व'},
  };

  /// Translates a category key like 'ROAD' → 'सड़क' etc.
  static String category(String cat, String lang) {
    final map = {
      'HEAD':         'cat_road',
      'ROAD':         'cat_road',
      'WATER':        'cat_water',
      'ELECTRICITY':  'cat_electricity',
      'SANITATION':   'cat_sanitation',
      'ENVIRONMENT':  'cat_environment',
      'SAFETY':       'cat_safety',
      'STREET_LIGHT': 'cat_street_light',
      'OTHER':        'cat_other',
    };
    if (cat == 'HEAD') return text('all_departments', lang);
    return text(map[cat] ?? 'cat_other', lang);
  }

  /// Translates a status string like 'IN_PROGRESS' → 'प्रगतीत'
  static String status(String s, String lang) {
    switch (s.toUpperCase()) {
      case 'IN_PROGRESS': return text('status_inprogress', lang);
      case 'COMPLETED':   return text('status_completed', lang);
      default:            return text('status_reported', lang);
    }
  }
}