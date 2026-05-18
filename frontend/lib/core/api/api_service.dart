import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 본인의 백엔드 서버 주소로 변경 (로컬 테스트 시 웹은 localhost, 안드로이드 에뮬레이터는 10.0.2.2)
  static const String baseUrl = 'http://localhost:8080/api';

  // 회원가입
  static Future<bool> signUp(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 로그인 (POST /api/users/{userId})
  static Future<bool> login(String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}), // 필요에 따라 구조 변경
    );
    return response.statusCode == 200;
  }
}