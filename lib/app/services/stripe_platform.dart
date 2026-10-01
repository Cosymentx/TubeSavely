/// 通用Stripe平台接口
/// 
/// 这个文件定义了Stripe服务的通用接口，用于在不同平台上提供一致的API
/// 实际实现在stripe_mobile.dart和stripe_web.dart中

// 模拟Stripe类
class Stripe {
  static Stripe get instance => _instance;
  static final Stripe _instance = Stripe._();
  
  Stripe._();
  
  static String publishableKey = '';
  
  // 应用设置
  Future<void> applySettings() async {
    // 空实现，在不支持的平台上不执行任何操作
  }
  
  // 检查平台支付是否可用
  Future<bool> isPlatformPaySupported() async {
    // 在不支持的平台上返回false
    return false;
  }
  
  // 初始化支付表单
  Future<void> initPaymentSheet({required dynamic paymentSheetParameters}) async {
    // 空实现，在不支持的平台上不执行任何操作
  }
  
  // 显示支付表单
  Future<void> presentPaymentSheet() async {
    // 空实现，在不支持的平台上不执行任何操作
  }
}

// 模拟Stripe异常
class StripeException implements Exception {
  final StripeError error;
  
  StripeException(this.error);
}

// 模拟Stripe错误
class StripeError {
  final String? localizedMessage;
  
  StripeError({this.localizedMessage});
}

// 模拟支付表单参数
class SetupPaymentSheetParameters {
  final String merchantDisplayName;
  final String paymentIntentClientSecret;
  final dynamic style;
  final dynamic appearance;
  final dynamic googlePay;
  
  const SetupPaymentSheetParameters({
    required this.merchantDisplayName,
    required this.paymentIntentClientSecret,
    this.style,
    this.appearance,
    this.googlePay,
  });
}

// 模拟支付表单外观
class PaymentSheetAppearance {
  final dynamic colors;
  
  const PaymentSheetAppearance({this.colors});
}

// 模拟支付表单颜色
class PaymentSheetAppearanceColors {
  final dynamic primary;
  
  const PaymentSheetAppearanceColors({this.primary});
}

// 模拟Google Pay支付表单
class PaymentSheetGooglePay {
  final String merchantCountryCode;
  final bool testEnv;
  
  const PaymentSheetGooglePay({
    required this.merchantCountryCode,
    required this.testEnv,
  });
}
