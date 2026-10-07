import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/download_task_model.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/adaptive/adaptive_dialog.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../widgets/adaptive/responsive_layout.dart';
import '../../../widgets/empty_state.dart';
import '../controllers/tasks_controller.dart';

/// 现代化响应式下载任务视图（移动端 & 桌面端通用，移除 ScreenUtil 强依赖）
class TasksView extends GetView<TasksController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: _buildAppBar(context),
      cupertinoNavBar: _buildCupertinoNavBar(context),
      body: SafeArea(
        top: false,
        child: ResponsiveBuilder(
          builder: (context, screenType) {
            final isCompact = screenType == AppScreenType.compact;
            return ResponsiveContainer(
              maxWidth: 1000,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact
                    ? AppSpacing.pagePaddingHorizontal
                    : AppSpacing.desktopContentPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskStats(context),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: _buildTaskList(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // ==================== iOS 顶部导航栏 ====================
  CupertinoNavigationBar _buildCupertinoNavBar(BuildContext context) {
    return CupertinoNavigationBar(
      middle: const Text('下载任务'),
      trailing: Obx(() {
        if (controller.isEditing.value) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: controller.selectAll,
                child: const Icon(CupertinoIcons.checkmark_circle, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: controller.selectedItems.isNotEmpty
                    ? controller.deleteSelected
                    : null,
                child: Icon(
                  CupertinoIcons.delete,
                  size: 22,
                  color: controller.selectedItems.isNotEmpty
                      ? CupertinoColors.destructiveRed
                      : CupertinoColors.inactiveGray,
                ),
              ),
            ],
          );
        } else {
          return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: controller.toggleEditMode,
            child: const Icon(CupertinoIcons.pencil, size: 22),
          );
        }
      }),
    );
  }

  // ==================== Material / 桌面端 AppBar ====================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        '下载任务',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      actions: [
        Obx(() {
          if (controller.isEditing.value) {
            final selectedCount = controller.selectedItems.length;
            return Row(
              children: [
                TextButton(
                  onPressed: controller.selectAll,
                  child: const Text('全选'),
                ),
                IconButton(
                  tooltip: '删除选中 ($selectedCount)',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: selectedCount > 0 ? AppColors.error : AppColors.textTertiary,
                  onPressed: selectedCount > 0 ? controller.deleteSelected : null,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            );
          } else {
            return IconButton(
              tooltip: '批量管理',
              icon: const Icon(Icons.edit_note_rounded),
              onPressed: controller.toggleEditMode,
            );
          }
        }),
      ],
    );
  }

  // ==================== 顶部任务指标统计 ====================
  Widget _buildTaskStats(BuildContext context) {
    return Obx(() {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context: context,
              title: '下载中',
              count: controller.downloadingTasksCount,
              icon: Icons.arrow_downward_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              context: context,
              title: '已完成',
              count: controller.completedTasksCount,
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              context: context,
              title: '失败 / 暂停',
              count: controller.failedTasksCount,
              icon: Icons.error_outline_rounded,
              color: AppColors.error,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: AppTextStyles.dataLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 任务列表构建 ====================
  Widget _buildTaskList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      }

      if (controller.downloadTasks.isEmpty) {
        return Center(
          child: EmptyState(
            icon: Icons.download_done_rounded,
            title: '暂无下载任务',
            subtitle: '在首页粘贴音视频链接，即可在此处查看下载进度与文件',
            actionLabel: '前往解析下载',
            onAction: () => Get.offAllNamed(Routes.MAIN),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.only(
          top: AppSpacing.xs,
          bottom: AppSpacing.xxl,
        ),
        itemCount: controller.downloadTasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final task = controller.downloadTasks[index];
          return _buildTaskItem(context, task);
        },
      );
    });
  }

  // ==================== 单个任务卡片 ====================
  Widget _buildTaskItem(BuildContext context, DownloadTaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isSelected = controller.isSelected(task);
      final isEditing = controller.isEditing.value;

      return Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: isEditing ? () => controller.toggleSelectItem(task) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected ? AppSpacing.shadowPrimaryGlow : AppSpacing.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 编辑勾选指示器
                    if (isEditing) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm, top: 8),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                          size: 22,
                        ),
                      ),
                    ],

                    // 视频封面缩略图
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: SizedBox(
                        width: 90,
                        height: 56,
                        child: task.thumbnail != null
                            ? CachedNetworkImage(
                                imageUrl: task.thumbnail!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: colorScheme.surfaceContainerLow,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: colorScheme.surfaceContainerLow,
                                  child: Icon(
                                    Icons.video_library_rounded,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              )
                            : Container(
                                color: colorScheme.surfaceContainerLow,
                                child: Icon(
                                  Icons.video_library_rounded,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // 视频标题与信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStatusBadge(context, task.status),
                              const SizedBox(width: AppSpacing.sm),
                              if (task.platform != null) ...[
                                Text(
                                  task.platform!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              if (task.quality != null || task.format != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${task.quality ?? ""} ${task.format ?? ""}'.trim(),
                                    style: AppTextStyles.dataSmall.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 右侧快捷操作按钮（仅在非编辑模式展示）
                    if (!isEditing) _buildTaskActionButtons(context, task),
                  ],
                ),

                // 下载进度条与指标（仅在进行中或暂停状态展示）
                if (task.status == DownloadStatus.downloading ||
                    task.status == DownloadStatus.paused) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                    child: LinearProgressIndicator(
                      value: task.progress,
                      minHeight: 5,
                      backgroundColor: colorScheme.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.status == DownloadStatus.paused
                            ? const Color(0xFFF59E0B)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task.progressText,
                        style: AppTextStyles.dataSmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${task.formattedDownloadedBytes} / ${task.formattedTotalBytes}',
                        style: AppTextStyles.dataSmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  // ==================== 状态胶囊标签 ====================
  Widget _buildStatusBadge(BuildContext context, DownloadStatus status) {
    Color color;
    String text;

    switch (status) {
      case DownloadStatus.downloading:
        color = AppColors.primary;
        text = '下载中';
        break;
      case DownloadStatus.pending:
        color = const Color(0xFF3B82F6);
        text = '等待中';
        break;
      case DownloadStatus.paused:
        color = const Color(0xFFF59E0B);
        text = '已暂停';
        break;
      case DownloadStatus.completed:
        color = AppColors.success;
        text = '已完成';
        break;
      case DownloadStatus.failed:
        color = AppColors.error;
        text = '下载失败';
        break;
      case DownloadStatus.canceled:
        color = AppColors.textTertiary;
        text = '已取消';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==================== 任务快捷操作按钮 ====================
  Widget _buildTaskActionButtons(BuildContext context, DownloadTaskModel task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return IconButton(
          tooltip: '暂停',
          icon: const Icon(Icons.pause_circle_filled_rounded, size: 24),
          color: AppColors.primary,
          onPressed: () => controller.pauseTask(task.id),
        );
      case DownloadStatus.paused:
        return IconButton(
          tooltip: '继续下载',
          icon: const Icon(Icons.play_circle_fill_rounded, size: 24),
          color: AppColors.primary,
          onPressed: () => controller.resumeTask(task.id),
        );
      case DownloadStatus.pending:
        return IconButton(
          tooltip: '取消',
          icon: const Icon(Icons.cancel_rounded, size: 22),
          color: AppColors.warning,
          onPressed: () => controller.cancelTask(task.id),
        );
      case DownloadStatus.completed:
      case DownloadStatus.failed:
      case DownloadStatus.canceled:
        return IconButton(
          tooltip: '删除记录',
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: AppColors.textSecondary,
          onPressed: () => _showDeleteConfirmation(task),
        );
    }
  }

  // ==================== 编辑模式浮动按钮 ====================
  Widget? _buildFloatingActionButton(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditing.value;
      if (!isEditing) return const SizedBox.shrink();

      return FloatingActionButton.extended(
        onPressed: controller.toggleEditMode,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_rounded),
        label: const Text('完成管理'),
      );
    });
  }

  // ==================== 删除确认弹窗 ====================
  void _showDeleteConfirmation(DownloadTaskModel task) {
    Get.dialog(
      AdaptiveDialog(
        title: '删除任务',
        message: '确定要删除此下载任务吗？本地已缓存内容也将一并清理。',
        confirmButtonText: '删除',
        cancelButtonText: '取消',
        isDangerousAction: true,
        onConfirm: () => controller.deleteTask(task.id),
      ),
    );
  }
}
