import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 下载状态枚举
enum DownloadStatus {
  /// 下载中
  downloading,

  /// 已完成
  completed,

  /// 已失败
  failed,

  /// 已暂停
  paused,

  /// 等待中
  waiting,
}

/// 状态徽章组件
/// 用于显示任务的当前状态，支持亮/暗模式自适配
///
/// 使用示例：
/// ```dart
/// StatusBadge(
///   status: DownloadStatus.downloading,
///   label: '下载中',
/// )
/// ```
class StatusBadge extends StatelessWidget {
  /// 任务状态
  final DownloadStatus status;

  /// 状态标签文本
  final String label;

  /// 是否显示背景色（默认true）
  final bool showBackground;

  /// 自定义颜色（可选）
  final Color? customColor;

  const StatusBadge({
    Key? key,
    required this.status,
    required this.label,
    this.showBackground = true,
    this.customColor,
  }) : super(key: key);

  /// 根据状态获取对应的颜色
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
        return AppColors.warning;
      case DownloadStatus.waiting:
        return AppColors.warning;
    }
  }

  /// 获取状态对应的图标
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
        // 背景色：状态色 + 10% 不透明度
        color: showBackground ? color.withOpacity(0.1) : Colors.transparent,
        // 边框：状态色 1px
        border: Border.all(
          color: color,
          width: 1,
        ),
        // 圆角
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
