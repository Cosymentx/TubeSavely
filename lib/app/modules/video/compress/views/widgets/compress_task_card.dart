import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/video_compress_model.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../utils/utils.dart';
import '../../controllers/compress_controller.dart';

/// 压缩任务卡片（移除 ScreenUtil 强依赖，采用高对比深色/浅色精密设计）
class CompressTaskCard extends GetView<CompressController> {
  final CompressTask task;

  const CompressTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCompressing = task.status == CompressTaskStatus.compressing;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isCompressing
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          width: isCompressing ? 1.5 : 1,
        ),
        boxShadow: isCompressing ? AppSpacing.shadowPrimaryGlow : AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：图标、文件名、元数据与状态胶囊
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.movie_creation_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.fileName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge('${task.width}x${task.height}'),
                        const SizedBox(width: 4),
                        if (task.durationSeconds > 0) ...[
                          _buildBadge(Utils.formatDuration(
                            Duration(seconds: task.durationSeconds.round()),
                          )),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '原始: ${Utils.formatFileSize(task.sourceSizeBytes)}',
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
              _buildStatusBadge(),
            ],
          ),

          // 压缩进度条与速度/剩余时间
          if (isCompressing) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              child: LinearProgressIndicator(
                value: task.progress,
                minHeight: 5,
                backgroundColor: colorScheme.surfaceContainerLow,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(task.progress * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.dataSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '速度: ${task.speed ?? "1.0x"}   剩余: ${task.eta ?? "计算中..."}',
                  style: AppTextStyles.dataSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // 完成信息：对比与节省百分比展示
          if (task.status == CompressTaskStatus.completed) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '压缩后: ${Utils.formatFileSize(task.targetSizeBytes ?? 0)}',
                    style: AppTextStyles.dataSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  if (task.savedRatio != null)
                    Text(
                      '已节省 ${task.savedRatio!.toStringAsFixed(1)}% (${Utils.formatFileSize(task.savedBytes)})',
                      style: AppTextStyles.dataSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // 底部操作按钮
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isCompressing)
                TextButton.icon(
                  onPressed: () => controller.cancelTask(task.id),
                  icon: const Icon(Icons.cancel_rounded, size: 16),
                  label: const Text('取消', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (task.status == CompressTaskStatus.completed) ...[
                TextButton.icon(
                  onPressed: () => controller.openFile(task.targetPath),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('播放', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => controller.openOutputFolder(),
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text('定位文件', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
              IconButton(
                tooltip: '移除记录',
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.textSecondary,
                onPressed: () => controller.removeTask(task.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (task.status) {
      case CompressTaskStatus.pending:
        color = const Color(0xFF3B82F6);
        text = '等待中';
        break;
      case CompressTaskStatus.analyzing:
        color = const Color(0xFFF59E0B);
        text = '分析中';
        break;
      case CompressTaskStatus.compressing:
        color = AppColors.primary;
        text = '压缩中';
        break;
      case CompressTaskStatus.completed:
        color = AppColors.success;
        text = '已完成';
        break;
      case CompressTaskStatus.failed:
        color = AppColors.error;
        text = '失败';
        break;
      case CompressTaskStatus.canceled:
        color = AppColors.textTertiary;
        text = '已取消';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
