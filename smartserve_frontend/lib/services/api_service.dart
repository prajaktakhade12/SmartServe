import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your PC's IP when testing on physical device via USB/WiFi
  // For emulator use: 10.0.2.2:8000
  // For physical device (USB reverse): 127.0.0.1:8000
  // For physical device (WiFi): 192.168.x.x:8000
  static const String baseUrl = "http://192.168.1.8:8000/api";

  // ─────────────────────────────────────────────
  //  CREATE ISSUE (with optional image)
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> createIssue({
    required String name,
    required String mobile,
    required String title,
    required String category,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
    File? image,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/issue/create/");

      if (image != null) {
        // Multipart request for image upload
        final request = http.MultipartRequest('POST', uri);
        request.fields['name'] = name;
        request.fields['mobile'] = mobile;
        request.fields['title'] = title;
        request.fields['category'] = category;
        request.fields['description'] = description;
        request.fields['location'] = location;
        if (latitude != null) request.fields['latitude'] = latitude.toString();
        if (longitude != null) request.fields['longitude'] = longitude.toString();
        request.files.add(await http.MultipartFile.fromPath('image', image.path));

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        return _handleResponse(response);
      } else {
        // JSON request
        final response = await http.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": name,
            "mobile": mobile,
            "title": title,
            "category": category,
            "description": description,
            "location": location,
            if (latitude != null) "latitude": latitude,
            if (longitude != null) "longitude": longitude,
          }),
        );
        return _handleResponse(response);
      }
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  // ─────────────────────────────────────────────
  //  GET MY ISSUES (filtered by mobile)
  // ─────────────────────────────────────────────
  static Future<List<dynamic>> getMyIssues(String mobile) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/issue/my/?mobile=$mobile"),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  //  GET ISSUE DETAIL
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getIssueDetail(int id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/issue/$id/"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  //  DASHBOARD
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard({String? mobile}) async {
    try {
      final url = mobile != null
          ? "$baseUrl/dashboard/?mobile=$mobile"
          : "$baseUrl/dashboard/";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (e) {
      return {};
    }
  }

  // ─────────────────────────────────────────────
  //  NOTIFICATIONS
  // ─────────────────────────────────────────────
  static Future<List<dynamic>> getNotifications(String mobile) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/notifications/?mobile=$mobile"),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> markNotificationRead(int id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/notifications/$id/read/"),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  //  HELPER
  // ─────────────────────────────────────────────
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return body;
      }
      return {'error': body['error'] ?? 'Something went wrong'};
    } catch (e) {
      return {'error': 'Invalid response: ${response.body}'};
    }
  }
}