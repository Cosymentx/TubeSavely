import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/theme_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../desktop/views/desktop_setting_dialog.dart';
import '../../controllers/workspace_controller.dart';

/// 桌面工作台顶部常驻工具栏 (Downie + Motrix 风格)
class WorkspaceTopBar extends StatelessWidget {
  const WorkspaceTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkspaceController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧：品牌标识与 Workbench 徽章
          _buildBrand(context, isDark),
          const SizedBox(width: AppSpacing.lg),

          // 中间：常驻全局极速解析输入栏 (支持 Ctrl+V 粘贴即解析)
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: _buildQuickParseBar(context, controller, isDark),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // 右侧：实时网速指示器 + 工具按钮群
          _buildTrailingActions(context, controller, isDark),
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text(
          'TubeSavely',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'WORKBENCH',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickParseBar(BuildContext context, WorkspaceController controller, bool isDark) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.link_rounded,
            size: 18,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller.globalUrlController,
              onSubmitted: (_) => controller.triggerGlobalParse(),
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: '粘贴视频/图文链接，按回车快速解析下载...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // 粘贴快捷动作
          Tooltip(
            message: '从剪贴板粘贴并解析',
            child: InkWell(
              onTap: controller.pasteFromClipboard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.content_paste_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '粘贴',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 解析触发主按钮
          Obx(() {
            final isLoading = controller.isGlobalParsing.value;
            return Container(
              height: 30,
              margin: const EdgeInsets.only(right: 4),
              child: ElevatedButton(
                onPressed: isLoading ? null : controller.triggerGlobalParse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '解析',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrailingActions(
      BuildContext context, WorkspaceController controller, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 实时下载速率徽章 (Tabular 数字防止抖动)
        Obx(() {
          final speed = controller.globalSpeedMBs;
          final isDownloading = controller.downloadingCount > 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDownloading
                  ? AppColors.success.withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              border: Border.all(
                color: isDownloading
                    ? AppColors.success.withValues(alpha: 0.3)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDownloading ? Icons.arrow_downward_rounded : Icons.sensors_off_rounded,
                  size: 13,
                  color: isDownloading ? AppColors.success : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 4),
                Text(
                  isDownloading ? '${speed.toStringAsFixed(1)} MB/s' : '就绪',
                  style: AppTextStyles.dataSmall.copyWith(
                    color: isDownloading ? AppColors.success : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(width: AppSpacing.sm),

        // 主题切换按钮
        IconButton(
          tooltip: '切换颜色主题',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 18,
          ),
          onPressed: () => ThemeService.to.switchTheme(),
          visualDensity: VisualDensity.compact,
        ),

        // 设置入口按钮
        IconButton(
          tooltip: '系统与工作台偏好设置 (Ctrl+,)',
          icon: const Icon(Icons.tune_rounded, size: 18),
          onPressed: () => DesktopSettingDialog.show(context),
          visualDensity: VisualDensity.compact,
        ),

        // 检视器开关控制按钮
        Obx(() {
          final isOpen = controller.isInspectorOpen.value;
          return IconButton(
            tooltip: isOpen ? '收起右侧检视器' : '展开右侧检视器',
            icon: Icon(
              isOpen ? Icons.view_sidebar_rounded : Icons.view_sidebar_outlined,
              size: 18,
              color: isOpen ? AppColors.primary : null,
            ),
            onPressed: controller.toggleInspector,
            visualDensity: VisualDensity.compact,
          );
        }),
      ],
    );
  }
}
