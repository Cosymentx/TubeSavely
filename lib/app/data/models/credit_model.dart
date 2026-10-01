/// 积分模型
class CreditModel {
  final int? id;
  final int userId;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CreditModel({
    this.id,
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    this.createdAt,
    this.updatedAt,
  });

  /// 从JSON创建积分模型
  factory CreditModel.fromJson(Map<String, dynamic> json) {
    return CreditModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      balance: json['balance'] ?? 0,
      totalEarned: json['total_earned'] ?? 0,
      totalSpent: json['total_spent'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'balance': balance,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// 复制积分模型
  CreditModel copyWith({
    int? id,
    int? userId,
    int? balance,
    int? totalEarned,
    int? totalSpent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 积分历史记录模型
class CreditHistoryModel {
  final int? id;
  final int userId;
  final int amount;
  final String action;
  final String? description;
  final DateTime createdAt;

  CreditHistoryModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.action,
    this.description,
    required this.createdAt,
  });

  /// 从JSON创建积分历史记录模型
  factory CreditHistoryModel.fromJson(Map<String, dynamic> json) {
    return CreditHistoryModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      amount: json['amount'] ?? 0,
      action: json['action'] ?? '',
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'amount': amount,
      'action': action,
      if (description != null) 'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 积分套餐模型
class CreditAmountModel {
  final int? id;
  final String title;
  final String? description;
  final int amount;
  final double price;
  final String currency;
  final bool isActive;
  final bool isPopular;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CreditAmountModel({
    this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.price,
    required this.currency,
    this.isActive = true,
    this.isPopular = false,
    this.createdAt,
    this.updatedAt,
  });

  /// 从JSON创建积分套餐模型
  factory CreditAmountModel.fromJson(Map<String, dynamic> json) {
    return CreditAmountModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      amount: json['amount'] ?? 0,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      currency: json['currency'] ?? 'CNY',
      isActive: json['is_active'] ?? true,
      isPopular: json['is_popular'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'amount': amount,
      'price': price,
      'currency': currency,
      'is_active': isActive,
      'is_popular': isPopular,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// 复制积分套餐模型
  CreditAmountModel copyWith({
    int? id,
    String? title,
    String? description,
    int? amount,
    double? price,
    String? currency,
    bool? isActive,
    bool? isPopular,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditAmountModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
