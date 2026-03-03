import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.3:8000/api";

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return body;
      return {'error': body['error'] ?? 'Something went wrong'};
    } catch (e) {
      return {'error': 'Invalid response: ${response.body}'};
    }
  }

  static Future<Map<String, dynamic>> createIssue(Map<String, dynamic> data, {File? image}) async {
    try {
      if (image != null) {
        final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/issue/create/'));
        data.forEach((k, v) { if (v != null) req.fields[k] = v.toString(); });
        req.files.add(await http.MultipartFile.fromPath('image', image.path));
        final streamed = await req.send();
        final response = await http.Response.fromStream(streamed);
        return _handleResponse(response);
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl/issue/create/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        return _handleResponse(response);
      }
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<List<dynamic>> getMyIssues(String mobile, {String? category, String? status, String? search}) async {
    try {
      var params = 'mobile=$mobile';
      if (category != null && category.isNotEmpty) params += '&category=$category';
      if (status != null && status.isNotEmpty) params += '&status=$status';
      if (search != null && search.isNotEmpty) params += '&search=$search';
      final response = await http.get(Uri.parse('$baseUrl/issue/my/?$params'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getIssueDetail(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/issue/$id/'));
      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> rateIssue(int id, int rating, {String comment = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/issue/$id/rate/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rating': rating, 'comment': comment}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> addComment(int id, String mobile, String name, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/issue/$id/comment/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'name': name, 'comment': comment}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<List<dynamic>> getNearbyIssues(double lat, double lng, {double radius = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/issue/nearby/?lat=$lat&lng=$lng&radius=$radius'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDashboard({String? mobile}) async {
    try {
      final url = mobile != null ? '$baseUrl/dashboard/?mobile=$mobile' : '$baseUrl/dashboard/';
      final response = await http.get(Uri.parse(url));
      return _handleResponse(response);
    } catch (e) {
      return {};
    }
  }

  static Future<List<dynamic>> getNotifications(String mobile) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications/?mobile=$mobile'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> markNotificationRead(int id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/notifications/$id/read/'));
      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCivicPoints(String mobile) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/civic/points/?mobile=$mobile'));
      return _handleResponse(response);
    } catch (e) {
      return {};
    }
  }

  static Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/civic/leaderboard/'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }
}