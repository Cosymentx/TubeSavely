import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 进度条组件
/// 用于显示下载或其他长时间操作的进度
class ProgressIndicatorWidget extends StatelessWidget {
  /// 进度值 (0.0 - 1.0)
  final double progress;
  
  /// 显示的标签文本
  final String? label;
  
  /// 是否显示标签
  final bool showLabel;
  
  /// 进度条颜色
  final Color? color;
  
  /// 背景色
  final Color? backgroundColor;
  
  /// 进度条高度
  final double height;

  const ProgressIndicatorWidget({
    Key? key,
    required this.progress,
    this.label,
    this.showLabel = false,
    this.color,
    this.backgroundColor,
    this.height = 4.0,
  }) : super(key: key);

  /// 圆形进度指示器命名构造函数
  factory ProgressIndicatorWidget.circular({
    Key? key,
    required double progress,
    String? label,
    bool showLabel = false,
    Color? color,
    double size = 60.0,
    double strokeWidth = 3.0,
  }) {
    return _CircularProgressIndicator(
      progress: progress,
      label: label,
      showLabel: showLabel,
      color: color,
      size: size,
      strokeWidth: strokeWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ?? AppColors.border;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: height,
            ),
          ),
        ),
        if (showLabel && label != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            label!,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// 圆形进度指示器
class _CircularProgressIndicator extends ProgressIndicatorWidget {
  final double size;
  final double strokeWidth;

  const _CircularProgressIndicator({
    Key? key,
    required double progress,
    String? label,
    bool showLabel = false,
    Color? color,
    required this.size,
    required this.strokeWidth,
  }) : super(
    key: key,
    progress: progress,
    label: label,
    showLabel: showLabel,
    color: color,
  );

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppColors.primary;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clampedProgress,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              backgroundColor: AppColors.border,
            ),
          ),
          if (showLabel && label != null)
            Text(
              label!,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
