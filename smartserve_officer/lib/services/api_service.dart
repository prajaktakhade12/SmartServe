import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.3:8000/api";

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) return body;
      return {'error': body['error'] ?? 'Something went wrong'};
    } catch (e) {
      return {'error': 'Invalid response'};
    }
  }

  static Future<Map<String, dynamic>> officerLogin(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/officer/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getOfficerDashboard(String category) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/officer/dashboard/?category=$category'));
      return _handleResponse(response);
    } catch (e) {
      return {};
    }
  }

  static Future<List<dynamic>> getOfficerIssues(String category,
      {String status = '', String search = ''}) async {
    try {
      var url = '$baseUrl/officer/issues/?category=$category';
      if (status.isNotEmpty) url += '&status=$status';
      if (search.isNotEmpty) url += '&search=$search';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateIssueStatus(
      int issueId, String status, String remarks,
      {Map<String, dynamic>? solverDetails}) async {
    try {
      final body = {
        'status': status,
        'remarks': remarks,
        'note': remarks,
        ...?solverDetails,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/issue/$issueId/status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
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

  static Future<List<dynamic>> getOfficerNotifications(String category) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/officer/notifications/?category=$category'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getOfficerStats(String category) async {
    try {
      final dashboard = await getOfficerDashboard(category);
      return dashboard;
    } catch (e) {
      return {};
    }
  }
}
