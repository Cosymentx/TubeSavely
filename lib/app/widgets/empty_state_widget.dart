import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'adaptive/adaptive_widgets.dart';

/// 空状态组件
/// 用于列表为空或没有数据时的占位符显示
class EmptyStateWidget extends StatelessWidget {
  /// 显示的图标
  final IconData icon;
  
  /// 主标题
  final String title;
  
  /// 副标题/描述文本
  final String? subtitle;
  
  /// 操作按钮标签
  final String? actionLabel;
  
  /// 操作按钮回调
  final VoidCallback? onAction;
  
  /// 图标大小
  final double iconSize;
  
  /// 图标颜色
  final Color? iconColor;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.onSurfaceVariant;
    
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize.sp,
                color: color,
              ),
              
              SizedBox(height: AppSpacing.lg),
              
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (subtitle != null) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: AppSpacing.xl),
                AdaptiveButton(
                  label: actionLabel!,
                  onPressed: onAction!,
                  size: ButtonSize.large,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
