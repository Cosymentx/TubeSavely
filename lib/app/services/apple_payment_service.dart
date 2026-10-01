import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tubesavely/app/data/models/payment_model.dart';
import 'package:tubesavely/app/data/providers/api_provider.dart';
import 'package:tubesavely/app/utils/logger.dart';
import 'package:flutter/foundation.dart';

/// Apple支付服务
///
/// 负责处理Apple In-App Purchase相关的业务逻辑
class ApplePaymentService extends GetxService {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // In-App Purchase实例
  late final InAppPurchase _inAppPurchase;

  // 购买更新订阅
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // 当前订单
  OrderModel? _currentOrder;

  // 支付结果回调
  Function(bool success, String? errorMessage)? _paymentCallback;

  // 是否可用
  final RxBool isAvailable = false.obs;

  // 商品列表
  final RxList<ProductDetails> products = <ProductDetails>[].obs;

  /// 初始化服务
  Future<ApplePaymentService> init() async {
    Logger.d('ApplePaymentService initialized');

    try {
      // 检查平台
      if (Platform.isIOS || Platform.isMacOS) {
        try {
          // 初始化In-App Purchase
          _inAppPurchase = InAppPurchase.instance;

          // 检查是否可用
          isAvailable.value = await _inAppPurchase.isAvailable();

          if (isAvailable.value) {
            // 监听购买更新
            _subscription = _inAppPurchase.purchaseStream.listen(
              _listenToPurchaseUpdated,
              onDone: () {
                _subscription?.cancel();
              },
              onError: (error) {
                Logger.e('Error in purchase stream: $error');
              },
            );

            // 加载商品
            await _loadProducts();

            Logger.d('Apple Payment Service initialized successfully');
          } else {
            Logger.d('In-App Purchase is not available on this device');
          }
        } catch (e) {
          Logger.e('Error initializing Apple Payment Service: $e');
          isAvailable.value = false;
        }
      } else {
        Logger.d('Apple Payment Service not available on this platform');
        isAvailable.value = false;
      }
    } catch (e) {
      // 捕获所有异常，确保服务初始化不会失败
      Logger.e('Unexpected error in Apple Payment Service init: $e');
      isAvailable.value = false;
    }

    return this;
  }

  /// 加载商品
  Future<void> _loadProducts() async {
    try {
      // 商品ID列表
      final Set<String> productIds = {
        'membership_monthly',
        'membership_quarterly',
        'membership_yearly',
        'membership_pro_monthly',
        'membership_pro_yearly',
        'credits_100',
        'credits_300',
        'credits_500',
        'credits_1000',
      };

      // 加载商品
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        Logger.w('Products not found: ${response.notFoundIDs}');
      }

      products.assignAll(response.productDetails);
      Logger.d('Loaded ${products.length} products');
    } catch (e) {
      Logger.e('Error loading products: $e');
    }
  }

  /// 处理Apple支付
  ///
  /// [order] 订单
  /// [callback] 支付结果回调
  Future<bool> processPayment(
    OrderModel order, {
    Function(bool success, String? errorMessage)? callback,
  }) async {
    try {
      Logger.d('Processing Apple payment for order: ${order.id}');

      if (!isAvailable.value) {
        Logger.e('In-App Purchase is not available');
        callback?.call(false, 'In-App Purchase is not available');
        return false;
      }

      // 保存当前订单和回调
      _currentOrder = order;
      _paymentCallback = callback;

      // 在开发模式下，模拟支付成功
      if (kDebugMode) {
        Logger.d('Simulating Apple payment success in debug mode');
        await Future.delayed(const Duration(seconds: 2));
        callback?.call(true, null);
        return true;
      }

      // 查找对应的商品
      final productId = order.productId;
      final product = products.firstWhereOrNull((p) => p.id == productId);

      if (product == null) {
        Logger.e('Product not found: $productId');
        callback?.call(false, 'Product not found: $productId');
        return false;
      }

      // 购买商品
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );

      // 发起购买
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      // 购买结果将通过purchaseStream回调
      return true;
    } catch (e) {
      Logger.e('Error processing Apple payment: $e');
      callback?.call(false, 'Error processing Apple payment: $e');
      return false;
    }
  }

  /// 恢复购买
  Future<bool> restorePurchases() async {
    try {
      Logger.d('Restoring purchases');

      if (!isAvailable.value) {
        Logger.e('In-App Purchase is not available');
        return false;
      }

      // 在开发模式下，模拟恢复购买成功
      if (kDebugMode) {
        Logger.d('Simulating restore purchases success in debug mode');
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }

      // 恢复购买
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      Logger.e('Error restoring purchases: $e');
      return false;
    }
  }

  /// 监听购买更新
  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 购买中
        Logger.d('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // 购买错误
        Logger.e('Purchase error: ${purchaseDetails.error}');
        _paymentCallback?.call(
            false, 'Purchase error: ${purchaseDetails.error?.message}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // 购买成功或恢复购买
        Logger.d(
            'Purchase ${purchaseDetails.status == PurchaseStatus.purchased ? 'purchased' : 'restored'}: ${purchaseDetails.productID}');

        // Only finish the StoreKit transaction after server-side verification.
        final verified = await _verifyPurchase(purchaseDetails);
        if (verified && purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        // 购买取消
        Logger.d('Purchase canceled: ${purchaseDetails.productID}');
        _paymentCallback?.call(false, 'Purchase canceled');
      }

    }
  }

  /// 验证购买
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // 构建验证数据
      final Map<String, dynamic> verificationData = {
        'receipt': purchaseDetails.verificationData.serverVerificationData,
        'product_id': purchaseDetails.productID,
        'transaction_id': purchaseDetails.purchaseID,
        'platform': 'ios',
        'order_id': _currentOrder?.id,
      };

      // 验证购买
      final response = await _apiProvider.verifyPayment(verificationData);

      final body = response.body;
      final verified = response.status.isOk &&
          body is Map &&
          body['code'] == 200 &&
          body['data'] is Map &&
          body['data']['status'] == 'completed';

      if (verified) {
        Logger.d('Purchase verified successfully');
        _paymentCallback?.call(true, null);
        return true;
      }

      Logger.e('Purchase verification was not confirmed by the server');
      _paymentCallback?.call(false, 'Purchase verification failed');
      return false;
    } catch (e) {
      Logger.e('Error verifying purchase: ${e.runtimeType}');
      _paymentCallback?.call(false, 'Purchase verification failed');
      return false;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
