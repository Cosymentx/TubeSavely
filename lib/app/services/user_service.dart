import 'package:get/get.dart';
import '../data/models/user_model.dart';
import '../data/models/api_response_model.dart';
import '../data/providers/api_provider.dart';
import '../data/providers/storage_provider.dart';
import '../utils/logger.dart';
import '../utils/utils.dart';

/// 用户服务
///
/// 负责管理用户登录、注册、信息获取等功能
class UserService extends GetxService {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageProvider _storageProvider = Get.find<StorageProvider>();

  // 当前用户
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // 登录状态
  final RxBool isLoggedIn = false.obs;

  /// 初始化服务
  Future<UserService> init() async {
    Logger.d('UserService initialized');

    // 检查是否已登录
    final token = await _storageProvider.getUserToken();
    isLoggedIn.value = token != null && token.isNotEmpty;
    _apiProvider.setAuthToken(token);

    // 如果已登录，异步获取用户信息，不阻塞启动
    if (isLoggedIn.value) {
      getUserInfo();
    }

    return this;
  }

  /// 用户登录
  ///
  /// [email] 邮箱
  /// [password] 密码
  /// 返回登录结果，包含成功状态和消息
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      Logger.d('User login: $email');

      final response = await _apiProvider.login(email, password);
      Logger.d('User login response received');

      // 处理API响应
      final apiResponse =
          _apiProvider.handleResponse<Map<String, dynamic>>(response);

      if (apiResponse.isSuccess && apiResponse.data != null) {
        // 保存令牌
        final token = apiResponse.data!['access_token'];
        if (token != null) {
          Logger.d('Saving authentication token');
          await _storageProvider.saveUserToken(token);
          _apiProvider.setAuthToken(token);
          isLoggedIn.value = true;

          // 如果响应中包含用户信息，直接使用
          if (apiResponse.data!.containsKey('user')) {
            final userData = apiResponse.data!['user'];
            if (userData != null) {
              final user = UserModel.fromJson(userData);
              await _storageProvider.saveUserInfo(user);
              currentUser.value = user;
            }
          } else {
            // 否则获取用户信息
            await getUserInfo();
          }

          return {
            'success': true,
            'message': apiResponse.message,
          };
        }
      }

