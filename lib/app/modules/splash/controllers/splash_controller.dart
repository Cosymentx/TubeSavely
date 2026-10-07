import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../services/init_services.dart';
import '../../../utils/logger.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void onInit() {
    super.onInit();
    Logger.d('SplashController initialized');

    // 优雅的 800ms 品牌入场动画
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 平滑缓动
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    );

    // 启动动画
    animationController.forward();

    // 启动极速就绪流转
    _startStartupFlow();
  }

  /// 等待品牌动画完整展现并同步后台服务就绪
  Future<void> _startStartupFlow() async {
    try {
      // 既保障 Logo 动画平滑播放完毕（800ms，避免突兀闪跳）
      // 又等待后台服务就绪（设置 1500ms 超时上限兜底，保障网络不佳时绝不卡死）
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 800)),
        servicesReady.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () {
            Logger.w('后台服务初始化已达安全超时上限，立即放行跳转主页');
          },
        ),
      ]);
    } catch (e) {
      Logger.e('Splash 等待过程出现异常: $e');
    } finally {
      _navigateToHome();
    }
  }

  // 导航到首页
  void _navigateToHome() {
    if (isClosed) return;
    try {
      Logger.d('All repositories & services ready, navigating to main');
      Get.offAllNamed(Routes.MAIN);
    } catch (e) {
      Logger.e('Error navigating to main: $e');

      // 降级防卡死保护，仅尝试一次快速跳转
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!isClosed) {
          Get.offAllNamed(Routes.MAIN);
        }
      });
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
