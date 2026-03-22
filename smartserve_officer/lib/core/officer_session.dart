import 'package:shared_preferences/shared_preferences.dart';

class OfficerSession {
  static int? id;
  static String? name;
  static String? username;
  static String? category;
  static String? role;
  static String? designation;

  static Future<void> save({
    required int id,
    required String name,
    required String username,
    required String category,
    required String role,
    String designation = '',
  }) async {
    OfficerSession.id = id;
    OfficerSession.name = name;
    OfficerSession.username = username;
    OfficerSession.category = category;
    OfficerSession.role = role;
    OfficerSession.designation = designation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('officer_id', id);
    await prefs.setString('officer_name', name);
    await prefs.setString('officer_username', username);
    await prefs.setString('officer_category', category);
    await prefs.setString('officer_role', role);
    await prefs.setString('officer_designation', designation);
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
    designation = prefs.getString('officer_designation');
    return true;
  }

  static Future<void> logout() async {
    id = null; name = null; username = null;
    category = null; role = null; designation = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// true if overall head (sees all departments)
  static bool get isHead => role == 'head';

  /// true if department head (sees their dept team performance)
  static bool get isDeptHead => role == 'dept_head';

  /// true if can see team performance screen (head or dept_head)
  static bool get canViewTeam => role == 'head' || role == 'dept_head';

  /// true if can reassign or escalate issues
  static bool get canManageIssues => role == 'head' || role == 'dept_head';
}