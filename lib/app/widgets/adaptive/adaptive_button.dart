import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/platform_util.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_animations.dart';

/// 按钮变体
enum ButtonVariant { primary, secondary, ghost, danger }

/// 按钮大小
enum ButtonSize { small, medium, large }

/// 自适应按钮 - 根据平台自动选择 Material 或 Cupertino 风格
/// 支持多种变体、大小、动画和状态
class AdaptiveButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final Color? color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? minWidth;
  final double? fontSize;
  final FontWeight? fontWeight;

  const AdaptiveButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.color,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.width,
    this.minWidth,
    this.fontSize,
    this.fontWeight,
  }) : super(key: key);

  @override
  State<AdaptiveButton> createState() => _AdaptiveButtonState();
}

class _AdaptiveButtonState extends State<AdaptiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.tapFeedbackDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  Color _getBackgroundColor() {
    if (!widget.isEnabled) return AppTheme.lightBorderColor;
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppTheme.primaryColor;
      case ButtonVariant.secondary:
        return AppTheme.lightCardBackground;
      case ButtonVariant.ghost:
        return Colors.transparent;
      case ButtonVariant.danger:
        return AppTheme.errorColor;
    }
  }

  Color _getTextColor() {
    if (!widget.isEnabled) return AppTheme.lightTextSecondaryColor;
    if (widget.color != null) return widget.color!;
    
    switch (widget.variant) {
      case ButtonVariant.primary:
      case ButtonVariant.danger:
        return Colors.white;
      case ButtonVariant.secondary:
      case ButtonVariant.ghost:
        return AppTheme.primaryColor;
    }
  }

  Color? _getBorderColor() {
    if (widget.variant == ButtonVariant.ghost) {
      return widget.isEnabled ? AppTheme.primaryColor : AppTheme.lightBorderColor;
    }
    return null;
  }

  double _getHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppSpacing.buttonHeightSm;
      case ButtonSize.medium:
        return AppSpacing.buttonHeightMd;
      case ButtonSize.large:
        return AppSpacing.buttonHeightLg;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppTextStyles.labelMedium;
      case ButtonSize.medium:
        return AppTextStyles.labelLarge;
      case ButtonSize.large:
        return AppTextStyles.titleMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return _buildCupertinoButton(context);
    } else {
      return _buildMaterialButton(context);
    }
  }

  /// 构建 Cupertino 风格按钮 (iOS)
  Widget _buildCupertinoButton(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: CupertinoButton(
          padding: widget.padding ??
              EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: (widget.size == ButtonSize.small ? 8 : 12).h,
              ),
          color: _getBackgroundColor(),
          onPressed: null,
          child: widget.isLoading
              ? const CupertinoActivityIndicator()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...<Widget>[
                      Icon(
                        widget.icon,
                        size: widget.fontSize ??
                            (widget.size == ButtonSize.small ? 14 : 16).sp,
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      widget.label,
                      style: (widget.fontSize != null
                              ? TextStyle(
                                  fontSize: widget.fontSize,
                                  fontWeight:
                                      widget.fontWeight ?? FontWeight.w500,
                                )
                              : _getTextStyle())
                          .copyWith(
                        color: _getTextColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 构建 Material 风格按钮 (Android)
  Widget _buildMaterialButton(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
        child: Container(
          width: widget.width,
          height: _getHeight(),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: _getBorderColor() != null
                ? Border.all(
                    color: _getBorderColor()!,
                    width: 1.5,
                  )
                : null,
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow:
                widget.variant == ButtonVariant.primary && widget.isEnabled
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getTextColor(),
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...<Widget>[
                      Icon(
                        widget.icon,
                        color: _getTextColor(),
                        size: AppSpacing.iconMd,
                      ),
                      SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: _getTextStyle().copyWith(
                        color: _getTextColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
