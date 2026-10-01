/// 任务状态枚举
enum TaskStatus {
  pending,    // 等待中
  processing, // 处理中
  completed,  // 已完成
  failed,     // 失败
  canceled,   // 已取消
}

/// 任务类型枚举
enum TaskType {
  convert,   // 转换任务
  generate,  // 生成任务
}

/// 任务模型
class TaskModel {
  final int? id;
  final String title;
  final String? description;
  final TaskType type;
  final TaskStatus status;
  final int creditsCost;
  final String? inputUrl;
  final Map<String, dynamic>? inputParams;
  final String? outputUrl;
  final String? outputFormat;
  final double progress;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final int? userId;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    required this.type,
    this.status = TaskStatus.pending,
    required this.creditsCost,
    this.inputUrl,
    this.inputParams,
    this.outputUrl,
    this.outputFormat,
    this.progress = 0.0,
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.userId,
  });

  /// 从JSON创建任务模型
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      type: _parseTaskType(json['type'] ?? 'convert'),
      status: _parseTaskStatus(json['status'] ?? 'pending'),
      creditsCost: json['credits_cost'] ?? 0,
      inputUrl: json['input_url'],
      inputParams: json['input_params'],
      outputUrl: json['output_url'],
      outputFormat: json['output_format'],
      progress: (json['progress'] is num) ? (json['progress'] as num).toDouble() : 0.0,
      errorMessage: json['error_message'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      userId: json['user_id'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'credits_cost': creditsCost,
      if (inputUrl != null) 'input_url': inputUrl,
      if (inputParams != null) 'input_params': inputParams,
      if (outputUrl != null) 'output_url': outputUrl,
      if (outputFormat != null) 'output_format': outputFormat,
      'progress': progress,
      if (errorMessage != null) 'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (userId != null) 'user_id': userId,
    };
  }

  /// 复制任务模型
  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    TaskType? type,
    TaskStatus? status,
    int? creditsCost,
    String? inputUrl,
    Map<String, dynamic>? inputParams,
    String? outputUrl,
    String? outputFormat,
    double? progress,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? userId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      creditsCost: creditsCost ?? this.creditsCost,
      inputUrl: inputUrl ?? this.inputUrl,
      inputParams: inputParams ?? this.inputParams,
      outputUrl: outputUrl ?? this.outputUrl,
      outputFormat: outputFormat ?? this.outputFormat,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
    );
  }

  /// 解析任务类型
  static TaskType _parseTaskType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'generate':
        return TaskType.generate;
      case 'convert':
      default:
        return TaskType.convert;
    }
  }

  /// 解析任务状态
  static TaskStatus _parseTaskStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'processing':
        return TaskStatus.processing;
      case 'completed':
        return TaskStatus.completed;
      case 'failed':
        return TaskStatus.failed;
      case 'canceled':
        return TaskStatus.canceled;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  /// 获取状态文本
  String get statusText {
    switch (status) {
      case TaskStatus.pending:
        return '等待中';
      case TaskStatus.processing:
        return '处理中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.failed:
        return '失败';
      case TaskStatus.canceled:
        return '已取消';
    }
  }

  /// 获取类型文本
  String get typeText {
    switch (type) {
      case TaskType.convert:
        return '转换任务';
      case TaskType.generate:
        return '生成任务';
    }
  }

  /// 获取进度文本
  String get progressText {
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  /// 是否可以取消
  bool get canCancel {
    return status == TaskStatus.pending || status == TaskStatus.processing;
  }

  /// 是否可以重试
  bool get canRetry {
    return status == TaskStatus.failed;
  }

  /// 是否已完成
  bool get isCompleted {
    return status == TaskStatus.completed;
  }

  /// 是否失败
  bool get isFailed {
    return status == TaskStatus.failed;
  }
}
