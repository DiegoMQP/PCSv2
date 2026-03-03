// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Override with: flutter build web --dart-define=API_URL=https://your-server.com
  static const String _defaultUrl =
      'https://pcsv2-production.up.railway.app';
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: _defaultUrl);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<bool> checkHealth() async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Auth ───────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}));
      if (r.statusCode == 200) {
        try {
          return {'success': true, 'data': jsonDecode(r.body)};
        } catch (_) {
          return {'success': true, 'data': null};
        }
      }
      return {'success': false, 'message': r.body, 'statusCode': r.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'statusCode': 0};
    }
  }

  // ─── Codes ──────────────────────────────────────────────
  Future<List<dynamic>> getCodes(String username) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/codes?username=$username'));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      print('getCodes error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> saveCode({
    required String name,
    required String code,
    required String username,
    String? duration,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/codes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'code': code,
          'username': username,
          'location': 'Main Gate',
          'duration': duration,
        }),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) return {'success': true};
      return {'success': false, 'message': r.body};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<bool> deleteCode(String code) async {
    try {
      final r = await http.delete(Uri.parse('$baseUrl/codes?code=$code'));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Guests ─────────────────────────────────────────────
  Future<List<dynamic>> getGuests(String username) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/guests?username=$username'));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      print('getGuests error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> createGuest({
    required String visitorName,
    required String hostUsername,
    String? plate,
    String? duration,
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/guests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'visitor_name': visitorName,
          'host_username': hostUsername,
          'plate': plate,
          'duration': duration,
          'reservation_time': DateTime.now().toIso8601String(),
        }),
      );
      if (r.statusCode == 200 || r.statusCode == 201) {
        try {
          final data = jsonDecode(r.body) as Map<String, dynamic>;
          return {'success': true, 'data': data};
        } catch (_) {
          return {'success': true, 'data': <String, dynamic>{}};
        }
      }
      return {'success': false, 'message': r.body};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyCode(String code) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/verify?code=$code'));
      if (r.statusCode == 200) {
        try {
          return jsonDecode(r.body) as Map<String, dynamic>;
        } catch (_) {
          return {'valid': true, 'message': r.body};
        }
      } else if (r.statusCode == 404) {
        return {'valid': false, 'message': 'Código inválido o expirado'};
      }
      return {'valid': false, 'message': r.body};
    } catch (e) {
      return {'valid': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ─── Logs ───────────────────────────────────────────────
  Future<List<dynamic>> getLogs(String username) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/logs?username=$username'));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      print('getLogs error: $e');
    }
    return [];
  }

  // ─── Notifications ──────────────────────────────────────
  Future<List<dynamic>> getNotifications(String username) async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/notifications?username=$username'));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      print('getNotifications error: $e');
    }
    return [];
  }

  // ─── Admin Users ────────────────────────────────────────
  Future<List<dynamic>> getUsers() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/admin/users'));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      print('getUsers error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String name,
    required String location,
    String role = 'user',
  }) async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/admin/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'name': name,
          'location': location,
          'role': role,
        }),
      );
      if (r.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(r.body)};
      }
      return {'success': false, 'message': r.body};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<bool> deleteUser(String username) async {
    try {
      final r = await http
          .delete(Uri.parse('$baseUrl/admin/users?username=$username'));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required String username,
    String? newUsername,
    String? password,
    String? name,
    String? location,
    String? role,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (newUsername != null && newUsername.isNotEmpty) body['new_username'] = newUsername;
      if (password   != null && password.isNotEmpty)    body['password']     = password;
      if (name       != null && name.isNotEmpty)        body['name']         = name;
      if (location   != null)                           body['location']     = location;
      if (role       != null)                           body['role']         = role;
      final r = await http.put(
        Uri.parse('$baseUrl/admin/users?username=$username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (r.statusCode == 200) return {'success': true};
      return {'success': false, 'message': r.body};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ─── Share Card Image ────────────────────────────────────
  /// Uploads [pngBytes] to Cloudinary via backend and returns the public URL.
  Future<String?> uploadCardImage(Uint8List pngBytes, String code) async {
    try {
      final b64 = base64Encode(pngBytes);
      final r = await http.post(
        Uri.parse('$baseUrl/share-card'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': b64, 'code': code}),
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return data['url']?.toString();
      }
      print('uploadCardImage error: ${r.statusCode} ${r.body}');
      return null;
    } catch (e) {
      print('uploadCardImage exception: $e');
      return null;
    }
  }
}
