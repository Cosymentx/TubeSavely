import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';
import '../utils/logger.dart';
import '../data/providers/api_provider.dart';
import '../data/providers/storage_provider.dart';
import '../data/repositories/credit_repository.dart';
import '../data/repositories/download_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/video_repository.dart';
import '../data/repositories/video_converter_repository.dart';
import '../data/repositories/video_player_repository.dart';
import 'theme_service.dart';
import 'translation_service.dart';
import 'video_parser_service.dart';
import 'download_service.dart';
import 'payment_service.dart';
import 'stripe_service.dart';
import 'apple_payment_service.dart';
import 'video_converter_service.dart';
import 'video_compress_service.dart';
import 'video_player_service.dart';
import 'user_service.dart';

final Completer<void> _servicesReadyCompleter = Completer<void>();

/// 提供给 Splash 或其它页面的异步初始化就绪信号
Future<void> get servicesReady => _servicesReadyCompleter.future;

bool _isAsyncInitialized = false;

/// 阶段一：极速初始化核心基础服务（耗时 ~10-20ms，保障 runApp 瞬间执行）
Future<void> initCoreServices() async {
  Logger.i('正在初始化核心基础服务...');

  // 1. 注册核心本地存储
  Get.put(StorageProvider(), permanent: true);
  await GetStorage.init();
  Get.put(GetStorage(), permanent: true);

  // 2. 注册网络 API 提供者
  Get.put(ApiProvider(), permanent: true);

  // 3. 初始化并注册主题服务
  final themeService = await ThemeService().init();
  Get.put(themeService, permanent: true);

  // 4. 注册多语言翻译服务
  Get.put(TranslationService(), permanent: true);

  Logger.i('核心基础服务初始化完成');
}

/// 阶段二：后台并行初始化所有重型服务与仓库（不阻塞首帧渲染）
Future<void> initAsyncServices() async {
  if (_isAsyncInitialized) return;
  _isAsyncInitialized = true;

  Logger.i('正在后台并行初始化重型组件与业务服务...');

  try {
    // 并行组 1：播放器与 MediaKit
    final mediaFuture = () async {
      try {
        MediaKit.ensureInitialized();
        final videoPlayerService = await VideoPlayerService().init();
        Get.put(videoPlayerService, permanent: true);
      } catch (e) {
        Logger.e('MediaKit / VideoPlayerService 初始化失败: $e');
        Get.put(VideoPlayerService(), permanent: true);
      }
    }();

    // 并行组 2：视频解析、下载与格式转换
    final videoFuture = () async {
      try {
        final videoParserService = await VideoParserService().init();
        Get.put(videoParserService, permanent: true);
      } catch (e) {
        Logger.e('VideoParserService 初始化失败: $e');
        Get.put(VideoParserService(), permanent: true);
      }

      try {
        final downloadService = await DownloadService().init();
        Get.put(downloadService, permanent: true);
      } catch (e) {
        Logger.e('DownloadService 初始化失败: $e');
        Get.put(DownloadService(), permanent: true);
      }

      try {
        final videoConverterService = await VideoConverterService().init();
        Get.put(videoConverterService, permanent: true);
      } catch (e) {
        Logger.e('VideoConverterService 初始化失败: $e');
        Get.put(VideoConverterService(), permanent: true);
      }

      Get.put(VideoCompressService(), permanent: true);
    }();

    // 并行组 3：用户服务
    final userFuture = () async {
      try {
        final userService = await UserService().init();
        Get.put(userService, permanent: true);
      } catch (e) {
        Logger.e('UserService 初始化失败: $e');
        Get.put(UserService(), permanent: true);
      }
    }();

    // 并行组 4：支付通道
    final paymentFuture = () async {
      try {
        final stripeService = await StripeService().init();
        Get.put(stripeService, permanent: true);
      } catch (e) {
        Logger.e('初始化Stripe服务失败: $e');
        Get.put(StripeService(), permanent: true);
      }

      try {
        final applePaymentService = await ApplePaymentService().init();
        Get.put(applePaymentService, permanent: true);
      } catch (e) {
        Logger.e('初始化Apple支付服务失败: $e');
        Get.put(ApplePaymentService(), permanent: true);
      }

      try {
        final paymentService = await PaymentService().init();
        Get.put(paymentService, permanent: true);
      } catch (e) {
        Logger.e('初始化支付服务失败: $e');
        Get.put(PaymentService(), permanent: true);
      }
    }();

    // 等待所有服务并行初始化完成
    await Future.wait([
      mediaFuture,
      videoFuture,
      userFuture,
      paymentFuture,
    ]);

    // 注册仓库（依赖上述服务）
    if (!Get.isRegistered<UserRepository>()) {
      Get.put(UserRepository(), permanent: true);
    }
    if (!Get.isRegistered<VideoRepository>()) {
      Get.put(VideoRepository(), permanent: true);
    }
    if (!Get.isRegistered<DownloadRepository>()) {
      Get.put(DownloadRepository(), permanent: true);
    }
    if (!Get.isRegistered<VideoConverterRepository>()) {
      Get.put(VideoConverterRepository(), permanent: true);
    }
    if (!Get.isRegistered<VideoPlayerRepository>()) {
      Get.put(VideoPlayerRepository(), permanent: true);
    }
    if (!Get.isRegistered<PaymentRepository>()) {
      Get.put(PaymentRepository(), permanent: true);
    }
    if (!Get.isRegistered<TaskRepository>()) {
      Get.put(TaskRepository(), permanent: true);
    }
    if (!Get.isRegistered<CreditRepository>()) {
      Get.put(CreditRepository(), permanent: true);
    }

    Logger.i('所有后台业务服务与仓库已就绪');
  } catch (e) {
    Logger.e('后台服务初始化异常: $e');
  } finally {
    if (!_servicesReadyCompleter.isCompleted) {
      _servicesReadyCompleter.complete();
    }
  }
}

/// 统一入口：移动端非阻塞快速启动，桌面端等待就绪
Future<void> initServices() async {
  await initCoreServices();

  if (GetPlatform.isMobile) {
    // 移动端：后台并行加载，让 runApp 毫秒级展示
    unawaited(initAsyncServices());
  } else {
    // 桌面端：在展示主窗口前加载完毕
    await initAsyncServices();
  }
}