      // 返回错误信息
      return {
        'success': false,
        'message': apiResponse.message,
        'code': apiResponse.code,
      };
    } catch (e) {
      Logger.e('Login error: $e');
      return {
        'success': false,
        'message': '登录失败: $e',
        'code': 500,
      };
    }
  }

  /// 用户注册
  ///
  /// [email] 邮箱
  /// [password] 密码
  /// [name] 用户名
  /// 返回注册结果，包含成功状态和消息
  Future<Map<String, dynamic>> register(
      String email, String password, String name) async {
    try {
      Logger.d('User register: $email');

      final response = await _apiProvider.register(email, password, name);
      Logger.d('User register response received');

      // 处理API响应
      final apiResponse =
          _apiProvider.handleResponse<Map<String, dynamic>>(response);

      if (apiResponse.isSuccess && apiResponse.data != null) {
        // 保存令牌
        final token = apiResponse.data!['access_token'];
        if (token != null) {
          Logger.d('Saving authentication token');
          await _storageProvider.saveUserToken(token);
          _apiProvider.setAuthToken(token);
          isLoggedIn.value = true;

          // 如果响应中包含用户信息，直接使用
          if (apiResponse.data!.containsKey('user')) {
            final userData = apiResponse.data!['user'];
            if (userData != null) {
              final user = UserModel.fromJson(userData);
              await _storageProvider.saveUserInfo(user);
              currentUser.value = user;
            }
          } else {
            // 否则获取用户信息
            await getUserInfo();
          }

          return {
            'success': true,
            'message': apiResponse.message,
          };
        }
      }

      // 返回错误信息
      return {
        'success': false,
        'message': apiResponse.message,
        'code': apiResponse.code,
      };
    } catch (e) {
      Logger.e('Register error: $e');
      return {
        'success': false,
        'message': '注册失败: $e',
        'code': 500,
      };
    }
  }

  /// 获取用户信息
  ///
  /// 返回用户信息，获取失败返回null
  Future<UserModel?> getUserInfo() async {
    try {
      Logger.d('Getting user info');

      // 先尝试从本地获取
      UserModel? user = _storageProvider.getUserInfo();
      if (user != null) {
        currentUser.value = user;
        return user;
      }

      // 如果本地没有，则从API获取
      final response = await _apiProvider.getUserInfo();
      Logger.d("Get user info response: ${response.bodyString}");

      // 处理API响应
      final apiResponse =
          _apiProvider.handleResponse<Map<String, dynamic>>(response);

      if (apiResponse.isSuccess && apiResponse.data != null) {
        user = UserModel.fromJson(apiResponse.data!);

        // 保存到本地
        await _storageProvider.saveUserInfo(user);

        // 更新当前用户
        currentUser.value = user;

        return user;
      }

      // 如果响应不成功，记录错误
      Logger.e('Get user info failed: ${apiResponse.message}');
      return null;
    } catch (e) {
      Logger.e('Get user info error: $e');
      return null;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      Logger.d('User logout');

      // 清除本地存储的用户数据
      await _storageProvider.clearUserData();
      _apiProvider.setAuthToken(null);

      // 更新状态
      isLoggedIn.value = false;
      currentUser.value = null;
    } catch (e) {
      Logger.e('Logout error: $e');
    }
  }

  /// 更新用户信息
  ///
  /// [user] 用户信息
  Future<bool> updateUserInfo(UserModel user) async {
    try {
      Logger.d('Updating user info');

      // 构建请求数据
      final data = user.toJson();

      // 调用 API
      final response = await _apiProvider.updateUserInfo(data);

      if (response.status.isOk) {
        // 更新本地存储
        await _storageProvider.saveUserInfo(user);

        // 更新当前用户
        currentUser.value = user;

        return true;
      }

      return false;
    } catch (e) {
      Logger.e('Update user info error: $e');
      return false;
    }
  }

  /// 检查用户是否是会员
  bool isPremiumUser() {
    return currentUser.value != null &&
        currentUser.value!.isPremium &&
        currentUser.value!.isMembershipActive;
  }

  /// 检查用户是否是专业会员
  bool isProUser() {
    return currentUser.value != null &&
        currentUser.value!.isPro &&
        currentUser.value!.isMembershipActive;
  }

  /// 获取会员套餐
  Future<List<Map<String, dynamic>>> getMembershipPlans() async {
    try {
      Logger.d('Getting membership plans');

      final response = await _apiProvider.getMembershipPlans();

      if (response.status.isOk && response.body != null) {
        return List<Map<String, dynamic>>.from(response.body);
      }

      return [];
    } catch (e) {
      Logger.e('Get membership plans error: $e');
      return [];
    }
  }

  /// 获取积分套餐
  Future<List<Map<String, dynamic>>> getCreditsPackages() async {
    try {
      Logger.d('Getting credits packages');

      final response = await _apiProvider.getCreditsPackages();

      if (response.status.isOk && response.body != null) {
        return List<Map<String, dynamic>>.from(response.body);
      }

      return [];
    } catch (e) {
      Logger.e('Get credits packages error: $e');
      return [];
    }
  }

  /// 验证支付
  ///
  /// [data] 支付数据
  Future<bool> verifyPayment(Map<String, dynamic> data) async {
    try {
      Logger.d('Verifying payment');

      final response = await _apiProvider.verifyPayment(data);

      return response.status.isOk;
    } catch (e) {
      Logger.e('Verify payment error: $e');
      return false;
    }
  }

  /// 发送重置密码邮件
  ///
  /// [email] 邮箱
  Future<Map<String, dynamic>> sendResetPasswordEmail(String email) async {
    try {
      Logger.d('Sending reset password email: $email');

      final response = await _apiProvider.sendResetPasswordEmail(email);
      Logger.d("Send reset password email response: ${response.bodyString}");

      // 处理API响应
      final apiResponse =
          _apiProvider.handleResponse<Map<String, dynamic>>(response);

      if (apiResponse.isSuccess) {
        return {
          'success': true,
          'message': apiResponse.message,
        };
      }

      // 返回错误信息
      return {
        'success': false,
        'message': apiResponse.message,
        'code': apiResponse.code,
      };
    } catch (e) {
      Logger.e('Send reset password email error: $e');
      return {
        'success': false,
        'message': '发送重置密码邮件失败: $e',
        'code': 500,
      };
    }
  }

  /// 使用 Apple 登录
  ///
  /// [identityToken] Apple 身份令牌
  /// [email] 邮箱
  /// [name] 用户名
  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    String? email,
    String? name,
  }) async {
    try {
      Logger.d('User login with Apple');

      // 构建请求数据
      final data = {
        'identity_token': identityToken,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
      };

      // 调用 API
      final response = await _apiProvider.loginWithApple(data);
      Logger.d('Apple login response received');

      // 处理API响应
      final apiResponse =
          _apiProvider.handleResponse<Map<String, dynamic>>(response);

      if (apiResponse.isSuccess && apiResponse.data != null) {
        // 保存令牌
        final token = apiResponse.data!['access_token'];
        if (token != null) {
          Logger.d('Saving authentication token');
          await _storageProvider.saveUserToken(token);
          _apiProvider.setAuthToken(token);
          isLoggedIn.value = true;

          // 如果响应中包含用户信息，直接使用
          if (apiResponse.data!.containsKey('user')) {
            final userData = apiResponse.data!['user'];
            if (userData != null) {
              final user = UserModel.fromJson(userData);
              await _storageProvider.saveUserInfo(user);
              currentUser.value = user;
            }
          } else {
            // 否则获取用户信息
            await getUserInfo();
          }

          return {
            'success': true,
            'message': apiResponse.message,
          };
        }
      }

      // 返回错误信息
      return {
        'success': false,
        'message': apiResponse.message,
        'code': apiResponse.code,
      };
    } catch (e) {
      Logger.e('Login with Apple error: $e');
      return {
        'success': false,
        'message': 'Apple登录失败: $e',
        'code': 500,
      };
    }
  }

  /// 使用 Google 登录
  ///
  /// [idToken] Google ID 令牌
  /// [email] 邮箱
  /// [name] 用户名
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    required String email,
    String? name,
  }) async {
    try {
      Logger.d('User login with Google');

      // 构建请求数据
      final data = {
        'id_token': idToken,
        'email': email,
        if (name != null) 'name': name,
      };

      // 调用 API
      final response = await _apiProvider.loginWithGoogle(data);
      Logger.d('Google login response received');

      // 处理API响应
      final apiResponse =
          _apiProvider.handleResponse<Map<String, dynamic>>(response);

      if (apiResponse.isSuccess && apiResponse.data != null) {
        // 保存令牌
        final token = apiResponse.data!['access_token'];
        if (token != null) {
          Logger.d('Saving authentication token');
          await _storageProvider.saveUserToken(token);
          _apiProvider.setAuthToken(token);
          isLoggedIn.value = true;

          // 如果响应中包含用户信息，直接使用
          if (apiResponse.data!.containsKey('user')) {
            final userData = apiResponse.data!['user'];
            if (userData != null) {
              final user = UserModel.fromJson(userData);
              await _storageProvider.saveUserInfo(user);
              currentUser.value = user;
            }
          } else {
            // 否则获取用户信息
            await getUserInfo();
          }

          return {
            'success': true,
            'message': apiResponse.message,
          };
        }
      }

      // 返回错误信息
      return {
        'success': false,
        'message': apiResponse.message,
        'code': apiResponse.code,
      };
    } catch (e) {
      Logger.e('Login with Google error: $e');
      return {
        'success': false,
        'message': 'Google登录失败: $e',
        'code': 500,
      };
    }
  }

  /// 模拟登录（仅用于开发测试）
  ///
  /// [user] 用户信息
  void mockLogin(UserModel user) {
    try {
      Logger.d('Mock login: ${user.email}');

      // 保存用户信息到本地
      _storageProvider.saveUserInfo(user);

      // 保存一个假的令牌
      _storageProvider
          .saveUserToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');

      // 更新状态
      isLoggedIn.value = true;
      currentUser.value = user;
    } catch (e) {
      Logger.e('Mock login error: $e');
    }
  }

  /// 模拟更新用户信息（仅用于开发测试）
  ///
  /// [user] 用户信息
  Future<void> mockUpdateUser(UserModel user) async {
    try {
      Logger.d('Mock update user: ${user.email}');

      // 保存用户信息到本地
      await _storageProvider.saveUserInfo(user);

      // 更新当前用户
      currentUser.value = user;
    } catch (e) {
      Logger.e('Mock update user error: $e');
    }
  }
}
