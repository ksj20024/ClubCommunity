// lib/core/api/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // kIsWeb, kDebugMode 활용을 위해 필수
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as http_web; // 웹 환경 대응
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/club/models/club_dashboard_response.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  // 백엔드가 던져준 세션 쿠키(JSESSIONID)를 저장하는 전역 변수
  static String? _cookieHeader;

  // 플랫폼(Web vs Mobile)에 맞게 옵션이 설정된 HTTP 클라이언트 생성기
  static http.Client _getClient() {
    final client = http.Client();
    if (kIsWeb && client is http_web.BrowserClient) {
      // 크롬 브라우저 환경일 경우 쿠키 자격증명 공유 활성화 (.withCredentials = true)
      client.withCredentials = true;
    }
    return client;
  }

  // 앱 구동 시 LocalStorage에서 기존 세션 쿠키를 복원하는 헬퍼
  static Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _cookieHeader = prefs.getString('auth_cookie');
    if (kDebugMode) {
      print('세션 쿠키 복원 완료: $_cookieHeader');
    }
  }

  // 세션 쿠키가 존재하면 헤더에 자동으로 주입합니다.
  static Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_cookieHeader != null) {
      headers['Cookie'] = _cookieHeader!;
    }
    return headers;
  }

  // 로그아웃 또는 회원 탈퇴 시 메모리뿐만 아니라 LocalStorage도 비웁니다.
  static Future<void> clearSession() async {
    _cookieHeader = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_cookie'); // 💾 저장소 데이터 삭제
    if (kDebugMode) {
      print('세션 쿠키 삭제 완료');
    }
  }

  // AuthGuardScreen에서 세션 유효성을 스프링 서버에 검증할 내 정보 조회 API(api/users/me)
  static Future<Map<String, dynamic>> getMe() async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/me'),
        headers: _getHeaders(),
      );
      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);
      return {
        'success': response.statusCode == 200,
        'data': mapData['data']
      };
    } catch (e) {
      return {'success': false};
    } finally {
      client.close();
    }
  }

  // User - 1. 회원가입 (POST /api/users/join)
  static Future<Map<String, dynamic>> signUp(Map<String, dynamic> userData) async {
    final client = _getClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/users/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': mapData['message'] ?? '회원가입이 완료되었습니다.'};
      } else {
        return {'success': false, 'message': mapData['message'] ?? '회원가입에 실패했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // User - 2. 로그인 (POST /api/users/login)
  static Future<Map<String, dynamic>> login(String userId, String password) async {
    final client = _getClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'password': password}),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        final String? setCookie = response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
        if (setCookie != null) {
          _cookieHeader = setCookie.split(';').first;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_cookie', _cookieHeader!);
        }

        return {
          'success': true,
          'message': mapData['message'] ?? '로그인 성공',
          'data': mapData['data'],
        };
      } else {
        return {'success': false, 'message': mapData['message'] ?? '로그인 중 오류가 발생했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // User - 3. 현재 로그인 한 유저가 가입 된 동아리 조회 (GET /api/users/clubs)
  static Future<Map<String, dynamic>> getUserClubs() async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/clubs'),
        headers: _getHeaders(),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': mapData['message'] ?? '동아리 목록 조회 성공',
          'data': mapData['data'] as List<dynamic>? ?? [],
        };
      } else {
        return {
          'success': false,
          'message': mapData['message'] ?? '동아리 정보를 가져오지 못했습니다.',
          'data': <dynamic>[]
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.', 'data': <dynamic>[]};
    } finally {
      client.close();
    }
  }

  // User - 4. 회원 정보 수정 (PUT /api/users)
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updateData) async {
    final client = _getClient();
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/users/general'),
        headers: _getHeaders(),
        body: jsonEncode(updateData),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': mapData['message'] ?? '프로필이 성공적으로 수정되었습니다.',
          'data': mapData['data'],
        };
      } else {
        return {'success': false, 'message': mapData['message'] ?? '정보 수정에 실패했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // User - 5. 비밀번호 변경 전용 API (PUT /api/users/password)
  static Future<Map<String, dynamic>> updatePassword({required String currentPassword, required String newPassword,}) async {
    final client = _getClient();
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/users/password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        return {'success': true, 'message': mapData['message'] ?? '비밀번호가 성공적으로 변경되었습니다.', 'data': null};
      } else {
        return {'success': false, 'message': mapData['message'] ?? '비밀번호 변경에 실패했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // User - 6. 회원 탈퇴 (DELETE /api/users)
  static Future<Map<String, dynamic>> withdrawAccount() async {
    final client = _getClient();
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        clearSession();
        return {'success': true, 'message': mapData['message'] ?? '회원 탈퇴가 완료되었습니다.'};
      } else {
        return {'success': false, 'message': mapData['message'] ?? '회원 탈퇴 처리에 실패했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // User - 7. 이메일 인증번호 발송 요청 (POST /api/users/email-verification/send)
  static Future<Map<String, dynamic>> sendEmailVerification(String email) async {
    final client = _getClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/users/email-verification/send'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        return {'success': true, 'message': mapData['message'] ?? '인증번호가 발송되었습니다.'};
      } else {
        return {'success': false, 'message': mapData['message'] ?? '인증번호 발송에 실패했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // User - 8. 이메일 업데이트 (PUT /api/users/email)
  static Future<Map<String, dynamic>> updateEmail({required String email, required String verificationCode,}) async {
    final client = _getClient();
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/users/email'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'verificationCode': verificationCode,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': mapData['message'] ?? '이메일 주소가 변경되었습니다.',
          'data': mapData['data'],
        };
      } else {
        return {'success': false, 'message': mapData['message'] ?? '이메일 변경에 실패했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club - 1. 새로운 동아리 개설 (POST /api/clubs)
  static Future<Map<String, dynamic>> createClub(Map<String, dynamic> clubData) async {
    final client = _getClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/clubs'),
        headers: _getHeaders(),
        body: jsonEncode(clubData),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': mapData['message'] ?? '동아리가 성공적으로 개설되었습니다.',
          'data': mapData['data'],
        };
      } else {
        return {
          'success': false,
          'message': mapData['message'] ?? '동아리 개설에 실패했습니다.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club - 2. 회장의 가입 질문 항목 설정 (PUT /api/club-management/{clubId}/setup-questions)
  static Future<Map<String, dynamic>> setupQuestions(int clubId, List<dynamic> questionList) async {
    final client = _getClient();
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/club-management/$clubId/setup-questions'),
        headers: _getHeaders(),
        body: jsonEncode({'questions': questionList}),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200,
        'message': mapData['message'] ?? '질문 양식이 설정되었습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club - 3. 입부 원서 워드 템플릿 파일(.docx) 업로드 (POST /api/club-management/{clubId}/setup-template)
  static Future<Map<String, dynamic>> setupTemplate({required int clubId, required List<int> fileBytes, required String filename,}) async {
    // 🎯 [마이그레이션]: 자격 증명이 결합된 클라이언트 할당
    final client = _getClient();
    try {
      final uri = Uri.parse('$baseUrl/club-management/$clubId/setup-template');
      final request = http.MultipartRequest('POST', uri);

      if (_cookieHeader != null) {
        request.headers['Cookie'] = _cookieHeader!;
      }

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
      );

      // 🎯 [마이그레이션]: 순수 request.send()를 차단하고 쿠키 유지 장치가 켜진 client.send로 통과
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': mapData['message'] ?? '템플릿 업로드가 완료되었습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close(); // 🎯 리소스 반환 완공
    }
  }

  // Club - 4. 동아리 메인 페이지 접속 시 (GET /api/club-members/{clubId}/my-auth)
  static Future<Map<String, dynamic>> getMyClubAuth(int clubId) async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/club-members/$clubId/my-auth'),
        headers: _getHeaders(),
      );
      final mapData = jsonDecode(utf8.decode(response.bodyBytes));

      return {'success': response.statusCode == 200, 'data': mapData['data'], 'message': mapData['message']};
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club - 5. 내 가입 정보 조회 시 (GET /api/club-members/$clubId/my-membership)
  static Future<Map<String, dynamic>> getMyClubMembership(int clubId) async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/club-members/$clubId/my-membership'),
        headers: _getHeaders(),
      );
      final mapData = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': response.statusCode == 200, 'data': mapData['data'], 'message': mapData['message']};
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club - 6. 내 동아리 가입 기본 정보(학번, 이메일) 수정 (PUT /api/club-members/{clubId}/basic-info)
  static Future<Map<String, dynamic>> updateMemberBasicInfo({ required int clubId, required Map<String, dynamic> updateData, }) async {
    final client = _getClient();
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/club-members/$clubId/basic-info'),
        headers: _getHeaders(),
        body: jsonEncode(updateData),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200,
        'message': mapData['message'] ?? '기본 정보가 수정되었습니다.',
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club - 7. 내가 제출했던 가입 신청서 서류(질문 답변) 수정 (PUT /api/club-members/{clubId}/application-doc)
  static Future<Map<String, dynamic>> updateSubmittedFormAnswers({ required int clubId, required Map<String, dynamic> updateData, }) async {
    final client = _getClient();
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/club-members/$clubId/application-doc'),
        headers: _getHeaders(),
        body: jsonEncode(updateData), // 예: {'formAnswers': {...}} 구조 수급
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200,
        'message': mapData['message'] ?? '가입 신청서 서류가 수정되었습니다.',
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club - 8. 서비스 전체 동아리 목록 조회 (GET /api/clubs)
  static Future<Map<String, dynamic>> getAllClubs() async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/clubs'),
        headers: _getHeaders(),
      );
      final mapData = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': response.statusCode == 200, 'data': mapData['data']};
    } catch (e) {
      return {'success': false, 'data': []};
    } finally {
      client.close();
    }
  }

  // Club - 9. 특정 동아리의 가입 설정 질문지 목록 조회 (GET /api/clubs-members/{clubId}/application-form)
  static Future<Map<String, dynamic>> getClubForm(int clubId) async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/club-members/$clubId/application-form'),
        headers: _getHeaders(),
      );
      final mapData = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': response.statusCode == 200, 'data': mapData['data']};
    } catch (e) {
      return {'success': false, 'data': null};
    } finally {
      client.close();
    }
  }

  // Club - 10. 동아리 가입 신청서 최종 제출 (POST /api/club-members/{clubId}/join)
  static Future<Map<String, dynamic>> submitApplication(int clubId, Map<String, dynamic> joinData) async {
    final client = _getClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/club-members/$clubId/join'), // 🎯 신규 엔드포인트 명세 매핑
        headers: _getHeaders(),
        body: jsonEncode(joinData), // 🎯 DTO 규격 전체 직렬화 바인딩
      );
      final mapData = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': mapData['message'] ?? '가입 신청이 완료되었습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club - 11. 동아리 홈 위젯 게시글 데이터 로드 (GET /api/clubs/{clubId}/dashboard)
  static Future<ClubDashboardResponse> getClubDashboard(int clubId) async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/clubs/$clubId/dashboard'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> mapData = jsonDecode(utf8.decode(response.bodyBytes));

        return ClubDashboardResponse.fromJson(mapData);
      } else {
        throw Exception('대시보드 데이터를 가져오는데 실패했습니다. (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('대시보드 네트워크 통신 오류: $e');
    } finally {
      client.close();
    }
  }

  // Post - 1. 게시글 작성 (POST /api/clubs/{clubId}/posts)
  static Future<Map<String, dynamic>> createPost({ required int clubId, required Map<String, dynamic> postData, List<PlatformFile>? files, }) async {
    final client = _getClient();
    try {
      final uri = Uri.parse('$baseUrl/clubs/$clubId/posts');
      final request = http.MultipartRequest('POST', uri);

      if (_cookieHeader != null) {
        request.headers['Cookie'] = _cookieHeader!;
      }

      // 1. JSON 메타데이터 파트 바인딩 (@RequestPart("post") 매핑)
      final jsonPart = http.MultipartFile.fromBytes(
        'post',
        utf8.encode(jsonEncode(postData)),
        contentType: MediaType('application', 'json'), // 415 에러 방어 배지
      );
      request.files.add(jsonPart);

      // 2. 다중 파일 파트 바인딩 (@RequestPart("files") 매핑)
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          // 웹이나 다른 환경  : 웹이거나 데이터가 직접 실려온 경우 (bytes 활용)
          if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'files',
              file.bytes!,
              filename: file.name,
              contentType: MediaType('image', 'jpeg'), // 안전을 위해 이미지 타입 명시 추천
            ));
          }
          // 모바일 환경 : 스마트폰 기기 가동이라 bytes가 비어있고 path 경로만 온 경우
          else if (file.path != null) {
            final File realFile = File(file.path!);
            if (await realFile.exists()) {
              final List<int> fileBytes = await realFile.readAsBytes();
              request.files.add(http.MultipartFile.fromBytes(
                'files',
                fileBytes,
                filename: file.name,
                contentType: MediaType('image', 'jpeg'),
              ));
            }
          }
        }
      }

      // 브라우저 크레덴셜이 동기화된 클라이언트로 바이패스 전송
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': mapData['message'] ?? '게시글이 등록되었습니다.',
        'data': mapData['data']
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Post - 2. 특정 게시판 페이징 목록 조회 (GET /api/clubs/{clubId}/posts?type=FREE&page=0&size=10)
  static Future<Map<String, dynamic>> getPosts({ required int clubId, required String boardType, int page = 0, int size = 10, }) async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/clubs/$clubId/posts?type=$boardType&page=$page&size=$size'),
        headers: _getHeaders(),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': mapData['message'],
          'data': mapData['data'],
        };
      } else {
        return {'success': false, 'message': mapData['message'] ?? '목록을 가져오지 못했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Post - 3. 게시글 단건 상세 조회 (GET /api/clubs/{clubId}/posts/{postId})
  static Future<Map<String, dynamic>> getPostDetail(int clubId, int postId) async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/clubs/$clubId/posts/$postId'),
        headers: _getHeaders(),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      if (response.statusCode == 200) {
        return {'success': true, 'message': mapData['message'], 'data': mapData['data']};
      } else {
        return {'success': false, 'message': mapData['message'] ?? '상세 정보를 가져오지 못했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Post - 4. 게시글 수정 (PUT /api/clubs/{clubId}/posts/{postId})
  static Future<Map<String, dynamic>> updatePost({ required int clubId, required int postId, required Map<String, dynamic> updateData, }) async {
    final client = _getClient();
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/clubs/$clubId/posts/$postId'),
        headers: _getHeaders(),
        body: jsonEncode(updateData),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200,
        'message': mapData['message'] ?? '게시글이 성공적으로 수정되었습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Post - 5. 게시글 삭제 (DELETE /api/clubs/{clubId}/posts/{postId})
  static Future<Map<String, dynamic>> deletePost({required int clubId, required int postId,}) async {
    final client = _getClient();
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/clubs/$clubId/posts/$postId'),
        headers: _getHeaders(),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200,
        'message': mapData['message'] ?? '게시글이 삭제되었습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Post - 6. 댓글 작성 (POST /api/clubs/{clubId}/posts/{postId}/comments)
  static Future<Map<String, dynamic>> createComment({required int clubId, required int postId, required Map<String, dynamic> commentData, }) async {
    final client = _getClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/clubs/$clubId/posts/$postId/comments'),
        headers: _getHeaders(),
        body: jsonEncode(commentData),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': mapData['message'] ?? '댓글이 등록되었습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Post - 7. 댓글 삭제 (DELETE /api/clubs/{clubId}/posts/comments/{commentId})
  static Future<Map<String, dynamic>> deleteComment({required int clubId, required int commentId,}) async {
    final client = _getClient();
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/clubs/$clubId/posts/comments/$commentId'),
        headers: _getHeaders(),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200,
        'message': mapData['message'] ?? '댓글이 삭제되었습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Post - 8. 게시글 추천 / 비추천 투표 토글 (POST /api/clubs/{clubId}/posts/{postId}/vote?type=UPVOTE)
  static Future<Map<String, dynamic>> votePost({required int clubId, required int postId, required String voteType,}) async {
    final client = _getClient();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/clubs/$clubId/posts/$postId/vote?type=$voteType'),
        headers: _getHeaders(),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final mapData = jsonDecode(decodedBody);

      return {
        'success': response.statusCode == 200,
        'message': mapData['message'] ?? '투표 처리가 완료되었습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }

  // Club Manager - 1. 동아리 관리자: 가입 신청 대기자 목록 조회 (GET /api/club-management/{clubId}/pending)
  static Future<Map<String, dynamic>> getPendingJoin(int clubId) async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/club-management/$clubId/pending'),
        headers: _getHeaders(),
      );
      final mapData = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': response.statusCode == 200, 'data': mapData['data']};
    } catch (e) {
      return {'success': false, 'data': []};
    } finally {
      client.close();
    }
  }

  // Club Manager - 2. 동아리 관리자: 정식 소속 부원 목록 조회 (GET /api/club-members/{clubId}/members)
  static Future<Map<String, dynamic>> getClubMembers(int clubId) async {
    final client = _getClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/club-members/$clubId/members'),
        headers: _getHeaders(),
      );
      final mapData = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': response.statusCode == 200, 'data': mapData['data']};
    } catch (e) {
      return {'success': false, 'data': []};
    } finally {
      client.close();
    }
  }

  // Club Manager - 3. 동아리 관리자: 가입 승인 (POST /api/club-management/{clubId}/join/{joinId}/approve)
  static Future<Map<String, dynamic>> approveJoin({required int clubId, required int joinId}) async {
    final client = _getClient();
    try {
      final response = await client.post(
          Uri.parse('$baseUrl/club-management/$clubId/join/$joinId/approve'),
          headers: _getHeaders()
      );
      return {
        'success': response.statusCode == 200,
        'message': jsonDecode(utf8.decode(response.bodyBytes))['message']
      };
    } catch (e) {
      return {'success': false};
    } finally {
      client.close();
    }
  }

  // Club Manager - 4. 동아리 관리자: 가입 반려 (POST /api/club-management/{clubId}/join/{joinId}/reject)
  static Future<Map<String, dynamic>> rejectJoin({required int clubId, required int joinId}) async {
    final client = _getClient();
    try {
      final response = await client.post(
          Uri.parse('$baseUrl/club-management/$clubId/join/$joinId/reject'),
          headers: _getHeaders()
      );
      return {
        'success': response.statusCode == 200,
        'message': jsonDecode(utf8.decode(response.bodyBytes))['message']
      };
    } catch (e) {
      return {'success': false};
    } finally {
      client.close();
    }
  }

  // Club Manager - 5. 동아리 관리자: 부원 추방 (DELETE /api/club-management/{clubId}/members/{memberId})
  static Future<Map<String, dynamic>> kickMember({required int clubId, required int memberId}) async {
    final client = _getClient();
    try {
      final response = await client.delete(
          Uri.parse('$baseUrl/club-management/$clubId/members/$memberId'),
          headers: _getHeaders()
      );
      return {
        'success': response.statusCode == 200,
        'message': jsonDecode(utf8.decode(response.bodyBytes))['message']
      };
    } catch (e) {
      return {'success': false};
    } finally {
      client.close();
    }
  }

  // Club Manager - 6. 동아리 관리자 전용 텔레그램 알림 정보 업데이트 (PUT /api/club-members/{clubId}/telegram)
  static Future<Map<String, dynamic>> updateTelegramSettings({ required int clubId, required Map<String, dynamic> telegramData,}) async {
    final client = _getClient();
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/club-members/$clubId/telegram'), // 🎯 백엔드 컨트롤러 경로 매핑
        headers: _getHeaders(),
        body: jsonEncode(telegramData), // 🎯 UpdateTelegramRequest 명세 직렬화
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 204,
        'message': response.statusCode == 200 ? '설정이 저장되었습니다.' : '서버 오류가 발생했습니다.'
      };
    } catch (e) {
      return {'success': false, 'message': '서버와 통신할 수 없습니다.'};
    } finally {
      client.close();
    }
  }
}