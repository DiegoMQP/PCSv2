// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Determine Base URL dynamically
  static String get baseUrl {
    return 'https://pseudoacademically-crenelated-patti.ngrok-free.dev';
  }
  
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkPort() async {
    try {
        final uri = Uri.parse(baseUrl);
        final socket = await Socket.connect(uri.host, uri.port, timeout: const Duration(seconds: 2));
        socket.destroy();
        return true;
    } catch (_) {
        return false;
    }
  }

  Future<Map<String, dynamic>> verifyLocation(String code) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/verify-location?code=$code'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Code invalid'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<List<dynamic>> getLogs(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/logs?username=$username'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create a log/event on the server.
  Future<bool> createLog({
    required String username,
    String? code,
    required String eventType,
    String? message,
  }) async {
    final url = Uri.parse('$baseUrl/logs');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'code': code,
          'event_type': eventType,
          'message': message,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Create Log error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/alerts'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getNotifications(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications?username=$username'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  Future<List<dynamic>> getCodes(String username) async {
    try {
        final response = await http.get(Uri.parse('$baseUrl/codes?username=$username'));
        if (response.statusCode == 200) {
            return jsonDecode(response.body);
        }
        return [];
    } catch (e) {
        return [];
    }
  }

  Future<Map<String, dynamic>> register(String username, String password, String location, String name) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
            'username': username, 
            'password': password,
            'location': location,
            'name': name
        }),
      );

      print('Register status: ${response.statusCode}');
      print('Register body: ${response.body}');

      if (response.statusCode == 201) {
         // Success
         return {'success': true, 'message': response.body};
      } else {
         return {'success': false, 'message': response.body};
      }
    } catch (e) {
      print('Register error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Login status: ${response.statusCode}');
      print('Login body: ${response.body}');

      if (response.statusCode == 200) {
         try {
            final data = jsonDecode(response.body);
            return {'success': true, 'data': data};
         } catch(e) {
            // Fallback for plain text response if any
            return {'success': true, 'message': response.body};
         }
      } else {
         return {'success': false, 'message': response.body};
      }
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveCode({
    required String name,
    required String code,
    required String username,
    String location = "Main Gate",
    List<String> visitors = const [],
    List<String> logs = const [],
    String? duration,
  }) async {
    final url = Uri.parse('$baseUrl/codes');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'code': code,
          'username': username,
          'location': location,
          'visitors': visitors,
          'logs': logs,
          'duration': duration,
        }),
      );

      print('Save Code status: ${response.statusCode}');

      if (response.statusCode == 201) {
         return {'success': true, 'message': response.body};
      } else {
         return {'success': false, 'message': response.body};
      }
    } catch (e) {
      print('Save Code error: $e');
       return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<bool> deleteCode(String code) async {
    final url = Uri.parse('$baseUrl/codes?code=$code');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      print('Delete Code error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createGuest({
      required String visitorName,
      required String hostUsername,
      String? plate,
      String? duration
  }) async {
     final url = Uri.parse('$baseUrl/guests');
     try {
         final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
                'visitor_name': visitorName,
                'host_username': hostUsername,
                'plate': plate,
                'duration': duration,
                'reservation_time': DateTime.now().toIso8601String(),
            })
         );
         
         if (response.statusCode == 201) {
             return {'success': true, 'message': response.body};
         } else {
             return {'success': false, 'message': response.body};
         }
     } catch (e) {
         print('Create Guest error: $e');
         return {'success': false, 'message': 'Connection error: $e'};
     }
  }
}
