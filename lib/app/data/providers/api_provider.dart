import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../utils/constants.dart';
import '../../utils/logger.dart';
import '../models/api_response_model.dart';

/// API提供者
///
/// 负责与后端API通信，提供各种API请求方法
class ApiProvider extends GetConnect {
  final GetStorage _storage = Get.find<GetStorage>();

  @override
  void onInit() {
    httpClient.baseUrl = Constants.API_BASE_URL;
    httpClient.timeout = const Duration(milliseconds: Constants.API_TIMEOUT);

    // 请求拦截器
    httpClient.addRequestModifier<dynamic>((request) {
      // 添加通用请求头
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'application/json';

      // 添加认证令牌（如果有）
      final token = _storage.read<String>(Constants.STORAGE_USER_TOKEN);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      return request;
    });

    // 响应拦截器
    httpClient.addResponseModifier<dynamic>((request, response) {
      // 处理响应
      if (response.status.isUnauthorized) {
        // 处理401未授权错误
        // 例如：清除本地令牌并重定向到登录页面
        _storage.remove(Constants.STORAGE_USER_TOKEN);
        Get.offAllNamed('/login');
      }

      return response;
    });

    super.onInit();
  }

  /// 处理API响应
  ///
  /// [response] GetX响应对象
  /// [fromJson] 可选的数据转换函数，用于将响应数据转换为特定类型
  /// 返回统一的API响应模型
  ApiResponseModel<T> handleResponse<T>(Response response,
      {T? Function(dynamic)? fromJson}) {
    try {
      // 检查响应状态
      if (!response.status.isOk) {
        return ApiResponseModel<T>.error(
          response.statusCode ?? 500,
          response.statusText ?? 'Unknown error',
        );
      }

      // 检查响应体是否为空
      if (response.body == null) {
        return ApiResponseModel<T>.error(
          500,
          'Empty response body',
        );
      }

      // 解析响应体
      final Map<String, dynamic> body = response.body is Map<String, dynamic>
          ? response.body
          : jsonDecode(response.bodyString ?? '{}');

      // 检查响应码
      final int code = body['code'] ?? 200;

      // 如果响应码不是200，返回错误
      if (code != 200) {
        return ApiResponseModel<T>.error(
          code,
          body['msg'] ?? 'Unknown error',
        );
      }

      // 处理数据
      final data = body['data'];

      // 记录数据结构，便于调试
      Logger.d('API response data structure: ${data?.runtimeType}');

      if (data != null) {
        if (fromJson != null) {
          return ApiResponseModel<T>.success(
            fromJson(data),
            message: body['msg'] ?? 'Success',
          );
        } else if (data is Map<String, dynamic> &&
            T.toString() == 'Map<String, dynamic>') {
          // 如果期望的类型是Map<String, dynamic>，直接返回数据
          return ApiResponseModel<T>.success(
            data as T,
            message: body['msg'] ?? 'Success',
          );
        } else {
          // 尝试直接转换
          try {
            return ApiResponseModel<T>.success(
              data as T,
              message: body['msg'] ?? 'Success',
            );
          } catch (e) {
            Logger.e('Error converting data to type $T: $e');
            return ApiResponseModel<T>.success(
              null,
              message: body['msg'] ?? 'Success',
            );
          }
        }
      }

      return ApiResponseModel<T>.success(
        null,
        message: body['msg'] ?? 'Success',
      );
    } catch (e) {
      Logger.e('Error handling API response: $e');
      return ApiResponseModel<T>.error(
        500,
        'Error parsing response: $e',
      );
    }
  }

  // ==================== 视频相关 ====================

  /// 解析视频链接
  ///
  /// [url] 视频链接
  Future<Response<dynamic>> parseVideo(String url) {
    Logger.d('Parsing video from ${Constants.PARSE_API_BASE_URL}: $url');
    return httpClient.get('${Constants.PARSE_API_BASE_URL}/parse', query: {'url': url});
  }

  /// 获取视频信息
  ///
  /// [videoId] 视频ID
  Future<Response<dynamic>> getVideoInfo(String videoId) {
    Logger.d('Getting video info: $videoId');
    return get('/api/v1/videos/$videoId');
  }

  /// 获取视频下载选项
  ///
  /// [videoId] 视频ID
  Future<Response<dynamic>> getVideoDownloadOptions(String videoId) {
    Logger.d('Getting video download options: $videoId');
    return get('/api/v1/videos/$videoId/download-options');
  }

