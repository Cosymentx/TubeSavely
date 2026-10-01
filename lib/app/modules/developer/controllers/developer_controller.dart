import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../routes/app_pages.dart';
import '../../../services/payment_service.dart';
import '../../../services/stripe_service.dart';
import '../../../services/user_service.dart';
import '../../../utils/logger.dart';
import '../../../utils/utils.dart';
import '../../../data/providers/api_provider.dart';

/// 开发者测试页面控制器
class DeveloperController extends GetxController {
  final UserService _userService = Get.find<UserService>();
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final PaymentService _paymentService = Get.find<PaymentService>();
  final PaymentRepository _paymentRepository = Get.find<PaymentRepository>();
  final StripeService _stripeService = Get.find<StripeService>();

  // API测试相关
  final TextEditingController apiUrlController = TextEditingController();
  final TextEditingController apiParamsController = TextEditingController();
  final RxString apiResponse = ''.obs;
  final RxBool isApiLoading = false.obs;
  final RxString selectedMethod = 'GET'.obs;
  final List<String> httpMethods = ['GET', 'POST', 'PUT', 'DELETE'];

  // 登录测试相关
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isLoginLoading = false.obs;

  // 模拟登录相关
  final TextEditingController mockNameController = TextEditingController();
  final TextEditingController mockEmailController = TextEditingController();
  final TextEditingController mockIdController = TextEditingController();
  final RxInt mockUserLevel = 0.obs;
  final RxInt mockUserCredits = 0.obs;
  final Rx<DateTime?> mockMembershipExpiry = Rx<DateTime?>(null);

  // 高级用户测试相关
  final RxBool isPremiumUser = false.obs;
  final RxBool isProUser = false.obs;

  // 当前用户信息
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;

