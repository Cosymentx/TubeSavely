/// API响应模型
///
/// 用于统一处理API响应格式
class ApiResponseModel<T> {
  /// 响应码
  final int code;
  
  /// 响应消息
  final String message;
  
  /// 响应数据
  final T? data;
  
  /// 是否成功
  bool get isSuccess => code == 200;
  
  /// 是否未授权
  bool get isUnauthorized => code == 401;
  
  /// 是否禁止访问
  bool get isForbidden => code == 403;
  
  /// 是否未找到
  bool get isNotFound => code == 404;
  
  /// 是否服务器错误
  bool get isServerError => code >= 500;
  
  ApiResponseModel({
    required this.code,
    required this.message,
    this.data,
  });
  
  /// 从JSON创建API响应模型
  factory ApiResponseModel.fromJson(Map<String, dynamic> json, {T? Function(dynamic)? fromJson}) {
    return ApiResponseModel<T>(
      code: json['code'] ?? 500,
      message: json['msg'] ?? 'Unknown error',
      data: json['data'] != null && fromJson != null ? fromJson(json['data']) : json['data'] as T?,
    );
  }
  
  /// 创建成功响应
  factory ApiResponseModel.success(T? data, {String message = 'Success'}) {
    return ApiResponseModel<T>(
      code: 200,
      message: message,
      data: data,
    );
  }
  
  /// 创建错误响应
  factory ApiResponseModel.error(int code, String message, {T? data}) {
    return ApiResponseModel<T>(
      code: code,
      message: message,
      data: data,
    );
  }
  
  /// 创建未授权响应
  factory ApiResponseModel.unauthorized({String message = 'Unauthorized'}) {
    return ApiResponseModel<T>(
      code: 401,
      message: message,
      data: null,
    );
  }
  
  /// 创建禁止访问响应
  factory ApiResponseModel.forbidden({String message = 'Forbidden'}) {
    return ApiResponseModel<T>(
      code: 403,
      message: message,
      data: null,
    );
  }
  
  /// 创建未找到响应
  factory ApiResponseModel.notFound({String message = 'Not found'}) {
    return ApiResponseModel<T>(
      code: 404,
      message: message,
      data: null,
    );
  }
  
  /// 创建服务器错误响应
  factory ApiResponseModel.serverError({String message = 'Server error'}) {
    return ApiResponseModel<T>(
      code: 500,
      message: message,
      data: null,
    );
  }
  
  /// 转换为字符串
  @override
  String toString() {
    return 'ApiResponseModel{code: $code, message: $message, data: $data}';
  }
}
