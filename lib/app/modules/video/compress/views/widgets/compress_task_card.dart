import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../../data/models/video_compress_model.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../utils/utils.dart';
import '../../controllers/compress_controller.dart';

class CompressTaskCard extends GetView<CompressController> {
  final CompressTask task;

  const CompressTaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: task.status == CompressTaskStatus.compressing
              ? AppColors.primary
              : AppColors.primaryLight10,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight5,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：文件名与状态
          Row(
            children: [
              Icon(Icons.video_file, color: AppColors.primary, size: 28.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.fileName,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _buildBadge('${task.width}x${task.height}'),
                        SizedBox(width: 6.w),
                        if (task.durationSeconds > 0)
                          _buildBadge(Utils.formatDuration(Duration(seconds: task.durationSeconds.round()))),
                        SizedBox(width: 6.w),
                        Text(
                          '原始: ${Utils.formatFileSize(task.sourceSizeBytes)}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),

          // 进度条与实时指标
          if (task.status == CompressTaskStatus.compressing) ...[
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: task.progress,
                minHeight: 6.h,
                backgroundColor: AppColors.primaryLight10,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(task.progress * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  '速度: ${task.speed ?? "1.0x"}   剩余: ${task.eta ?? "计算中..."}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],

          // 完成信息：对比与节省百分比
          if (task.status == CompressTaskStatus.completed) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 6.w),
                  Text(
                    '压缩后: ${Utils.formatFileSize(task.targetSizeBytes ?? 0)}',
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                  const Spacer(),
                  if (task.savedRatio != null)
                    Text(
                      '已节省 ${task.savedRatio!.toStringAsFixed(1)}% (${Utils.formatFileSize(task.savedBytes)})',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                ],
              ),
            ),
          ],

          // 底部操作区
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (task.status == CompressTaskStatus.compressing)
                TextButton.icon(
                  onPressed: () => controller.cancelTask(task.id),
                  icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                  label: const Text('取消', style: TextStyle(color: Colors.red)),
                ),
              if (task.status == CompressTaskStatus.completed) ...[
                TextButton.icon(
                  onPressed: () => controller.openFile(task.targetPath),
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: const Text('播放'),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => controller.openOutputFolder(),
                  icon: const Icon(Icons.folder, size: 16),
                  label: const Text('定位文件'),
                ),
              ],
              TextButton.icon(
                onPressed: () => controller.removeTask(task.id),
                icon: Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                label: Text('移除', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.primaryLight10,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(text, style: TextStyle(fontSize: 10.sp, color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStatusBadge() {
    switch (task.status) {
      case CompressTaskStatus.pending:
        return Chip(
          label: const Text('等待中'),
          visualDensity: VisualDensity.compact,
        );
      case CompressTaskStatus.analyzing:
        return Chip(
          label: const Text('分析中'),
          visualDensity: VisualDensity.compact,
        );
      case CompressTaskStatus.compressing:
        return Chip(
          label: const Text('压缩中', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          visualDensity: VisualDensity.compact,
        );
      case CompressTaskStatus.completed:
        return Chip(
          label: const Text('已完成', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          visualDensity: VisualDensity.compact,
        );
      case CompressTaskStatus.failed:
        return Chip(
          label: const Text('失败', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          visualDensity: VisualDensity.compact,
        );
      case CompressTaskStatus.canceled:
        return Chip(
          label: const Text('已取消'),
          visualDensity: VisualDensity.compact,
        );
    }
  }
}
