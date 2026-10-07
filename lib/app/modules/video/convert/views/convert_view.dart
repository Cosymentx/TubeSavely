import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/video_converter_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../../widgets/adaptive/responsive_layout.dart';
import '../controllers/convert_controller.dart';

/// 现代化响应式视频格式转换视图（移动端 & 桌面端通用，移除 ScreenUtil 强依赖）
class ConvertView extends GetView<ConvertController> {
  const ConvertView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(
          '视频格式转换',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            onPressed: controller.openOutputFolder,
            tooltip: '打开输出目录',
          ),
        ],
      ),
      cupertinoNavBar: CupertinoNavigationBar(
        middle: const Text('视频格式转换'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: controller.openOutputFolder,
          child: const Icon(CupertinoIcons.folder, size: 22),
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
              child: isCompact
                  ? _buildMobileLayout(context)
                  : _buildDesktopLayout(context),
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // ==================== 移动端流式布局 ====================
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(context),
          const SizedBox(height: AppSpacing.lg),
          _buildFileSelectorCard(context),
          const SizedBox(height: AppSpacing.lg),
          _buildTaskListSection(context),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ==================== 桌面端双列布局 ====================
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左列：转码预设与待处理文件列表 (40%)
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingsCard(context),
                const SizedBox(height: AppSpacing.lg),
                _buildFileSelectorCard(context),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),

        // 右列：实时任务队列与进度监视 (60%)
        Expanded(
          flex: 6,
          child: _buildTaskListSection(context),
        ),
      ],
    );
  }

  // ==================== 1. 转换参数设置卡片 ====================
  Widget _buildSettingsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '转码输出预设',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 目标格式胶囊
          Text(
            '目标格式',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Obx(() {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: controller.availableFormats.map((format) {
                final isSelected = controller.selectedFormat.value == format;
                return ChoiceChip(
                  label: Text(format.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  onSelected: (selected) {
                    if (selected) controller.setFormat(format);
                  },
                );
              }).toList(),
            );
          }),
          const SizedBox(height: AppSpacing.md),

          // 目标分辨率胶囊
          Text(
            '目标分辨率',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Obx(() {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: controller.availableResolutions.map((resolution) {
                final isSelected =
                    controller.selectedResolution.value == resolution;
                return ChoiceChip(
                  label: Text(resolution),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  onSelected: (selected) {
                    if (selected) controller.setResolution(resolution);
                  },
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ==================== 2. 待转换文件选择卡片 ====================
  Widget _buildFileSelectorCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '待处理文件',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('添加视频', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: controller.pickVideoFiles,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Obx(() {
            if (controller.selectedFiles.isEmpty) {
              return InkWell(
                onTap: controller.pickVideoFiles,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 36,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '点击导入本地视频文件',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '支持 MP4 / MKV / MOV / AVI 等主流格式',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.selectedFiles.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final file = controller.selectedFiles[index];
                      final fileName = file.path.split(Platform.pathSeparator).last;

                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.movie_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          file.path,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          tooltip: '移除',
                          onPressed: () => controller.removeFile(file),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text('转换全部 (${controller.selectedFiles.length}个文件)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    onPressed: controller.convertAllVideos,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ==================== 3. 任务队列与进度卡片 ====================
  Widget _buildTaskListSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.playlist_play_rounded,
                  color: AppColors.info,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '转码任务队列',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Obx(() {
            if (controller.conversionTasks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 40,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '暂无正在进行的转换任务',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.conversionTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final task = controller.conversionTasks[index];
                return _buildTaskCard(context, task);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, ConversionTask task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fileName = task.sourceFilePath.split(Platform.pathSeparator).last;
    final statusColor = _getStatusColor(task.status);
    final statusText = _getStatusText(task.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101724) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '目标: ${task.format.toUpperCase()} • ${task.resolution}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // 进度条（转码中展示）
          if (task.status == ConversionStatus.converting ||
              task.status == ConversionStatus.pending) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              child: LinearProgressIndicator(
                value: task.progress,
                minHeight: 4,
                backgroundColor: colorScheme.surfaceContainerLow,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.statusMessage ?? (task.status == ConversionStatus.pending ? '排队中...' : '转码加速中...'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${(task.progress * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.dataSmall.copyWith(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          // 操作按钮组
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (task.status == ConversionStatus.completed) ...[
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('播放', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => controller.openFile(task.targetFilePath),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text('定位', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => controller.openFileLocation(task.targetFilePath),
                ),
              ],
              if (task.status == ConversionStatus.pending ||
                  task.status == ConversionStatus.converting)
                TextButton.icon(
                  icon: const Icon(Icons.cancel_rounded, size: 16),
                  label: const Text('取消', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => controller.cancelTask(task.id),
                ),
              if (task.status == ConversionStatus.failed)
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('重试', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => controller.retryTask(task),
                ),
              IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.textSecondary,
                onPressed: () => controller.deleteTask(task.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  FloatingActionButton? _buildFloatingActionButton(BuildContext context) {
    return null;
  }

  Color _getStatusColor(ConversionStatus status) {
    switch (status) {
      case ConversionStatus.pending:
        return AppColors.warning;
      case ConversionStatus.converting:
        return AppColors.primary;
      case ConversionStatus.completed:
        return AppColors.success;
      case ConversionStatus.failed:
        return AppColors.error;
      case ConversionStatus.canceled:
        return AppColors.textTertiary;
    }
  }

  String _getStatusText(ConversionStatus status) {
    switch (status) {
      case ConversionStatus.pending:
        return '排队中';
      case ConversionStatus.converting:
        return '转换中';
      case ConversionStatus.completed:
        return '已完成';
      case ConversionStatus.failed:
        return '失败';
      case ConversionStatus.canceled:
        return '已取消';
    }
  }
}
