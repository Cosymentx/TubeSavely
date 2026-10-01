import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tubesavely/app/data/models/payment_model.dart';
import 'package:tubesavely/app/data/models/user_model.dart';
import 'package:tubesavely/app/data/repositories/payment_repository.dart';
import 'package:tubesavely/app/services/stripe_service.dart';
import 'package:tubesavely/app/services/payment_service.dart';
import 'package:tubesavely/app/services/user_service.dart';
import 'package:tubesavely/app/utils/logger.dart';
import 'package:tubesavely/app/utils/utils.dart';

/// 支付控制器
class PaymentController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final PaymentRepository _paymentRepository = Get.find<PaymentRepository>();
  final UserService _userService = Get.find<UserService>();
  final StripeService _stripeService = Get.find<StripeService>();

  // 标签控制器
  late TabController tabController;

  // 商品列表
  final RxList<ProductModel> membershipProducts = <ProductModel>[].obs;
  final RxList<ProductModel> creditsProducts = <ProductModel>[].obs;

  // 选中的商品
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);

  // 选中的支付方式
  final Rx<PaymentMethod> selectedPaymentMethod = Rx<PaymentMethod>(
    PaymentMethod.stripe,
  );

  // 当前订单
  final Rx<OrderModel?> currentOrder = Rx<OrderModel?>(null);

  // 是否正在加载
  final RxBool isLoading = false.obs;

  // 用户信息
  final Rx<UserModel?> userInfo = Rx<UserModel?>(null);

  // 是否支持Google Pay
  final RxBool isGooglePaySupported = false.obs;

  @override
  void onInit() {
    super.onInit();
    Logger.d('PaymentController initialized');

    // 初始化标签控制器
    tabController = TabController(length: 2, vsync: this);

    // 检查是否有初始标签参数
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args.containsKey('initialTab')) {
        final initialTab = args['initialTab'] as int;
        if (initialTab >= 0 && initialTab < tabController.length) {
          tabController.index = initialTab;
        }
      }
    }

    // 加载商品列表
    loadProducts();

    // 加载用户信息
    loadUserInfo();

    // 检查Google Pay是否可用
    if (GetPlatform.isAndroid) {
      checkGooglePaySupport();
    }
  }

  /// 检查Google Pay是否可用
  Future<void> checkGooglePaySupport() async {
    try {
      isGooglePaySupported.value = await _stripeService.isGooglePaySupported();
      Logger.d('Google Pay supported: ${isGooglePaySupported.value}');
    } catch (e) {
      Logger.e('Error checking Google Pay support: $e');
      isGooglePaySupported.value = false;
    }
  }

  /// 加载商品列表
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;

      final products = await _paymentRepository.getProducts();

      // 分类商品
      membershipProducts.value = products
          .where((product) => product.type == ProductType.membership)
          .toList();

      creditsProducts.value = products
          .where((product) => product.type == ProductType.credit)
          .toList();

      // 默认选中第一个商品
      if (membershipProducts.isNotEmpty) {
        selectedProduct.value = membershipProducts.first;
      } else if (creditsProducts.isNotEmpty) {
        selectedProduct.value = creditsProducts.first;
        tabController.index = 1;
      }
      final enabled =
          availablePaymentMethods.map((entry) => entry['id']).toList();
      if (!enabled.contains(selectedPaymentMethod.value.name) &&
          enabled.isNotEmpty) {
        selectPaymentMethod(PaymentMethod.values
            .firstWhere((method) => method.name == enabled.first));
      }
    } catch (e) {
      Logger.e('Error loading products: $e');
      Utils.showSnackbar('错误', '加载商品列表失败: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载用户信息
  Future<void> loadUserInfo() async {
    try {
      // 先检查用户是否已登录
      if (_userService.isLoggedIn.value) {
        // 如果已登录，获取当前用户信息
        userInfo.value = _userService.currentUser.value;

        // 如果当前用户信息为空，尝试从服务器获取
        if (userInfo.value == null) {
          userInfo.value = await _userService.getUserInfo();
        }
      } else {
        // 如果未登录，清空用户信息
        userInfo.value = null;
      }
    } catch (e) {
      Logger.e('Error loading user info: $e');
    }
  }

  /// 选择商品
  void selectProduct(ProductModel product) {
    selectedProduct.value = product;
  }

  List<Map<String, dynamic>> get availablePaymentMethods =>
      Get.find<PaymentService>().availableMethods;

  /// 选择支付方式
  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
    final config = availablePaymentMethods
        .firstWhereOrNull((entry) => entry['id'] == method.name);
    final currencies = config?['currencies'] as List? ?? [];
    final currency = currencies.contains('CNY') ? 'CNY' : 'USD';
    final selectedId = selectedProduct.value?.id;
    creditsProducts.assignAll(creditsProducts
        .map((product) => product.forCurrency(currency))
        .toList());
    selectedProduct.value =
        creditsProducts.firstWhereOrNull((product) => product.id == selectedId);
  }

  /// 创建订单
  Future<void> createOrder() async {
    if (selectedProduct.value == null) {
      Utils.showSnackbar('错误', '请选择商品', isError: true);
      return;
    }

    try {
      isLoading.value = true;

      final order = await _paymentRepository.createOrder(
        selectedProduct.value!.id,
        selectedPaymentMethod.value,
        currency: selectedProduct.value!.currency,
      );

      if (order != null) {
        currentOrder.value = order;

        // 处理支付
        await processPayment(order);
      } else {
        Utils.showSnackbar('错误', '创建订单失败', isError: true);
      }
    } catch (e) {
      Logger.e('Error creating order: $e');
      Utils.showSnackbar('错误', '创建订单时出错: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// 处理支付
  Future<void> processPayment(OrderModel order) async {
    try {
      isLoading.value = true;

      final success = await _paymentRepository.processPayment(order);
      final latest = Get.find<PaymentService>().currentOrder.value ?? order;
      currentOrder.value = latest;

      if (success) {
        // 支付成功，更新用户信息
        await loadUserInfo();

        // 导航到支付结果页面
        Get.toNamed(
          '/payment-result',
          arguments: {'isSuccess': true, 'order': latest},
        );
      } else {
        // 导航到支付结果页面
        Get.toNamed(
          '/payment-result',
          arguments: {
            'isSuccess': false,
            'order': latest,
            'isPending': latest.status == 'pending',
            'errorMessage': latest.status == 'pending'
                ? '订单尚未确认，请完成支付后在交易记录中查看状态。'
                : '支付处理失败，请稍后重试',
          },
        );
      }
    } catch (e) {
      Logger.e('Error processing payment: $e');

      // 导航到支付结果页面
      Get.toNamed(
        '/payment-result',
        arguments: {
          'isSuccess': false,
          'order': order,
          'errorMessage': '处理支付时出错: $e',
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 查看交易记录
  void viewTransactionHistory() {
    Get.toNamed('/transaction-history');
  }

  /// 获取订单状态
  Future<void> getOrderStatus(String orderId) async {
    try {
      isLoading.value = true;

      final order = await _paymentRepository.getOrderStatus(orderId);

      if (order != null) {
        currentOrder.value = order;

        // 如果订单已完成，更新用户信息
        if (order.status == 'completed') {
          await loadUserInfo();
          Utils.showSnackbar('成功', '支付成功');
        }
      }
    } catch (e) {
      Logger.e('Error getting order status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
