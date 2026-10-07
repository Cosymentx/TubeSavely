import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/video_model.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../widgets/adaptive/responsive_layout.dart';
import '../../../widgets/empty_state.dart';
import '../controllers/history_controller.dart';

/// 现代化响应式历史记录视图（移动端 & 桌面端通用，移除 ScreenUtil 强依赖）
class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

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
                  _buildSearchBar(context),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: _buildHistoryList(context),
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

  // ==================== iOS 导航栏 ====================
  CupertinoNavigationBar _buildCupertinoNavBar(BuildContext context) {
    return CupertinoNavigationBar(
      middle: const Text('下载历史'),
      trailing: Obx(() {
        if (controller.isEditing.value) {
          final hasSelected = controller.selectedItems.isNotEmpty;
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
                onPressed: hasSelected ? controller.deleteSelected : null,
                child: Icon(
                  CupertinoIcons.delete,
                  size: 22,
                  color: hasSelected
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

  // ==================== Material / Desktop AppBar ====================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        '下载历史',
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

  // ==================== 搜索过滤栏 ====================
  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索历史记录中的标题或平台...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          fillColor: Colors.transparent,
          filled: false,
        ),
        style: const TextStyle(fontSize: 13.5),
        onChanged: controller.searchHistory,
      ),
    );
  }

  // ==================== 历史记录列表 ====================
  Widget _buildHistoryList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      }

      if (controller.historyList.isEmpty) {
        return Center(
          child: EmptyState(
            icon: Icons.history_rounded,
            title: '暂无下载历史',
            subtitle: '解析并完成下载的媒体记录会自动归档于此处',
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
        itemCount: controller.historyList.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final video = controller.historyList[index];
          return _buildHistoryItem(context, video);
        },
      );
    });
  }

  // ==================== 单个历史项卡片 ====================
  Widget _buildHistoryItem(BuildContext context, VideoModel video) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isSelected = controller.isSelected(video);
      final isEditing = controller.isEditing.value;

      return Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () {
            if (isEditing) {
              controller.toggleSelectItem(video);
            } else {
              controller.viewVideoDetail(video);
            }
          },
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 编辑多选勾选框
                if (isEditing) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm, top: 12),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                      size: 22,
                    ),
                  ),
                ],

                // 视频封面及播放时长角标
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 104,
                        height: 64,
                        child: video.thumbnail != null
                            ? CachedNetworkImage(
                                imageUrl: video.thumbnail!,
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
                                    Icons.movie_creation_outlined,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              )
                            : Container(
                                color: colorScheme.surfaceContainerLow,
                                child: Icon(
                                  Icons.movie_creation_outlined,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                      ),
                      // 时长标签
                      if (video.formattedDuration.isNotEmpty)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              video.formattedDuration,
                              style: AppTextStyles.dataSmall.copyWith(
                                color: Colors.white,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // 视频信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
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
                              video.platform ?? '网络视频',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (video.createdAt != null)
                            Text(
                              _formatDateTime(video.createdAt!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 快捷详情按钮（非编辑状态）
                if (!isEditing)
                  IconButton(
                    tooltip: '查看详情',
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                    ),
                    color: AppColors.textSecondary,
                    onPressed: () => controller.viewVideoDetail(video),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ==================== 相对时间格式化 ====================
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}年前';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}个月前';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // ==================== 浮动操作按钮 ====================
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
}
