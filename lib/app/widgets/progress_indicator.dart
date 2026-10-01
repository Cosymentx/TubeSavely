import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 进度指示器类型
enum ProgressType {
  /// 线性进度条
  linear,

  /// 圆形进度条
  circular,
}

/// 进度指示器组件
/// 用于显示下载或其他长时间操作的进度
/// 支持线性和圆形两种样式
///
/// 使用示例：
/// ```dart
/// // 线性进度条
/// CustomProgressIndicator(
///   progress: 0.65,
///   label: '65%',
///   showLabel: true,
/// )
///
/// // 圆形进度条
/// CustomProgressIndicator.circular(
///   progress: 0.75,
///   size: 60,
/// )
/// ```
class CustomProgressIndicator extends StatelessWidget {
  /// 进度值 (0.0 - 1.0)
  final double progress;

  /// 显示的标签文本（可选）
  final String? label;

  /// 是否显示标签
  final bool showLabel;

  /// 进度条颜色（可选，默认使用主题色）
  final Color? color;

  /// 背景色（可选）
  final Color? backgroundColor;

  /// 进度条高度（仅线性）
  final double height;

  /// 进度类型
  final ProgressType type;

  /// 圆形进度条大小（仅圆形）
  final double size;

  /// 圆形进度条宽度（仅圆形）
  final double strokeWidth;

  /// 线性进度指示器构造函数
  const CustomProgressIndicator({
    Key? key,
    required this.progress,
    this.label,
    this.showLabel = false,
    this.color,
    this.backgroundColor,
    this.height = 4.0,
    this.size = 0,
    this.strokeWidth = 0,
  })
      : type = ProgressType.linear,
        super(key: key);

  /// 圆形进度指示器命名构造函数
  const CustomProgressIndicator.circular({
    Key? key,
    required this.progress,
    this.label,
    this.showLabel = false,
    this.color,
    this.size = 60.0,
    this.strokeWidth = 3.0,
  })
      : type = ProgressType.circular,
        backgroundColor = null,
        height = 0,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ?? AppColors.border;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return type == ProgressType.linear
        ? _buildLinearProgress(barColor, bgColor, clampedProgress)
        : _buildCircularProgress(barColor, clampedProgress);
  }

  /// 构建线性进度条
  Widget _buildLinearProgress(
    Color barColor,
    Color bgColor,
    double clampedProgress,
  ) {
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
        if (showLabel && label != null) ...
          [
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

  /// 构建圆形进度条
  Widget _buildCircularProgress(
    Color barColor,
    double clampedProgress,
  ) {
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
