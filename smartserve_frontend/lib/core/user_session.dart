import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static String? mobile;
  static String? name;

  static Future<void> login(String mobileNumber, String userName) async {
    mobile = mobileNumber;
    name = userName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobile', mobileNumber);
    await prefs.setString('name', userName);
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    mobile = prefs.getString('mobile');
    name = prefs.getString('name');
    return mobile != null && mobile!.isNotEmpty;
  }

  static Future<void> logout() async {
    mobile = null;
    name = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mobile');
    await prefs.remove('name');
  }

  static bool get isLoggedIn => mobile != null && mobile!.isNotEmpty;
}