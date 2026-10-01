import 'dart:convert';
import 'package:http/http.dart' as http;

/// 简单的API测试脚本
///
/// 用于测试TubeSavely API接口
void main() async {
  final tester = ApiTester();

  // 测试健康检查接口
  await tester.testHealthCheck();

  // 测试登录接口
  final token = await tester.testLogin('waitinghc@163.com', '123456');

  if (token != null) {
    // 测试获取用户信息接口
    await tester.testGetUserProfile(token);

    // 测试获取用户积分接口
    await tester.testGetUserCredits(token);

    // 测试获取积分历史接口
    await tester.testGetUserCreditsHistory(token);

    // 测试获取积分套餐接口
    await tester.testGetCreditAmounts();

    // 测试解析视频接口
    await tester.testParseVideo(
        token, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');

    // 测试获取视频历史接口
    await tester.testGetVideoHistory(token);

    // 测试获取任务列表接口
    await tester.testGetTaskList(token);
  }
}

/// API测试类
class ApiTester {
  final String baseUrl = 'https://api.tubesavely.cosyment.com';

  /// 测试健康检查接口
  Future<void> testHealthCheck() async {
    print('\n===== 测试健康检查接口 =====');
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/health'));
      _printResponse('GET', '/api/v1/health', response);
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 测试登录接口
  Future<String?> testLogin(String email, String password) async {
    print('\n===== 测试登录接口 =====');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      _printResponse('POST', '/api/v1/auth/login', response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          return data['data']['access_token'];
        }
      }

      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  /// 测试获取用户信息接口
  Future<void> testGetUserProfile(String token) async {
    print('\n===== 测试获取用户信息接口 =====');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _printResponse('GET', '/api/v1/users/profile', response);
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 测试获取用户积分接口
  Future<void> testGetUserCredits(String token) async {
    print('\n===== 测试获取用户积分接口 =====');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/credits/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _printResponse('GET', '/api/v1/credits/', response);
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 测试获取积分历史接口
  Future<void> testGetUserCreditsHistory(String token) async {
    print('\n===== 测试获取积分历史接口 =====');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/credits/history?offset=1&limit=10'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _printResponse('GET', '/api/v1/credits/history', response);
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 测试获取积分套餐接口
  Future<void> testGetCreditAmounts() async {
    print('\n===== 测试获取积分套餐接口 =====');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/credit_amount/active/list'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      _printResponse('GET', '/api/v1/credit_amount/active/list', response);
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 测试解析视频接口
  Future<void> testParseVideo(String token, String videoUrl) async {
    print('\n===== 测试解析视频接口 =====');
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/v1/videos/parse?url=${Uri.encodeComponent(videoUrl)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _printResponse('GET', '/api/v1/videos/parse', response);
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 测试获取视频历史接口
  Future<void> testGetVideoHistory(String token) async {
    print('\n===== 测试获取视频历史接口 =====');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/videos/history?offset=1&limit=10'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _printResponse('GET', '/api/v1/videos/history', response);
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 测试获取任务列表接口
  Future<void> testGetTaskList(String token) async {
    print('\n===== 测试获取任务列表接口 =====');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/tasks/list?skip=0&limit=10'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _printResponse('GET', '/api/v1/tasks/list', response);
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 打印响应
  void _printResponse(String method, String path, http.Response response) {
    print('$method $path');
    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');

    try {
      final json = jsonDecode(response.body);
      final prettyJson = const JsonEncoder.withIndent('  ').convert(json);
      print('Body: $prettyJson');
    } catch (e) {
      print('Body: ${response.body}');
    }
  }
}
