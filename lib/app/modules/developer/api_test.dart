import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tubesavely/app/data/providers/api_provider.dart';
import 'package:tubesavely/app/utils/logger.dart';

/// API测试工具
///
/// 用于测试各种API接口
class ApiTest {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  /// 测试用户信息接口
  Future<void> testUserProfile() async {
    try {
      Logger.d('Testing user profile API');
      final response = await _apiProvider.getUserInfo();
      _logResponse('User Profile', response);
    } catch (e) {
      Logger.e('Error testing user profile API: $e');
    }
  }

  /// 测试视频解析接口
  Future<void> testVideoParser(String url) async {
    try {
      Logger.d('Testing video parser API with URL: $url');
      final response = await _apiProvider.parseVideo(url);
      _logResponse('Video Parser', response);
    } catch (e) {
      Logger.e('Error testing video parser API: $e');
    }
  }

  /// 测试获取积分接口
  Future<void> testGetCredits() async {
    try {
      Logger.d('Testing get credits API');
      final response = await _apiProvider.getUserCredits();
      _logResponse('Get Credits', response);
    } catch (e) {
      Logger.e('Error testing get credits API: $e');
    }
  }

  /// 测试获取积分历史接口
  Future<void> testGetCreditsHistory() async {
    try {
      Logger.d('Testing get credits history API');
      final response = await _apiProvider.getUserCreditsHistory();
      _logResponse('Get Credits History', response);
    } catch (e) {
      Logger.e('Error testing get credits history API: $e');
    }
  }

  /// 测试获取积分套餐接口
  Future<void> testGetCreditAmounts() async {
    try {
      Logger.d('Testing get credit amounts API');
      final response = await _apiProvider.getCreditAmounts();
      _logResponse('Get Credit Amounts', response);
    } catch (e) {
      Logger.e('Error testing get credit amounts API: $e');
    }
  }

  /// 测试获取视频历史接口
  Future<void> testGetVideoHistory() async {
    try {
      Logger.d('Testing get video history API');
      final response = await _apiProvider.getVideoHistory();
      _logResponse('Get Video History', response);
    } catch (e) {
      Logger.e('Error testing get video history API: $e');
    }
  }

  /// 测试获取任务列表接口
  Future<void> testGetTaskList() async {
    try {
      Logger.d('Testing get task list API');
      final response = await _apiProvider.getTaskList();
      _logResponse('Get Task List', response);
    } catch (e) {
      Logger.e('Error testing get task list API: $e');
    }
  }

  /// 测试获取交易记录接口
  Future<void> testGetTransactions() async {
    try {
      Logger.d('Testing get transactions API');
      final response = await _apiProvider.getTransactions();
      _logResponse('Get Transactions', response);
    } catch (e) {
      Logger.e('Error testing get transactions API: $e');
    }
  }

  /// 记录响应
  void _logResponse(String apiName, Response response) {
    Logger.d('$apiName API Response:');
    Logger.d('Status Code: ${response.statusCode}');
    Logger.d('Status Text: ${response.statusText}');
    Logger.d('Headers: ${response.headers}');
    Logger.d('Body: ${response.bodyString}');
  }

  /// 运行所有测试
  Future<void> runAllTests() async {
    await testUserProfile();
    await testGetCredits();
    await testGetCreditsHistory();
    await testGetCreditAmounts();
    await testGetVideoHistory();
    await testGetTaskList();
    await testGetTransactions();
  }
}

/// API测试页面
class ApiTestPage extends StatefulWidget {
  const ApiTestPage({Key? key}) : super(key: key);

  @override
  _ApiTestPageState createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  final ApiTest _apiTest = ApiTest();
  final TextEditingController _urlController = TextEditingController();
  String _testResults = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _runTest(Future<void> Function() testFunction) async {
    setState(() {
      _isLoading = true;
      _testResults = '测试中...';
    });

    try {
      await testFunction();
      setState(() {
        _testResults = '测试完成，请查看控制台日志';
      });
    } catch (e) {
      setState(() {
        _testResults = '测试出错: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API测试'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: '视频URL',
                hintText: '输入要解析的视频URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _runTest(() => _apiTest.testVideoParser(_urlController.text)),
              child: const Text('测试视频解析'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest(_apiTest.testUserProfile),
              child: const Text('测试用户信息'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest(_apiTest.testGetCredits),
              child: const Text('测试获取积分'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest(_apiTest.testGetCreditsHistory),
              child: const Text('测试获取积分历史'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest(_apiTest.testGetCreditAmounts),
              child: const Text('测试获取积分套餐'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest(_apiTest.testGetVideoHistory),
              child: const Text('测试获取视频历史'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest(_apiTest.testGetTaskList),
              child: const Text('测试获取任务列表'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest(_apiTest.testGetTransactions),
              child: const Text('测试获取交易记录'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest(_apiTest.runAllTests),
              child: const Text('运行所有测试'),
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(_testResults),
            ),
          ],
        ),
      ),
    );
  }
}