  // 支付测试相关
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);
  final Rx<PaymentMethod> selectedPaymentMethod =
      Rx<PaymentMethod>(PaymentMethod.stripe);
  final Rx<OrderModel?> currentOrder = Rx<OrderModel?>(null);
  final RxBool isPaymentLoading = false.obs;
  final RxBool isStripeAvailable = false.obs;
  final RxBool isGooglePayAvailable = false.obs;

  @override
  void onInit() {
    super.onInit();
    Logger.d('DeveloperController initialized');

    // 初始化API测试表单
    apiUrlController.text = '/parse';
    apiParamsController.text =
        '{"url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"}';

    // 初始化模拟用户信息
    mockNameController.text = 'Test User';
    mockEmailController.text = 'test@example.com';
    mockIdController.text = 'test123';
    mockUserLevel.value = 0;
    mockUserCredits.value = 100;
    mockMembershipExpiry.value = DateTime.now().add(const Duration(days: 30));

    // 监听登录状态
    ever(_userService.isLoggedIn, (isLoggedIn) {
      this.isLoggedIn.value = isLoggedIn;
      if (isLoggedIn) {
        _loadUserInfo();
      } else {
        currentUser.value = null;
      }
    });

    // 监听用户信息
    ever(_userService.currentUser, (user) {
      currentUser.value = user;
      if (user != null) {
        isPremiumUser.value = user.isPremium;
        isProUser.value = user.isPro;
      }
    });

    // 初始化
    isLoggedIn.value = _userService.isLoggedIn.value;
    currentUser.value = _userService.currentUser.value;

    // 加载商品列表
    _loadProducts();

    // 检查支付服务可用性
    _checkPaymentServicesAvailability();
  }

  @override
  void onClose() {
    // 释放资源
    apiUrlController.dispose();
    apiParamsController.dispose();
    emailController.dispose();
    passwordController.dispose();
    mockNameController.dispose();
    mockEmailController.dispose();
    mockIdController.dispose();
    super.onClose();
  }

  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    try {
      await _userService.getUserInfo();
    } catch (e) {
      Logger.e('Load user info error: $e');
    }
  }

  /// 发送API请求
  Future<void> sendApiRequest() async {
    try {
      isApiLoading.value = true;
      apiResponse.value = '';

      final url = apiUrlController.text.trim();
      if (url.isEmpty) {
        Utils.showSnackbar('错误', 'API路径不能为空', isError: true);
        return;
      }

      // 解析参数
      Map<String, dynamic>? params;
      if (apiParamsController.text.isNotEmpty) {
        try {
          params = json.decode(apiParamsController.text);
        } catch (e) {
          Utils.showSnackbar('错误', '参数格式错误: $e', isError: true);
          return;
        }
      }

      // 发送请求
      Response response;
      switch (selectedMethod.value) {
        case 'GET':
          response = await _apiProvider.get(url, query: params);
          break;
        case 'POST':
          response = await _apiProvider.post(url, params);
          break;
        case 'PUT':
          response = await _apiProvider.put(url, params);
          break;
        case 'DELETE':
          response = await _apiProvider.delete(url, query: params);
          break;
        default:
          response = await _apiProvider.get(url, query: params);
      }

      // 格式化响应
      final prettyResponse = _formatResponse(response);
      apiResponse.value = prettyResponse;
    } catch (e) {
      Logger.e('API request error: $e');
      apiResponse.value = 'Error: $e';
    } finally {
      isApiLoading.value = false;
    }
  }

  /// 格式化API响应
  String _formatResponse(Response response) {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Status: ${response.statusCode} ${response.statusText}');
      buffer.writeln('Headers: ${response.headers}');
      buffer.writeln('Body:');

      if (response.body != null) {
        if (response.body is Map || response.body is List) {
          final encoder = JsonEncoder.withIndent('  ');
          buffer.writeln(encoder.convert(response.body));
        } else {
          buffer.writeln(response.body.toString());
        }
      } else {
        buffer.writeln('null');
      }

      return buffer.toString();
    } catch (e) {
      return 'Error formatting response: $e\nRaw response: ${response.body}';
    }
  }

  /// API登录
  Future<void> apiLogin() async {
    try {
      isLoginLoading.value = true;

      final email = emailController.text.trim();
      final password = passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        Utils.showSnackbar('错误', '邮箱和密码不能为空', isError: true);
        return;
      }

      final result = await _userService.login(email, password);

      if (result['success'] == true) {
        Utils.showSnackbar('成功', 'API登录成功');
      } else {
        Utils.showSnackbar('错误', result['message'] ?? 'API登录失败，请检查邮箱和密码',
            isError: true);
      }
    } catch (e) {
      Logger.e('API login error: $e');
      Utils.showSnackbar('错误', 'API登录时出错: $e', isError: true);
    } finally {
      isLoginLoading.value = false;
    }
  }

  /// API注册
  Future<void> apiRegister() async {
    try {
      isLoginLoading.value = true;

      final email = emailController.text.trim();
      final password = passwordController.text;
      final name = mockNameController.text.trim();

      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        Utils.showSnackbar('错误', '邮箱、密码和用户名不能为空', isError: true);
        return;
      }

      final result = await _userService.register(email, password, name);

      if (result['success'] == true) {
        Utils.showSnackbar('成功', 'API注册成功');
      } else {
        Utils.showSnackbar('错误', result['message'] ?? 'API注册失败，请检查输入信息',
            isError: true);
      }
    } catch (e) {
      Logger.e('API register error: $e');
      Utils.showSnackbar('错误', 'API注册时出错: $e', isError: true);
    } finally {
      isLoginLoading.value = false;
    }
  }

  /// API重置密码
  Future<void> apiResetPassword() async {
    try {
      isLoginLoading.value = true;

      final email = emailController.text.trim();

      if (email.isEmpty) {
        Utils.showSnackbar('错误', '邮箱不能为空', isError: true);
        return;
      }

      final result = await _userService.sendResetPasswordEmail(email);

      if (result['success'] == true) {
        Utils.showSnackbar('成功', 'API重置密码邮件已发送');
      } else {
        Utils.showSnackbar('错误', result['message'] ?? 'API重置密码邮件发送失败',
            isError: true);
      }
    } catch (e) {
      Logger.e('API reset password error: $e');
      Utils.showSnackbar('错误', 'API重置密码时出错: $e', isError: true);
    } finally {
      isLoginLoading.value = false;
    }
  }

  /// API获取用户信息
  Future<void> apiGetUserInfo() async {
    try {
      isLoginLoading.value = true;

      final user = await _userService.getUserInfo();

      if (user != null) {
        Utils.showSnackbar('成功', 'API获取用户信息成功');
        apiResponse.value = json.encode(user.toJson());
      } else {
        Utils.showSnackbar('错误', 'API获取用户信息失败', isError: true);
      }
    } catch (e) {
      Logger.e('API get user info error: $e');
      Utils.showSnackbar('错误', 'API获取用户信息时出错: $e', isError: true);
    } finally {
      isLoginLoading.value = false;
    }
  }

  /// 模拟登录
  void mockLogin() {
    try {
      // 创建模拟用户
      final user = UserModel(
        id: int.tryParse(mockIdController.text.trim()),
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: mockNameController.text.trim(),
        email: mockEmailController.text.trim(),
        level: mockUserLevel.value,
        credits: mockUserCredits.value,
        membershipExpiry: mockMembershipExpiry.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 更新用户服务中的用户信息
      _userService.mockLogin(user);

      Utils.showSnackbar('成功', '模拟登录成功');

      // 跳转到主页面（带底部导航栏）
      Get.offAllNamed(Routes.MAIN);
    } catch (e) {
      Logger.e('Mock login error: $e');
      Utils.showSnackbar('错误', '模拟登录时出错: $e', isError: true);
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _userService.logout();
      Utils.showSnackbar('成功', '已退出登录');
    } catch (e) {
      Logger.e('Logout error: $e');
      Utils.showSnackbar('错误', '退出登录时出错: $e', isError: true);
    }
  }

  /// 切换高级用户状态
  void togglePremiumUser() {
    if (!isLoggedIn.value || currentUser.value == null) {
      Utils.showSnackbar('错误', '请先登录', isError: true);
      return;
    }

    try {
      final user = currentUser.value!;
      final newLevel = isPremiumUser.value ? 0 : 1;

      // 更新用户等级
      final updatedUser = user.copyWith(level: newLevel);

      // 更新用户服务中的用户信息
      _userService.mockUpdateUser(updatedUser);

      isPremiumUser.value = !isPremiumUser.value;
      Utils.showSnackbar('成功', isPremiumUser.value ? '已切换为高级用户' : '已切换为普通用户');
    } catch (e) {
      Logger.e('Toggle premium user error: $e');
      Utils.showSnackbar('错误', '切换高级用户状态时出错: $e', isError: true);
    }
  }

  /// 切换专业用户状态
  void toggleProUser() {
    if (!isLoggedIn.value || currentUser.value == null) {
      Utils.showSnackbar('错误', '请先登录', isError: true);
      return;
    }

    try {
      final user = currentUser.value!;
      final newLevel = isProUser.value ? 1 : 2; // 如果是专业用户，降级为高级用户，否则升级为专业用户

      // 更新用户等级
      final updatedUser = user.copyWith(level: newLevel);

      // 更新用户服务中的用户信息
      _userService.mockUpdateUser(updatedUser);

      isProUser.value = !isProUser.value;
      Utils.showSnackbar('成功', isProUser.value ? '已切换为专业用户' : '已切换为高级用户');
    } catch (e) {
      Logger.e('Toggle pro user error: $e');
      Utils.showSnackbar('错误', '切换专业用户状态时出错: $e', isError: true);
    }
  }

  /// 加载商品列表
  Future<void> _loadProducts() async {
    try {
      // 加载商品列表
      final productsList = await _paymentRepository.getProducts();
      products.assignAll(productsList);

      // 默认选中第一个商品
      if (products.isNotEmpty) {
        selectedProduct.value = products.first;
      }
    } catch (e) {
      Logger.e('Load products error: $e');
    }
  }

  /// 检查支付服务可用性
  Future<void> _checkPaymentServicesAvailability() async {
    try {
      // 检查Stripe是否可用
      isStripeAvailable.value = _stripeService.isInitialized;

      // 检查Google Pay是否可用
      if (isStripeAvailable.value) {
        isGooglePayAvailable.value =
            await _stripeService.isGooglePaySupported();
      }
    } catch (e) {
      Logger.e('Check payment services availability error: $e');
    }
  }

  /// 选择商品
  void selectProduct(ProductModel product) {
    selectedProduct.value = product;
  }

  /// 选择支付方式
  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
  }

  /// 创建订单
  Future<void> createOrder() async {
    if (selectedProduct.value == null) {
      Utils.showSnackbar('错误', '请选择商品', isError: true);
      return;
    }

    if (!isLoggedIn.value) {
      Utils.showSnackbar('错误', '请先登录', isError: true);
      return;
    }

    try {
      isPaymentLoading.value = true;

      // 创建订单
      final order = await _paymentRepository.createOrder(
        selectedProduct.value!.id,
        selectedPaymentMethod.value,
      );

      if (order != null) {
        currentOrder.value = order;
        Utils.showSnackbar('成功', '订单创建成功: ${order.id}');
      } else {
        Utils.showSnackbar('错误', '创建订单失败', isError: true);
      }
    } catch (e) {
      Logger.e('Create order error: $e');
      Utils.showSnackbar('错误', '创建订单时出错: $e', isError: true);
    } finally {
      isPaymentLoading.value = false;
    }
  }

  /// 处理支付
  Future<void> processPayment() async {
    if (currentOrder.value == null) {
      Utils.showSnackbar('错误', '请先创建订单', isError: true);
      return;
    }

    try {
      isPaymentLoading.value = true;

      // 处理支付
      final success =
          await _paymentRepository.processPayment(currentOrder.value!);

      if (success) {
        Utils.showSnackbar('成功', '支付成功');

        // 更新用户信息
        await _loadUserInfo();
      } else {
        Utils.showSnackbar('错误', '支付失败', isError: true);
      }
    } catch (e) {
      Logger.e('Process payment error: $e');
      Utils.showSnackbar('错误', '处理支付时出错: $e', isError: true);
    } finally {
      isPaymentLoading.value = false;
    }
  }

  /// 获取订单状态
  Future<void> getOrderStatus() async {
    if (currentOrder.value == null) {
      Utils.showSnackbar('错误', '请先创建订单', isError: true);
      return;
    }

    try {
      isPaymentLoading.value = true;

      // 获取订单状态
      final order =
          await _paymentRepository.getOrderStatus(currentOrder.value!.id);

      if (order != null) {
        currentOrder.value = order;
        Utils.showSnackbar('成功', '订单状态: ${order.status}');
      } else {
        Utils.showSnackbar('错误', '获取订单状态失败', isError: true);
      }
    } catch (e) {
      Logger.e('Get order status error: $e');
      Utils.showSnackbar('错误', '获取订单状态时出错: $e', isError: true);
    } finally {
      isPaymentLoading.value = false;
    }
  }

  /// 测试会员权益
  Future<void> testMembershipBenefits() async {
    if (!isLoggedIn.value || currentUser.value == null) {
      Utils.showSnackbar('错误', '请先登录', isError: true);
      return;
    }

    try {
      isPaymentLoading.value = true;

      // 获取当前用户信息
      final user = currentUser.value!;

      // 检查会员状态
      final bool isPremium = user.level >= 1;
      final bool isPro = user.level >= 2;
      final bool isActive = user.membershipExpiry != null &&
          user.membershipExpiry!.isAfter(DateTime.now());

      // 构建会员权益测试结果
      final StringBuffer result = StringBuffer();
      result.writeln('会员权益测试结果:');
      result.writeln(
          '- 会员等级: ${user.level} (${isPro ? "专业会员" : (isPremium ? "高级会员" : "普通用户")})');
      result.writeln('- 会员状态: ${isActive ? "有效" : "已过期"}');
      if (user.membershipExpiry != null) {
        result.writeln(
            '- 到期时间: ${user.membershipExpiry!.toString().split('.')[0]}');
      }
      result.writeln('- 积分余额: ${user.credits}');

      // 测试下载限制
      result.writeln('\n下载限制测试:');
      if (isPremium && isActive) {
        result.writeln('- 每日下载限制: 无限制');
        result.writeln('- 并发下载数: ${isPro ? "无限制" : "5个"}');
        result.writeln('- 最大视频质量: ${isPro ? "8K" : "4K"}');
      } else {
        result.writeln('- 每日下载限制: 10个');
        result.writeln('- 并发下载数: 2个');
        result.writeln('- 最大视频质量: 1080p');
      }

      // 测试格式转换功能
      result.writeln('\n格式转换测试:');
      if (isPremium && isActive) {
        result.writeln('- 格式转换功能: 可用');
        result.writeln('- 支持的格式: ${isPro ? "全部格式" : "常用格式"}');
        result.writeln('- 批量转换: ${isPro ? "可用" : "不可用"}');
      } else {
        result.writeln('- 格式转换功能: 不可用');
      }

      // 显示测试结果
      apiResponse.value = result.toString();
      Utils.showSnackbar('成功', '会员权益测试完成');
    } catch (e) {
      Logger.e('Test membership benefits error: $e');
      Utils.showSnackbar('错误', '测试会员权益时出错: $e', isError: true);
    } finally {
      isPaymentLoading.value = false;
    }
  }

  /// 模拟支付成功
  Future<void> simulateSuccessfulPayment() async {
    if (!isLoggedIn.value || currentUser.value == null) {
      Utils.showSnackbar('错误', '请先登录', isError: true);
      return;
    }

    if (selectedProduct.value == null) {
      Utils.showSnackbar('错误', '请选择商品', isError: true);
      return;
    }

    try {
      isPaymentLoading.value = true;

      // 获取当前用户信息
      final user = currentUser.value!;

      // 根据选择的商品更新用户信息
      final product = selectedProduct.value!;
      UserModel updatedUser;

      if (product.type == ProductType.membership) {
        // 会员商品
        int level = 1; // 默认高级会员
        if (product.title.toLowerCase().contains('pro')) {
          level = 2; // 专业会员
        }

        // 计算会员到期时间
        DateTime expiry;
        if (user.membershipExpiry != null &&
            user.membershipExpiry!.isAfter(DateTime.now())) {
          // 如果当前会员未过期，则在当前到期时间基础上延长
          expiry = user.membershipExpiry!;
        } else {
          // 如果当前会员已过期，则从现在开始计算
          expiry = DateTime.now();
        }

        // 根据商品ID确定会员时长
        int days = 30; // 默认30天
        if (product.title.toLowerCase().contains('季度') ||
            product.title.toLowerCase().contains('quarterly')) {
          days = 90;
        } else if (product.title.toLowerCase().contains('年') ||
            product.title.toLowerCase().contains('yearly')) {
          days = 365;
        }

        // 更新会员到期时间
        expiry = expiry.add(Duration(days: days));

        // 更新用户信息
        updatedUser = user.copyWith(
          level: level,
          membershipExpiry: expiry,
        );
      } else {
        // 积分商品
        int credits = 0;
        if (product.metadata != null &&
            product.metadata!.containsKey('credits')) {
          credits = int.tryParse(product.metadata!['credits'].toString()) ?? 0;
        } else {
          // 根据价格估算积分
          credits = (product.price * 10).toInt();
        }

        // 更新用户信息
        updatedUser = user.copyWith(
          credits: user.credits + credits,
        );
      }

      // 更新用户服务中的用户信息
      _userService.mockUpdateUser(updatedUser);

      // 创建模拟订单
      final order = OrderModel(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        userId: user.userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        amount: product.price,
        currency: product.currency,
        status: 'completed',
        paymentMethod: selectedPaymentMethod.value,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      currentOrder.value = order;

      Utils.showSnackbar('成功', '模拟支付成功，用户权益已更新');

      // 更新用户信息
      await _loadUserInfo();
    } catch (e) {
      Logger.e('Simulate successful payment error: $e');
      Utils.showSnackbar('错误', '模拟支付时出错: $e', isError: true);
    } finally {
      isPaymentLoading.value = false;
    }
  }
}
