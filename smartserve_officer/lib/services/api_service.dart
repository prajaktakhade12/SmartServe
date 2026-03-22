import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✏️ Change this IP whenever your WiFi IP changes
  static const String baseUrl = "http://192.168.1.3:8000/api";

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Officer Auth ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> officerLogin(
      String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/officer/login/'),
        headers: _headers,
        body: json.encode({'username': username, 'password': password}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'error': 'Connection failed. Check server IP.'};
    }
  }

  // ── Issues ─────────────────────────────────────────────────────────────────
  /// Fetches issues for an officer.
  /// Regular officers only get issues assigned to them.
  /// Dept heads get all issues in their category.
  /// Overall head gets all issues.
  static Future<List<dynamic>> getOfficerIssues(
    String category, {
    String status = '',
    String search = '',
    int? officerId,
    String role = '',
  }) async {
    try {
      final params = <String, String>{
        'category': category,
        if (status.isNotEmpty) 'status': status,
        if (search.isNotEmpty) 'search': search,
        if (officerId != null) 'officer_id': '$officerId',
        if (role.isNotEmpty) 'role': role,
      };
      final uri = Uri.parse('$baseUrl/officer/issues/').replace(queryParameters: params);
      final res = await http.get(uri);
      return json.decode(res.body) as List;
    } catch (_) {
      return [];
    }
  }

  // ── Single Issue ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getIssueById(int issueId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/issue/$issueId/'));
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Update Status ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateIssueStatus(
    int issueId,
    String status,
    String remarks, {
    Map<String, dynamic>? solverDetails,
    int? officerId,
    String? officerName,
  }) async {
    try {
      final body = {
        'status': status,
        'remarks': remarks,
        'note': remarks,
        if (officerId != null) 'officer_id': officerId,
        if (officerName != null) 'officer_name': officerName,
        ...?solverDetails,
      };
      final res = await http.post(
        Uri.parse('$baseUrl/issue/$issueId/status/'),
        headers: _headers,
        body: json.encode(body),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getOfficerDashboard(
    String category, {
    int? officerId,
    String role = '',
  }) async {
    try {
      String url = '$baseUrl/officer/dashboard/?category=$category';
      if (officerId != null) url += '&officer_id=$officerId';
      if (role.isNotEmpty) url += '&role=$role';
      final res = await http.get(Uri.parse(url));
      return json.decode(res.body);
    } catch (_) {
      return {};
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  static Future<dynamic> getOfficerNotifications(
    String category, {
    int? officerId,
    String role = '',
  }) async {
    try {
      final params = <String, String>{
        'category': category,
        if (officerId != null) 'officer_id': '$officerId',
        if (role.isNotEmpty) 'role': role,
      };
      final uri = Uri.parse('$baseUrl/officer/notifications/')
          .replace(queryParameters: params);
      final res = await http.get(uri);
      return json.decode(res.body);
    } catch (_) {
      return [];
    }
  }

  // ── Profile Stats (individual officer) ────────────────────────────────────
  static Future<Map<String, dynamic>> getOfficerProfileStats(int officerId) async {
    try {
      final res = await http.get(
          Uri.parse('$baseUrl/officer/profile-stats/?officer_id=$officerId'));
      return json.decode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Team Stats ─────────────────────────────────────────────────────────────
  static Future<dynamic> getOfficerStats(String category) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/officer/stats/?category=$category'));
      final decoded = json.decode(res.body);
      if (decoded is List) {
        return {'data': decoded};
      }
      return decoded;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Officer List (for reassign dropdown) ──────────────────────────────────
  static Future<List<dynamic>> getOfficerList(String category) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/officer/list/?category=$category'));
      return json.decode(res.body) as List;
    } catch (_) {
      return [];
    }
  }

  // ── Reassign Issue ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> reassignIssue(
      int issueId, int newOfficerId, String requesterRole) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/issue/$issueId/reassign/'),
        headers: _headers,
        body: json.encode({
          'officer_id': newOfficerId,
          'requester_role': requesterRole,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Escalate Issue ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> escalateIssue(
      int issueId, String note, String requesterRole) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/issue/$issueId/escalate/'),
        headers: _headers,
        body: json.encode({
          'note': note,
          'requester_role': requesterRole,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}