  // ==================== 用户相关 ====================

  /// 用户登录
  ///
  /// [email] 邮箱
  /// [password] 密码
  Future<Response<dynamic>> login(String email, String password) {
    Logger.d('User login: $email');
    return post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
  }

  /// 用户注册
  ///
  /// [email] 邮箱
  /// [password] 密码
  /// [name] 用户名
  Future<Response<dynamic>> register(
      String email, String password, String name) {
    Logger.d('User register: $email');
    return post('/api/v1/auth/register', {
      'email': email,
      'password': password,
      'username': name, // 根据接口文档，参数名应该是 username
    });
  }

  /// 修改密码
  ///
  /// [oldPassword] 旧密码
  /// [newPassword] 新密码
  Future<Response<dynamic>> changePassword(
      String oldPassword, String newPassword) {
    Logger.d('User change password');
    return post('/api/v1/auth/change-password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  /// 设置密码（第三方登录用户）
  ///
  /// [password] 密码
  Future<Response<dynamic>> setPassword(String password) {
    Logger.d('User set password');
    return post('/api/v1/auth/set-password', {
      'password': password,
    });
  }

  /// 使用 Apple 登录
  ///
  /// [data] 登录数据，包含 identity_token, email, name 等
  Future<Response<dynamic>> loginWithApple(Map<String, dynamic> data) {
    Logger.d('User login with Apple');
    return post('/api/v1/auth/oauth/apple/callback', data);
  }

  /// 使用 Google 登录
  ///
  /// [data] 登录数据，包含 id_token, email, name 等
  Future<Response<dynamic>> loginWithGoogle(Map<String, dynamic> data) {
    Logger.d('User login with Google');
    return post('/api/v1/auth/oauth/google/callback', data);
  }

  /// 获取用户信息
  Future<Response<dynamic>> getUserInfo() {
    Logger.d('Getting user info');
    return get('/api/v1/users/profile');
  }

  /// 更新用户信息
  ///
  /// [data] 用户信息
  Future<Response<dynamic>> updateUserInfo(Map<String, dynamic> data) {
    Logger.d('Updating user info');
    return put('/api/v1/users/profile', data);
  }

  /// 上传用户头像
  ///
  /// [file] 头像文件
  Future<Response<dynamic>> uploadAvatar(File file) {
    Logger.d('Uploading user avatar');
    final formData = FormData({
      'file': MultipartFile(file, filename: 'avatar.jpg'),
    });
    return post('/api/v1/users/avatar', formData);
  }

  /// 获取下载历史
  ///
  /// [offset] 偏移量，默认为1
  /// [limit] 每页数量，默认为20
  Future<Response<dynamic>> getDownloadHistory(
      {int offset = 1, int limit = 20}) {
    Logger.d('Getting download history');
    return get('/api/v1/videos/history', query: {
      'offset': offset.toString(),
      'limit': limit.toString(),
    });
  }

  /// 删除下载历史
  ///
  /// [id] 视频ID
  Future<Response<dynamic>> deleteDownloadHistory(int id) {
    Logger.d('Deleting download history: $id');
    return delete('/api/v1/videos/$id');
  }

  // ==================== 平台相关 ====================

  /// 获取支持的平台
  Future<Response<dynamic>> getSupportedPlatforms() {
    Logger.d('Getting supported platforms');
    return get('/api/v1/platforms');
  }

  /// 获取热门视频
  Future<Response<dynamic>> getTrendingVideos() {
    Logger.d('Getting trending videos');
    return get('/api/v1/videos/trending');
  }

  // ==================== 会员相关 ====================

  /// 获取会员套餐
  Future<Response<dynamic>> getMembershipPlans() {
    Logger.d('Getting membership plans');
    return get('/api/v1/membership/plans');
  }

  /// 获取积分套餐
  Future<Response<dynamic>> getCreditsPackages() {
    Logger.d('Getting credit amounts');
    return get('/api/v1/credit_amount/active/list');
  }

  // ==================== 订单相关 ====================

  /// 创建订单
  ///
  /// [packageId] 套餐ID
  /// [paymentMethod] 支付方式
  /// [currency] 货币类型
  Future<Response<dynamic>> createOrder(String packageId, String paymentMethod,
      {String currency = 'CNY'}) {
    Logger.d('Creating order: $packageId, $paymentMethod, $currency');
    return post('/api/v1/payments/create', null, query: {
      'credit_amount_id': packageId,
      'payment_method': paymentMethod,
      'currency': currency,
    });
  }

  /// 获取订单状态
  ///
  /// [orderId] 订单ID
  Future<Response<dynamic>> getOrderStatus(String orderId) {
    Logger.d('Getting order status: $orderId');
    return get('/api/v1/payments/status/$orderId');
  }

  /// 验证支付
  ///
  /// [data] 支付验证数据
  Future<Response<dynamic>> verifyPayment(Map<String, dynamic> data) {
    Logger.d('Verifying payment');
    return post('/api/v1/payments/verify', data);
  }

  /// 获取交易记录
  ///
  /// [offset] 偏移量，默认为0
  /// [limit] 每页数量，默认为10
  Future<Response<dynamic>> getTransactions({int offset = 0, int limit = 10}) {
    Logger.d('Getting transactions');
    return get('/api/v1/payments/orders', query: {
      'offset': offset.toString(),
      'limit': limit.toString(),
    });
  }

  /// 获取支付回调
  ///
  /// [provider] 支付提供商
  Future<Response<dynamic>> getPaymentCallback(
      String provider, Map<String, dynamic> data) {
    Logger.d('Getting payment callback: $provider');
    return post('/api/v1/payments/webhook/$provider', data);
  }

  /// 发送重置密码邮件
  ///
  /// [email] 邮箱
  Future<Response<dynamic>> sendResetPasswordEmail(String email) {
    Logger.d('Sending reset password email: $email');
    return post('/api/v1/auth/reset-password', {
      'email': email,
    });
  }

  /// 获取支付宝支付参数
  ///
  /// [orderId] 订单ID
  Future<Response<dynamic>> getAlipayParams(String orderId) {
    Logger.d('Getting Alipay params: $orderId');
    return get('/api/v1/payments/alipay/$orderId');
  }

  /// 获取微信支付参数
  ///
  /// [orderId] 订单ID
  Future<Response<dynamic>> getWechatPayParams(String orderId) {
    Logger.d('Getting WeChat Pay params: $orderId');
    return get('/api/v1/payments/wechat-pay/$orderId');
  }

  /// 获取用户积分
  Future<Response<dynamic>> getUserCredits() {
    Logger.d('Getting user credits');
    return get('/api/v1/credits/');
  }

  /// 获取用户积分历史
  Future<Response<dynamic>> getUserCreditsHistory(
      {int offset = 1, int limit = 20}) {
    Logger.d('Getting user credits history');
    return get('/api/v1/credits/history', query: {
      'offset': offset.toString(),
      'limit': limit.toString(),
    });
  }

  /// 添加用户积分
  ///
  /// [credits] 积分数量
  /// [action] 操作类型
  /// [description] 描述
  Future<Response<dynamic>> addUserCredits(int credits, String action,
      {String? description}) {
    Logger.d('Adding user credits: $credits, $action');
    final Map<String, dynamic> query = {
      'credits': credits.toString(),
      'action': action,
    };
    if (description != null) {
      query['description'] = description;
    }
    return post('/api/v1/credits/add', null, query: query);
  }

  /// 扣除用户积分
  ///
  /// [credits] 积分数量
  /// [action] 操作类型
  /// [description] 描述
  Future<Response<dynamic>> deductUserCredits(int credits, String action,
      {String? description}) {
    Logger.d('Deducting user credits: $credits, $action');
    final Map<String, dynamic> query = {
      'credits': credits.toString(),
      'action': action,
    };
    if (description != null) {
      query['description'] = description;
    }
    return post('/api/v1/credits/deduct', null, query: query);
  }

  /// 获取积分套餐列表
  Future<Response<dynamic>> getCreditAmounts() {
    Logger.d('Getting credit amounts');
    return get('/api/v1/credit_amount/active/list');
  }

  /// 获取积分套餐详情
  ///
  /// [id] 积分套餐ID
  Future<Response<dynamic>> getCreditAmount(int id) {
    Logger.d('Getting credit amount: $id');
    return get('/api/v1/credit_amount/$id');
  }

  /// 提交反馈
  ///
  /// [content] 反馈内容
  /// [name] 姓名
  /// [email] 邮箱
  /// [type] 反馈类型
  Future<Response<dynamic>> submitFeedback(String content,
      {String? name, String? email, String type = 'bug'}) {
    Logger.d('Submitting feedback');
    final Map<String, dynamic> data = {
      'content': content,
      'type': type,
    };
    if (name != null) {
      data['name'] = name;
    }
    if (email != null) {
      data['email'] = email;
    }
    return post('/api/v1/feedback/', data);
  }

  // ==================== 任务相关 ====================

  /// 创建视频转换任务
  ///
  /// [title] 任务标题
  /// [description] 任务描述
  /// [inputUrl] 输入视频URL
  /// [inputParams] 输入参数
  /// [outputFormat] 输出格式
  /// [creditsCost] 积分消耗
  Future<Response<dynamic>> createConvertTask(String title, int creditsCost,
      {String? description,
      String? inputUrl,
      Map<String, dynamic>? inputParams,
      String? outputFormat}) {
    Logger.d('Creating convert task: $title');
    final Map<String, dynamic> data = {
      'title': title,
      'credits_cost': creditsCost,
    };
    if (description != null) {
      data['description'] = description;
    }
    if (inputUrl != null) {
      data['input_url'] = inputUrl;
    }
    if (inputParams != null) {
      data['input_params'] = inputParams;
    }
    if (outputFormat != null) {
      data['output_format'] = outputFormat;
    }
    return post('/api/v1/tasks/convert', data);
  }

  /// 创建视频生成任务
  ///
  /// [title] 任务标题
  /// [description] 任务描述
  /// [inputUrl] 输入视频URL
  /// [inputParams] 输入参数
  /// [outputFormat] 输出格式
  /// [creditsCost] 积分消耗
  Future<Response<dynamic>> createGenerateTask(String title, int creditsCost,
      {String? description,
      String? inputUrl,
      Map<String, dynamic>? inputParams,
      String? outputFormat}) {
    Logger.d('Creating generate task: $title');
    final Map<String, dynamic> data = {
      'title': title,
      'credits_cost': creditsCost,
    };
    if (description != null) {
      data['description'] = description;
    }
    if (inputUrl != null) {
      data['input_url'] = inputUrl;
    }
    if (inputParams != null) {
      data['input_params'] = inputParams;
    }
    if (outputFormat != null) {
      data['output_format'] = outputFormat;
    }
    return post('/api/v1/tasks/generate', data);
  }

  /// 获取任务列表
  ///
  /// [skip] 跳过数量，默认为0
  /// [limit] 每页数量，默认为10
  /// [taskType] 任务类型，可选值：convert, generate
  Future<Response<dynamic>> getTaskList({
    int skip = 0,
    int limit = 10,
    String? taskType,
  }) {
    Logger.d('Getting task list');
    final Map<String, dynamic> query = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (taskType != null) {
      query['task_type'] = taskType;
    }
    return get('/api/v1/tasks/list', query: query);
  }

  /// 获取任务详情
  ///
  /// [taskId] 任务ID
  Future<Response<dynamic>> getTaskDetail(int taskId) {
    Logger.d('Getting task detail: $taskId');
    return get('/api/v1/tasks/$taskId');
  }

  /// 取消任务
  ///
  /// [taskId] 任务ID
  Future<Response<dynamic>> cancelTask(int taskId) {
    Logger.d('Canceling task: $taskId');
    return delete('/api/v1/tasks/$taskId');
  }

  /// 创建视频
  ///
  /// [videoData] 视频数据
  Future<Response<dynamic>> createVideo(Map<String, dynamic> videoData) {
    Logger.d('Creating video');
    return post('/api/v1/videos/', videoData);
  }

  /// 删除视频
  ///
  /// [id] 视频ID
  Future<Response<dynamic>> deleteVideo(int id) {
    Logger.d('Deleting video: $id');
    return delete('/api/v1/videos/$id');
  }

  /// 获取视频历史
  ///
  /// [offset] 偏移量，默认为1
  /// [limit] 每页数量，默认为20
  Future<Response<dynamic>> getVideoHistory({int offset = 1, int limit = 20}) {
    Logger.d('Getting video history');
    return get('/api/v1/videos/history', query: {
      'offset': offset.toString(),
      'limit': limit.toString(),
    });
  }
}
