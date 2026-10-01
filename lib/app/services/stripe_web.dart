import 'package:tubesavely/app/utils/logger.dart';

// 导出通用Stripe平台接口
export '../services/stripe_platform.dart';

// 检查是否是Web平台
bool get isWebPlatform => false;

// 初始化Stripe
void initStripe(String publishableKey) {
  try {
    if (isWebPlatform) {
      // 在Web平台上初始化Stripe
      // 这里的代码会在编译时被替换为实际的Stripe初始化代码
      Logger.d('Stripe initialized on web platform');
    } else {
      Logger.d('Stripe is not supported on this platform');
    }
  } catch (e) {
    Logger.e('Error initializing Stripe: $e');
  }
}
