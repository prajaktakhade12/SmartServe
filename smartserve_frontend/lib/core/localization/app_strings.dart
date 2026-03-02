class AppStrings {
  static const Map<String, Map<String, String>> _localized = {
    "en": {
      // Navigation
      "report": "Report",
      "dashboard": "Dashboard",
      "my_issues": "My Issues",
      "notifications": "Notifications",

      // Report Issue Screen
      "report_issue": "Report Issue",
      "name": "Full Name *",
      "mobile": "Mobile Number *",
      "title": "Issue Title *",
      "description": "Description *",
      "location": "Location *",
      "select_category": "Select Category *",
      "submit": "Submit Issue",
      "select_map": "Select on Map",
      "photo": "Add Photo",
      "issue_submitted": "Issue submitted successfully!",

      // Categories
      "road": "Road",
      "water": "Water",
      "electricity": "Electricity",
      "sanitation": "Sanitation",
      "environment": "Environment",
      "safety": "Safety",
      "street_light": "Street Light",
      "other": "Other",

      // Dashboard
      "total": "Total",
      "reported": "Reported",
      "in_progress": "In Progress",
      "completed": "Completed",

      // My Issues
      "no_issues": "No issues found",
      "search_issues": "Search issues...",
      "filter_status": "Status",
      "filter_category": "Category",
      "all": "All",

      // Language
      "select_language": "Select Language",
      "change_language": "Language",
    },
    "hi": {
      // Navigation
      "report": "रिपोर्ट",
      "dashboard": "डैशबोर्ड",
      "my_issues": "मेरी शिकायतें",
      "notifications": "सूचनाएं",

      // Report Issue Screen
      "report_issue": "शिकायत दर्ज करें",
      "name": "पूरा नाम *",
      "mobile": "मोबाइल नंबर *",
      "title": "समस्या शीर्षक *",
      "description": "विवरण *",
      "location": "स्थान *",
      "select_category": "श्रेणी चुनें *",
      "submit": "शिकायत जमा करें",
      "select_map": "मानचित्र पर चुनें",
      "photo": "फोटो जोड़ें",
      "issue_submitted": "शिकायत सफलतापूर्वक दर्ज हुई!",

      // Categories
      "road": "सड़क",
      "water": "पानी",
      "electricity": "बिजली",
      "sanitation": "सफाई",
      "environment": "पर्यावरण",
      "safety": "सुरक्षा",
      "street_light": "स्ट्रीट लाइट",
      "other": "अन्य",

      // Dashboard
      "total": "कुल",
      "reported": "रिपोर्टेड",
      "in_progress": "प्रगति में",
      "completed": "पूर्ण",

      // My Issues
      "no_issues": "कोई शिकायत नहीं मिली",
      "search_issues": "शिकायतें खोजें...",
      "filter_status": "स्थिति",
      "filter_category": "श्रेणी",
      "all": "सभी",

      // Language
      "select_language": "भाषा चुनें",
      "change_language": "भाषा",
    },
    "mr": {
      // Navigation
      "report": "तक्रार",
      "dashboard": "डॅशबोर्ड",
      "my_issues": "माझ्या तक्रारी",
      "notifications": "सूचना",

      // Report Issue Screen
      "report_issue": "तक्रार नोंदवा",
      "name": "पूर्ण नाव *",
      "mobile": "मोबाईल नंबर *",
      "title": "समस्या शीर्षक *",
      "description": "वर्णन *",
      "location": "स्थान *",
      "select_category": "श्रेणी निवडा *",
      "submit": "तक्रार सादर करा",
      "select_map": "नकाशावर निवडा",
      "photo": "फोटो जोडा",
      "issue_submitted": "तक्रार यशस्वीरित्या नोंदवली!",

      // Categories
      "road": "रस्ता",
      "water": "पाणी",
      "electricity": "वीज",
      "sanitation": "स्वच्छता",
      "environment": "पर्यावरण",
      "safety": "सुरक्षा",
      "street_light": "पथदीप",
      "other": "इतर",

      // Dashboard
      "total": "एकूण",
      "reported": "नोंदवले",
      "in_progress": "प्रगतीत",
      "completed": "पूर्ण",

      // My Issues
      "no_issues": "कोणतीही तक्रार आढळली नाही",
      "search_issues": "तक्रारी शोधा...",
      "filter_status": "स्थिती",
      "filter_category": "श्रेणी",
      "all": "सर्व",

      // Language
      "select_language": "भाषा निवडा",
      "change_language": "भाषा",
    }
  };

  static String text(String key, String lang) {
    return _localized[lang]?[key] ?? _localized["en"]?[key] ?? key;
  }
}