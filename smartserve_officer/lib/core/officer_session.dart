import 'package:shared_preferences/shared_preferences.dart';

class OfficerSession {
  static int? id;
  static String? name;
  static String? username;
  static String? category;
  static String? role;

  static Future<void> save({
    required int id,
    required String name,
    required String username,
    required String category,
    required String role,
  }) async {
    OfficerSession.id = id;
    OfficerSession.name = name;
    OfficerSession.username = username;
    OfficerSession.category = category;
    OfficerSession.role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('officer_id', id);
    await prefs.setString('officer_name', name);
    await prefs.setString('officer_username', username);
    await prefs.setString('officer_category', category);
    await prefs.setString('officer_role', role);
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('officer_id');
    if (savedId == null) return false;
    id = savedId;
    name = prefs.getString('officer_name');
    username = prefs.getString('officer_username');
    category = prefs.getString('officer_category');
    role = prefs.getString('officer_role');
    return true;
  }

  static Future<void> logout() async {
    id = null; name = null; username = null; category = null; role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static bool get isHead => role == 'head';
}
