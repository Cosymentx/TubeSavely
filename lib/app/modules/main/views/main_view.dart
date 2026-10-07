import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../widgets/adaptive/adaptive_shell.dart';
import '../../desktop/views/desktop_setting_dialog.dart';
import '../controllers/main_controller.dart';
import '../controllers/workspace_controller.dart';
import 'widgets/workspace_center_list.dart';
import 'widgets/workspace_inspector.dart';
import 'widgets/workspace_sidebar.dart';
import 'widgets/workspace_top_bar.dart';

/// 应用主入口视图 - Option A: 桌面一体化工作台 (Downie + Motrix) 与移动端极简传输中心双引擎架构
class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final workspaceController = Get.find<WorkspaceController>();
    final isDesktopPlatform = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 900;

        // 桌面大屏布局 (Downie + Motrix 一体化三栏工作台)
        if (isWideScreen) {
          Widget desktopWorkbench = Scaffold(
            body: Column(
              children: [
                // 1. 全局常驻顶部工具栏 (快速解析、实时全局网速、主题切换与设置)
                const WorkspaceTopBar(),

                // 2. 三栏一体化主体工作区
                Expanded(
                  child: Row(
                    children: [
                      // 左侧分类导航 (~220px)
                      const WorkspaceSidebar(),

                      // 中间主任务队列与工作流面板
                      const Expanded(
                        child: WorkspaceCenterList(),
                      ),

                      // 右侧任务检视器 (~330px，支持折叠展开)
                      Obx(() {
                        if (workspaceController.isInspectorOpen.value) {
                          return const WorkspaceInspector();
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );

          // 桌面平台键盘快捷键绑定
          if (isDesktopPlatform) {
            desktopWorkbench = CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                // 切换分类
                const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
                    workspaceController.setSection(WorkspaceSection.all),
                const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
                    workspaceController.setSection(WorkspaceSection.downloading),
                const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
                    workspaceController.setSection(WorkspaceSection.completed),
                const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
                    workspaceController.setSection(WorkspaceSection.convert),
                const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
                    workspaceController.setSection(WorkspaceSection.compress),

                const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () =>
                    workspaceController.setSection(WorkspaceSection.all),
                const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () =>
                    workspaceController.setSection(WorkspaceSection.downloading),
                const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () =>
                    workspaceController.setSection(WorkspaceSection.completed),
                const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () =>
                    workspaceController.setSection(WorkspaceSection.convert),
                const SingleActivator(LogicalKeyboardKey.digit5, meta: true): () =>
                    workspaceController.setSection(WorkspaceSection.compress),

                // 检视器开关 (Ctrl/Cmd + I)
                const SingleActivator(LogicalKeyboardKey.keyI, control: true):
                    workspaceController.toggleInspector,
                const SingleActivator(LogicalKeyboardKey.keyI, meta: true):
                    workspaceController.toggleInspector,

                // 视图模式切换 (Ctrl/Cmd + T)
                const SingleActivator(LogicalKeyboardKey.keyT, control: true):
                    workspaceController.toggleTableView,
                const SingleActivator(LogicalKeyboardKey.keyT, meta: true):
                    workspaceController.toggleTableView,

                // 打开偏好设置 (Ctrl/Cmd + ,)
                const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
                    DesktopSettingDialog.show(context),
                const SingleActivator(LogicalKeyboardKey.comma, meta: true): () =>
                    DesktopSettingDialog.show(context),
              },
              child: Focus(
                autofocus: true,
                child: desktopWorkbench,
              ),
            );
          }

          return desktopWorkbench;
        }

        // 移动端 / 紧凑窄屏布局 (AdaptiveShell 底部导航体验)
        return Obx(() {
          final currentIndex = controller.currentIndex.value;

          return AdaptiveShell(
            currentIndex: currentIndex,
            onDestinationSelected: controller.changePage,
            destinations: const [
              AdaptiveNavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '首页',
                tooltip: '视频下载与解析',
              ),
              AdaptiveNavigationDestination(
                icon: Icon(Icons.swap_vert_rounded),
                selectedIcon: Icon(Icons.swap_vert_circle_rounded),
                label: '传输',
                tooltip: '下载与已完成历史',
              ),
              AdaptiveNavigationDestination(
                icon: Icon(Icons.transform_outlined),
                selectedIcon: Icon(Icons.transform_rounded),
                label: '转换',
                tooltip: '格式转换工具',
              ),
              AdaptiveNavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: '我的',
                tooltip: '个人中心与设置',
              ),
            ],
            body: IndexedStack(
              index: currentIndex,
              children: controller.pages,
            ),
          );
        });
      },
    );
  }
}
