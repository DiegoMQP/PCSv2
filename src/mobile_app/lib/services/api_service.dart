// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Determine Base URL dynamically
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:7070';
    // 10.0.2.2 is for Android Emulator to access host localhost
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:7070';
    // For iOS Simulator and Desktop (Windows/Mac/Linux)
    return 'http://localhost:7070';
  }
  
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Future<Map<String, dynamic>> register(String username, String password, String location) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
            'username': username, 
            'password': password,
            'location': location
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
