import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../../widgets/adaptive/responsive_layout.dart';
import '../controllers/compress_controller.dart';
import 'widgets/compress_settings_panel.dart';
import 'widgets/compress_task_card.dart';

/// 现代化响应式视频压缩视图（移动端 & 桌面端通用，移除 ScreenUtil 强依赖）
class CompressView extends GetView<CompressController> {
  const CompressView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(
          '智能视频压缩',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: '打开输出目录',
            onPressed: controller.openOutputFolder,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: '清空已完成',
            onPressed: controller.clearCompleted,
          ),
        ],
      ),
      cupertinoNavBar: CupertinoNavigationBar(
        middle: const Text('智能视频压缩'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: controller.openOutputFolder,
              child: const Icon(CupertinoIcons.folder, size: 22),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveBuilder(
          builder: (context, screenType) {
            final isCompact = screenType == AppScreenType.compact;
            return ResponsiveContainer(
              maxWidth: 1100,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact
                    ? AppSpacing.pagePaddingHorizontal
                    : AppSpacing.desktopContentPadding,
                vertical: AppSpacing.md,
              ),
              child: isCompact ? _buildMobileLayout() : _buildDesktopLayout(),
            );
          },
        ),
      ),
    );
  }

  /// PC 桌面端宽屏双栏布局
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：压缩参数设置面板 (380px)
        const SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: CompressSettingsPanel(),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),

        // 右侧：导入区、任务队列、实时统计
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderActionBar(),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildTaskList()),
            ],
          ),
        ),
      ],
    );
  }

  /// 移动端单栏滚动布局
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderActionBar(),
          const SizedBox(height: AppSpacing.md),
          const CompressSettingsPanel(),
          const SizedBox(height: AppSpacing.lg),
          Text('任务队列', style: Get.theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          _buildTaskList(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// 顶部操作卡片与添加视频入口
  Widget _buildHeaderActionBar() {
    final theme = Get.theme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.pickVideos,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('添加视频文件 (支持批量多选)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Obx(() {
            return Row(
              children: [
                _buildStatPill('队列', '${controller.tasks.length}'),
                const SizedBox(width: AppSpacing.xs),
                _buildStatPill('已完成', '${controller.completedCount}'),
                if (controller.totalSavedMB > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _buildStatPill(
                    '已节省',
                    '${controller.totalSavedMB.toStringAsFixed(1)} MB',
                    isHighlight: true,
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 任务列表
  Widget _buildTaskList() {
    return Obx(() {
      if (controller.tasks.isEmpty) {
        return _buildEmptyState();
      }

      final isMobile = Get.context != null && MediaQuery.of(Get.context!).size.width < 850;

      return ListView.separated(
        shrinkWrap: isMobile,
        physics: isMobile
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        itemCount: controller.tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final task = controller.tasks[index];
          return CompressTaskCard(task: task);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    final theme = Get.theme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_collection_outlined,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '暂无待压缩视频',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '点击上方按钮导入视频文件，支持高效批量瘦身',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
