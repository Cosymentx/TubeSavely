import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../utils/logger.dart';

/// API测试控制器
class ApiTestController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  
  // 加载状态
  final RxBool isLoading = false.obs;
  
  // API响应
  final RxString apiResponse = ''.obs;
  
  // 选中的API
  final RxString selectedApi = '获取用户信息'.obs;
  
  // API参数
  final RxMap<String, dynamic> apiParams = <String, dynamic>{}.obs;
  
  // 参数控制器映射
  final Map<String, TextEditingController> paramControllers = {};
  
  // API列表
  final List<String> apiList = [
    '获取用户信息',
    '更新用户信息',
    '上传用户头像',
    '解析视频',
    '获取用户积分',
    '获取积分历史',
    '添加用户积分',
    '扣除用户积分',
    '获取积分套餐',
    '创建订单',
    '获取订单状态',
    '获取交易记录',
    '获取视频历史',
    '创建视频转换任务',
    '创建视频生成任务',
    '获取任务列表',
    '获取任务详情',
    '取消任务',
    '创建视频',
    '删除视频',
  ];
  
  @override
  void onInit() {
    super.onInit();
    updateParamsForSelectedApi();
  }
  
  @override
  void onClose() {
    // 释放所有控制器
    paramControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.onClose();
  }
  
  /// 获取参数的控制器
  TextEditingController getControllerForParam(String key) {
    if (!paramControllers.containsKey(key)) {
      paramControllers[key] = TextEditingController(
        text: apiParams[key]?.toString() ?? '',
      );
    }
    return paramControllers[key]!;
  }
  
  /// 根据选中的API更新参数
  void updateParamsForSelectedApi() {
    // 清空参数
    apiParams.clear();
    
    // 根据选中的API设置参数
    switch (selectedApi.value) {
      case '获取用户信息':
        // 无参数
        break;
      case '更新用户信息':
        apiParams['username'] = '';
        apiParams['email'] = '';
        break;
      case '上传用户头像':
        apiParams['filePath'] = '';
        break;
      case '解析视频':
        apiParams['url'] = '';
        break;
      case '获取用户积分':
        // 无参数
        break;
      case '获取积分历史':
        apiParams['offset'] = 1;
        apiParams['limit'] = 20;
        break;
      case '添加用户积分':
        apiParams['credits'] = 100;
        apiParams['action'] = 'test';
        apiParams['description'] = '测试添加积分';
        break;
      case '扣除用户积分':
        apiParams['credits'] = 10;
        apiParams['action'] = 'test';
        apiParams['description'] = '测试扣除积分';
        break;
      case '获取积分套餐':
        // 无参数
        break;
      case '创建订单':
        apiParams['packageId'] = '';
        apiParams['paymentMethod'] = 'alipay';
        apiParams['currency'] = 'CNY';
        break;
      case '获取订单状态':
        apiParams['orderId'] = '';
        break;
      case '获取交易记录':
        apiParams['offset'] = 0;
        apiParams['limit'] = 10;
        break;
      case '获取视频历史':
        apiParams['offset'] = 1;
        apiParams['limit'] = 20;
        break;
      case '创建视频转换任务':
        apiParams['title'] = '测试转换任务';
        apiParams['creditsCost'] = 10;
        apiParams['description'] = '测试描述';
        apiParams['inputUrl'] = '';
        apiParams['outputFormat'] = 'mp4';
        break;
      case '创建视频生成任务':
        apiParams['title'] = '测试生成任务';
        apiParams['creditsCost'] = 20;
        apiParams['description'] = '测试描述';
        apiParams['inputUrl'] = '';
        apiParams['outputFormat'] = 'mp4';
        break;
      case '获取任务列表':
        apiParams['skip'] = 0;
        apiParams['limit'] = 10;
        apiParams['taskType'] = '';
        break;
      case '获取任务详情':
        apiParams['taskId'] = 0;
        break;
      case '取消任务':
        apiParams['taskId'] = 0;
        break;
      case '创建视频':
        apiParams['title'] = '测试视频';
        apiParams['url'] = '';
        apiParams['thumbnail'] = '';
        break;
      case '删除视频':
        apiParams['id'] = 0;
        break;
    }
    
    // 更新控制器
    paramControllers.forEach((key, controller) {
      if (!apiParams.containsKey(key)) {
        controller.text = '';
      } else {
        controller.text = apiParams[key]?.toString() ?? '';
      }
    });
  }
  
  /// 从控制器获取参数值
  Map<String, dynamic> getParamsFromControllers() {
    final Map<String, dynamic> params = {};
    
    apiParams.forEach((key, value) {
      if (paramControllers.containsKey(key)) {
        final text = paramControllers[key]!.text;
        
        // 尝试转换为数字
        if (value is int) {
          params[key] = int.tryParse(text) ?? value;
        } else if (value is double) {
          params[key] = double.tryParse(text) ?? value;
        } else {
          params[key] = text;
        }
      } else {
        params[key] = value;
      }
    });
    
    return params;
  }
  
  /// 发送API请求
  Future<void> sendApiRequest() async {
    try {
      isLoading.value = true;
      
      final params = getParamsFromControllers();
      Response<dynamic> response;
      
      switch (selectedApi.value) {
        case '获取用户信息':
          response = await _apiProvider.getUserInfo();
          break;
        case '更新用户信息':
          response = await _apiProvider.updateUserInfo({
            'username': params['username'],
            'email': params['email'],
          });
          break;
        case '上传用户头像':
          // 需要文件选择器实现
          apiResponse.value = '上传头像需要文件选择器，请在应用中测试';
          isLoading.value = false;
          return;
        case '解析视频':
          response = await _apiProvider.parseVideo(params['url']);
          break;
        case '获取用户积分':
          response = await _apiProvider.getUserCredits();
          break;
        case '获取积分历史':
          response = await _apiProvider.getUserCreditsHistory(
            offset: params['offset'],
            limit: params['limit'],
          );
          break;
        case '添加用户积分':
          response = await _apiProvider.addUserCredits(
            params['credits'],
            params['action'],
            description: params['description'],
          );
          break;
        case '扣除用户积分':
          response = await _apiProvider.deductUserCredits(
            params['credits'],
            params['action'],
            description: params['description'],
          );
          break;
        case '获取积分套餐':
          response = await _apiProvider.getCreditAmounts();
          break;
        case '创建订单':
          response = await _apiProvider.createOrder(
            params['packageId'],
            params['paymentMethod'],
            currency: params['currency'],
          );
          break;
        case '获取订单状态':
          response = await _apiProvider.getOrderStatus(params['orderId']);
          break;
        case '获取交易记录':
          response = await _apiProvider.getTransactions(
            offset: params['offset'],
            limit: params['limit'],
          );
          break;
        case '获取视频历史':
          response = await _apiProvider.getVideoHistory(
            offset: params['offset'],
            limit: params['limit'],
          );
          break;
        case '创建视频转换任务':
          response = await _apiProvider.createConvertTask(
            params['title'],
            params['creditsCost'],
            description: params['description'],
            inputUrl: params['inputUrl'],
            outputFormat: params['outputFormat'],
          );
          break;
        case '创建视频生成任务':
          response = await _apiProvider.createGenerateTask(
            params['title'],
            params['creditsCost'],
            description: params['description'],
            inputUrl: params['inputUrl'],
            outputFormat: params['outputFormat'],
          );
          break;
        case '获取任务列表':
          response = await _apiProvider.getTaskList(
            skip: params['skip'],
            limit: params['limit'],
            taskType: params['taskType'].isEmpty ? null : params['taskType'],
          );
          break;
        case '获取任务详情':
          response = await _apiProvider.getTaskDetail(params['taskId']);
          break;
        case '取消任务':
          response = await _apiProvider.cancelTask(params['taskId']);
          break;
        case '创建视频':
          response = await _apiProvider.createVideo({
            'title': params['title'],
            'url': params['url'],
            'thumbnail': params['thumbnail'],
          });
          break;
        case '删除视频':
          response = await _apiProvider.deleteVideo(params['id']);
          break;
        default:
          apiResponse.value = '未知API: ${selectedApi.value}';
          isLoading.value = false;
          return;
      }
      
      // 格式化响应
      _formatResponse(response);
    } catch (e) {
      Logger.e('API测试错误: $e');
      apiResponse.value = '错误: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 格式化响应
  void _formatResponse(Response<dynamic> response) {
    final buffer = StringBuffer();
    
    buffer.writeln('状态码: ${response.statusCode}');
    buffer.writeln('状态文本: ${response.statusText}');
    buffer.writeln('');
    
    if (response.bodyString != null) {
      try {
        final json = jsonDecode(response.bodyString!);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(json);
        buffer.writeln('响应体:');
        buffer.writeln(prettyJson);
      } catch (e) {
        buffer.writeln('响应体:');
        buffer.writeln(response.bodyString);
      }
    } else {
      buffer.writeln('响应体为空');
    }
    
    apiResponse.value = buffer.toString();
  }
}
