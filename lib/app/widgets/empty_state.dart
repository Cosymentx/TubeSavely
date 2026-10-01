import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'adaptive/adaptive_widgets.dart';

/// 空状态组件
/// 用于列表为空或没有数据时的占位符显示
/// 支持自定义图标、标题、描述和操作按钮
///
/// 使用示例：
/// ```dart
/// EmptyState(
///   icon: Icons.download_done,
///   title: '暂无下载任务',
///   subtitle: '解析视频后将显示下载任务',
///   actionLabel: '返回首页',
///   onAction: () => Get.toNamed('/home'),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// 显示的图标
  final IconData icon;

  /// 主标题
  final String title;

  /// 副标题/描述文本（可选）
  final String? subtitle;

  /// 操作按钮标签（可选）
  final String? actionLabel;

  /// 操作按钮回调（可选）
  final VoidCallback? onAction;

  /// 图标大小（默认64）
  final double iconSize;

  /// 图标颜色（可选，默认使用主题色）
  final Color? iconColor;

  /// 自定义内容widget（可选，如提供则忽略标题和描述）
  final Widget? customContent;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
    this.customContent,
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
              // 图标
              Icon(
                icon,
                size: iconSize.sp,
                color: color,
              ),

              SizedBox(height: AppSpacing.lg),

              // 内容区域
              if (customContent != null)
                customContent!
              else
                Column(
                  children: [
                    // 标题
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // 副标题
                    if (subtitle != null) ...
                      [
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                  ],
                ),

              // 操作按钮
              if (actionLabel != null && onAction != null) ...
                [
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
