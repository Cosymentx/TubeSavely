import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as flutter_stripe;
import 'package:tubesavely/app/utils/logger.dart';

// 检查是否是移动平台
bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;

// Stripe类
class Stripe {
  static Stripe get instance => _instance;
  static final Stripe _instance = Stripe._();

  Stripe._();

  static String _publishableKey = '';

  static set publishableKey(String key) {
    _publishableKey = key;
    if (isMobilePlatform) {
      try {
        // 设置Stripe发布密钥
        flutter_stripe.Stripe.publishableKey = key;
        Logger.d('Stripe publishable key set');
      } catch (e) {
        Logger.e('Error setting Stripe publishable key: $e');
      }
    }
  }

  static String get publishableKey => _publishableKey;

  // 应用设置
  Future<void> applySettings() async {
    try {
      if (isMobilePlatform) {
        // 应用Stripe设置
        await flutter_stripe.Stripe.instance.applySettings();
        Logger.d('Stripe settings applied');
      }
    } catch (e) {
      Logger.e('Error applying Stripe settings: $e');
      rethrow;
    }
  }

  // 检查平台支付是否可用
  Future<bool> isPlatformPaySupported() async {
    try {
      if (isMobilePlatform) {
        if (Platform.isAndroid) {
          // 检查Google Pay是否可用
          final params = flutter_stripe.IsGooglePaySupportedParams(
            testEnv: true,
            existingPaymentMethodRequired: false,
          );
          return await flutter_stripe.Stripe.instance
              .isPlatformPaySupported(googlePay: params);
        } else if (Platform.isIOS) {
          // 检查Apple Pay是否可用
          // 在iOS上，我们只需要检查设备是否支持Apple Pay
          return true; // 简化处理，实际应用中应该使用Apple Pay SDK检查
        }
      }
      return false;
    } catch (e) {
      Logger.e('Error checking platform pay support: $e');
      return false;
    }
  }

  // 初始化支付表单
  Future<void> initPaymentSheet(
      {required SetupPaymentSheetParameters paymentSheetParameters}) async {
    try {
      if (isMobilePlatform) {
        // 初始化支付表单
        await flutter_stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: flutter_stripe.SetupPaymentSheetParameters(
            merchantDisplayName: paymentSheetParameters.merchantDisplayName,
            paymentIntentClientSecret:
                paymentSheetParameters.paymentIntentClientSecret,
            style: paymentSheetParameters.style == ThemeMode.dark
                ? ThemeMode.dark
                : (paymentSheetParameters.style == ThemeMode.light
                    ? ThemeMode.light
                    : ThemeMode.system),
            appearance: flutter_stripe.PaymentSheetAppearance(
              colors: flutter_stripe.PaymentSheetAppearanceColors(
                primary: paymentSheetParameters.appearance?.colors?.primary ??
                    Colors.blue,
              ),
            ),
            googlePay: paymentSheetParameters.googlePay != null
                ? flutter_stripe.PaymentSheetGooglePay(
                    merchantCountryCode:
                        paymentSheetParameters.googlePay.merchantCountryCode,
                    testEnv: paymentSheetParameters.googlePay.testEnv,
                  )
                : null,
          ),
        );
        Logger.d('Payment sheet initialized');
      }
    } catch (e) {
      Logger.e('Error initializing payment sheet: $e');
      rethrow;
    }
  }

  // 显示支付表单
  Future<void> presentPaymentSheet() async {
    try {
      if (isMobilePlatform) {
        // 显示支付表单
        await flutter_stripe.Stripe.instance.presentPaymentSheet();
        Logger.d('Payment sheet presented');
      }
    } catch (e) {
      Logger.e('Error presenting payment sheet: $e');
      rethrow;
    }
  }
}

// Stripe异常
class StripeException implements Exception {
  final StripeError error;

  StripeException(this.error);

  factory StripeException.fromStripeError(StripeError stripeError) {
    return StripeException(stripeError);
  }
}

// Stripe错误
class StripeError {
  final String? localizedMessage;

  StripeError({this.localizedMessage});

  factory StripeError.fromStripeException(dynamic e) {
    if (e is StripeException) {
      return StripeError(localizedMessage: e.error.localizedMessage);
    }
    return StripeError(localizedMessage: e.toString());
  }
}

// 支付表单参数
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

// 支付表单外观
class PaymentSheetAppearance {
  final dynamic colors;

  const PaymentSheetAppearance({this.colors});
}

// 支付表单颜色
class PaymentSheetAppearanceColors {
  final dynamic primary;

  const PaymentSheetAppearanceColors({this.primary});
}

// Google Pay支付表单
class PaymentSheetGooglePay {
  final String merchantCountryCode;
  final bool testEnv;

  const PaymentSheetGooglePay({
    required this.merchantCountryCode,
    required this.testEnv,
  });
}
