// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://pcsv2-production.up.railway.app';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, dynamic>> verifyCode(String code) async {
    final url = Uri.parse('$baseUrl/verify?code=$code');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          return {'valid': true, 'message': response.body};
        }
      } else if (response.statusCode == 404) {
        return {'valid': false, 'message': 'Código inválido o expirado'};
      } else {
        return {'valid': false, 'message': 'Error del servidor (${response.statusCode})'};
      }
    } catch (e) {
      print('VerifyCode error: $e');
      return {'valid': false, 'message': 'Error de conexión'};
    }
  }

  Future<bool> checkHealth() async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
