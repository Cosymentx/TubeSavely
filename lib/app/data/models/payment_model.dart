import 'package:flutter/foundation.dart';

/// 支付方式枚举
enum PaymentMethod {
  applePay,
  googlePay,
  stripe,
  creem,
  alipay,
  wechatPay,
}

/// 商品类型枚举
enum ProductType {
  membership, // 会员
  credit, // 积分
  feature, // 功能
}

/// 商品模型
class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final ProductType type;
  final Map<String, dynamic>? metadata;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    this.metadata,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('amount_cny') && json.containsKey('credits')) {
      final credits = int.tryParse(json['credits'].toString()) ?? 0;
      return ProductModel(
        id: json['id'].toString(),
        title: '$credits 积分',
        description: '视频解析积分',
        price: double.tryParse(json['amount_cny'].toString()) ?? 0,
        currency: 'CNY',
        type: ProductType.credit,
        metadata: {
          'credits': credits,
          'amount_cny': json['amount_cny'],
          'amount_usd': json['amount_usd']
        },
      );
    }
    return ProductModel(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      currency: json['currency'],
      type: ProductType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ProductType.credit,
      ),
      metadata: json['metadata'],
    );
  }

  ProductModel forCurrency(String selectedCurrency) => ProductModel(
        id: id,
        title: title,
        description: description,
        price: double.tryParse(metadata?[
                        selectedCurrency == 'USD' ? 'amount_usd' : 'amount_cny']
                    ?.toString() ??
                '') ??
            price,
        currency: selectedCurrency,
        type: type,
        metadata: metadata,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'type': type.toString().split('.').last,
      'metadata': metadata,
    };
  }
}

/// 订单模型
class OrderModel {
  final String id;
  final String productId;
  final String? userId; // 改为可选
  final double amount;
  final String currency;
  final String status; // pending, completed, failed, canceled
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? errorMessage;
  final String? paymentUrl; // 添加支付URL字段

  OrderModel({
    required this.id,
    required this.productId,
    this.userId, // 改为可选
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.transactionId,
    this.errorMessage,
    this.paymentUrl, // 添加支付URL字段
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['order_id'] ?? json['id'] ?? '').toString(),
      productId:
          (json['product_id'] ?? json['credit_amount_id'] ?? '').toString(),
      userId: json['user_id']?.toString(),
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'CNY',
      status: json['status'] ?? 'pending',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (json['payment_method'] ?? '').toLowerCase(),
        orElse: () => PaymentMethod.stripe,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      transactionId: json['transaction_id'],
      errorMessage: json['error_message'],
      paymentUrl: json['payment_url'], // 添加支付URL字段
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      if (userId != null) 'user_id': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt?.toIso8601String(),
      if (transactionId != null) 'transaction_id': transactionId,
      if (errorMessage != null) 'error_message': errorMessage,
      if (paymentUrl != null) 'payment_url': paymentUrl,
    };
  }
}
