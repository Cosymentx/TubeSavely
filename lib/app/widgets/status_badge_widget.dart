import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 下载状态枚举
enum DownloadStatus {
  downloading,  // 下载中
  completed,    // 已完成
  failed,       // 已失败
  paused,       // 已暂停
  waiting,      // 等待中
}

/// 状态徽章组件
/// 用于显示任务的当前状态
class StatusBadgeWidget extends StatelessWidget {
  final DownloadStatus status;
  final String label;
  final bool showBackground;
  final Color? customColor;

  const StatusBadgeWidget({
    Key? key,
    required this.status,
    required this.label,
    this.showBackground = true,
    this.customColor,
  }) : super(key: key);

  Color _getStatusColor() {
    if (customColor != null) return customColor!;
    
    switch (status) {
      case DownloadStatus.downloading:
        return AppColors.info;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.paused:
      case DownloadStatus.waiting:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case DownloadStatus.downloading:
        return Icons.download_rounded;
      case DownloadStatus.completed:
        return Icons.check_circle_rounded;
      case DownloadStatus.failed:
        return Icons.error_rounded;
      case DownloadStatus.paused:
        return Icons.pause_circle_rounded;
      case DownloadStatus.waiting:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final icon = _getStatusIcon();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: showBackground ? color.withOpacity(0.1) : Colors.transparent,
        border: Border.all(
          color: color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12.sp,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
