import 'package:get/get.dart';
import 'package:tubesavely/app/data/models/payment_model.dart';
import 'package:tubesavely/app/data/providers/api_provider.dart';
import 'package:tubesavely/app/services/payment_service.dart';
import 'package:tubesavely/app/utils/logger.dart';

/// 交易记录结果
class TransactionResult {
  final List<OrderModel> transactions;
  final bool hasMore;

  TransactionResult({
    required this.transactions,
    required this.hasMore,
  });
}

/// 兼容旧版API的参数
extension PaymentRepositoryExtension on PaymentRepository {
  /// 获取交易记录（兼容旧版API）
  Future<TransactionResult> getTransactionsCompat({
    required int page,
    required int pageSize,
  }) async {
    return getTransactions(
      offset: (page - 1) * pageSize,
      limit: pageSize,
    );
  }
}

/// 支付仓库
///
/// 负责处理支付相关的数据操作
class PaymentRepository {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final PaymentService _paymentService = Get.find<PaymentService>();

  /// 获取商品列表
  Future<List<ProductModel>> getProducts() async {
    try {
      // 如果已经加载过商品列表，直接返回
      if (_paymentService.products.isNotEmpty) {
        return _paymentService.products;
      }

      // 加载商品列表
      await _paymentService.loadProducts();
      return _paymentService.products;
    } catch (e) {
      Logger.e('Error getting products: $e');
      return [];
    }
  }

  /// 创建订单
  ///
  /// [productId] 商品ID
  /// [paymentMethod] 支付方式
  /// [currency] 货币类型，默认为CNY
  Future<OrderModel?> createOrder(String productId, PaymentMethod paymentMethod,
      {String currency = 'CNY'}) async {
    try {
      return await _paymentService.createOrder(productId, paymentMethod,
          currency: currency);
    } catch (e) {
      Logger.e('Error creating order: $e');
      return null;
    }
  }

  /// 处理支付
  ///
  /// [order] 订单
  Future<bool> processPayment(OrderModel order) async {
    try {
      return await _paymentService.processPayment(order);
    } catch (e) {
      Logger.e('Error processing payment: $e');
      return false;
    }
  }

  /// 获取订单状态
  ///
  /// [orderId] 订单ID
  Future<OrderModel?> getOrderStatus(String orderId) async {
    try {
      final response = await _apiProvider.getOrderStatus(orderId);

      if (response.status.isOk && response.body != null) {
        final body = response.body;
        if (body is Map && body['code'] == 200 && body['data'] is Map) {
          final previous = _paymentService.currentOrder.value;
          return OrderModel.fromJson({
            if (previous?.id == orderId) ...previous!.toJson(),
            ...Map<String, dynamic>.from(body['data']),
            'order_id': orderId,
          });
        }
      }

      return null;
    } catch (e) {
      Logger.e('Error getting order status: $e');
      return null;
    }
  }

  /// 验证支付
  ///
  /// [data] 支付验证数据
  Future<bool> verifyPayment(Map<String, dynamic> data) async {
    try {
      final response = await _apiProvider.verifyPayment(data);
      return response.status.isOk &&
          response.body is Map &&
          response.body['code'] == 200 &&
          response.body['data']?['status'] == 'completed';
    } catch (e) {
      Logger.e('Error verifying payment: $e');
      return false;
    }
  }

  /// 获取交易记录
  ///
  /// [offset] 偏移量
  /// [limit] 限制数量
  Future<TransactionResult> getTransactions({
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _apiProvider.getTransactions(
        offset: offset,
        limit: limit,
      );

      if (response.status.isOk && response.body != null) {
        final data = response.body['data'];
        if (data is Map && data['records'] is List) {
          final records = data['records'] as List;
          final List<OrderModel> transactions = records
              .map((item) => OrderModel.fromJson(item))
              .toList()
              .cast<OrderModel>();

          // 获取总数
          final total = data['total'] ?? transactions.length;
          final hasMore = offset + transactions.length < total;

          return TransactionResult(
            transactions: transactions,
            hasMore: hasMore,
          );
        }
      }

      return TransactionResult(
        transactions: [],
        hasMore: false,
      );
    } catch (e) {
      Logger.e('Error getting transactions: $e');
      return TransactionResult(
        transactions: [],
        hasMore: false,
      );
    }
  }

  /// 获取支付宝支付参数
  ///
  /// [orderId] 订单ID
  Future<Map<String, dynamic>?> getAlipayParams(String orderId) async {
    try {
      Logger.d('Getting Alipay params: $orderId');

      final response = await _apiProvider.getAlipayParams(orderId);

      if (response.status.isOk) {
        return response.body['data'];
      }

      return null;
    } catch (e) {
      Logger.e('Error getting Alipay params: $e');
      return null;
    }
  }

  /// 获取微信支付参数
  ///
  /// [orderId] 订单ID
  Future<Map<String, dynamic>?> getWechatPayParams(String orderId) async {
    try {
      Logger.d('Getting WeChat Pay params: $orderId');

      final response = await _apiProvider.getWechatPayParams(orderId);

      if (response.status.isOk) {
        return response.body['data'];
      }

      return null;
    } catch (e) {
      Logger.e('Error getting WeChat Pay params: $e');
      return null;
    }
  }

  /// 获取交易详情
  ///
  /// [orderId] 订单ID
  Future<OrderModel?> getTransactionDetails(String orderId) async {
    try {
      final response = await _apiProvider.get('/orders/$orderId');

      if (response.status.isOk && response.body != null) {
        return OrderModel.fromJson(response.body);
      }

      return null;
    } catch (e) {
      Logger.e('Error getting transaction details: $e');
      return null;
    }
  }
}
