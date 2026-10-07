import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../widgets/adaptive/adaptive_shell.dart';
import '../../desktop/views/desktop_setting_dialog.dart';
import '../controllers/main_controller.dart';

/// 应用主入口视图 - 基于 AdaptiveShell 实现真正的全平台双端响应式导航架构
/// 内置桌面端专属全局快捷键体系 (Ctrl/Cmd + 1..4 切换页面，Ctrl/Cmd + , 打开设置)
class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    Widget content = Obx(() {
      final currentIndex = controller.currentIndex.value;

      return AdaptiveShell(
        currentIndex: currentIndex,
        onDestinationSelected: controller.changePage,
        destinations: const [
          AdaptiveNavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '首页',
            tooltip: '视频下载与解析 (Ctrl+1)',
          ),
          AdaptiveNavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: '历史',
            tooltip: '历史解析记录 (Ctrl+2)',
          ),
          AdaptiveNavigationDestination(
            icon: Icon(Icons.downloading_outlined),
            selectedIcon: Icon(Icons.download_done_rounded),
            label: '任务',
            tooltip: '下载与处理任务 (Ctrl+3)',
          ),
          AdaptiveNavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
            tooltip: '个人中心与设置 (Ctrl+4)',
          ),
        ],
        // 使用 IndexedStack 保持各 Tab 页面状态，防止重复构建导致输入状态或下载进度抖动
        body: IndexedStack(
          index: currentIndex,
          children: controller.pages,
        ),
      );
    });

    if (isDesktop) {
      return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          // Windows / Linux Ctrl + 1..4
          const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => controller.changePage(0),
          const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => controller.changePage(1),
          const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => controller.changePage(2),
          const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => controller.changePage(3),
          // macOS Cmd + 1..4
          const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () => controller.changePage(0),
          const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () => controller.changePage(1),
          const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () => controller.changePage(2),
          const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () => controller.changePage(3),
          // Ctrl / Cmd + , 打开设置
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () => DesktopSettingDialog.show(context),
          const SingleActivator(LogicalKeyboardKey.comma, meta: true): () => DesktopSettingDialog.show(context),
        },
        child: Focus(
          autofocus: true,
          child: content,
        ),
      );
    }

    return content;
  }
}
