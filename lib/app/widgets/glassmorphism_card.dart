import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../utils/platform_util.dart';

/// iOS 18毛玻璃效果卡片
/// 仅在iOS平台显示毛玻璃效果，Android降级为普通Card
class GlassmorphismCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;
  
  /// 内边距
  final EdgeInsets padding;
  
  /// 模糊强度（0-20）
  final double blurStrength;
  
  /// 背景色透明度（0-1）
  final double opacity;
  
  /// 圆角半径
  final double borderRadius;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 是否显示边框
  final bool showBorder;
  
  const GlassmorphismCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blurStrength = 10,
    this.opacity = 0.7,
    this.borderRadius = 12,
    this.onTap,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return _buildIOSGlassmorphism(context);
    } else {
      return _buildAndroidCard(context);
    }
  }

  /// iOS毛玻璃效果实现
  Widget _buildIOSGlassmorphism(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: blurStrength,
          sigmaY: blurStrength,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: CupertinoColors.systemGrey5.withOpacity(0.3),
                    width: 0.5,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Android普通卡片降级方案
  Widget _buildAndroidCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// 毛玻璃容器 - 更轻量级
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double blurStrength;
  final double opacity;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const GlassmorphismContainer({
    Key? key,
    required this.child,
    this.blurStrength = 10,
    this.opacity = 0.7,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurStrength,
            sigmaY: blurStrength,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (backgroundColor ?? CupertinoColors.systemBackground)
                  .withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: CupertinoColors.systemGrey5.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      );
    } else {
      // Android降级
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      );
    }
  }
}

/// 毛玻璃浮动按钮容器
class GlassmorphismFAB extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final EdgeInsets padding;

  const GlassmorphismFAB({
    Key? key,
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsets.all(12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return GestureDetector(
        onTap: onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CupertinoColors.systemGrey5.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    } else {
      // Android使用标准FAB
      return FloatingActionButton(
        onPressed: onPressed,
        child: child,
      );
    }
  }
}

/// 毛玻璃底部工作表背景
class GlassmorphismBottomSheet extends StatelessWidget {
  final Widget child;
  final double height;
  final bool showDragHandle;

  const GlassmorphismBottomSheet({
    Key? key,
    required this.child,
    this.height = 400,
    this.showDragHandle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            if (showDragHandle) ...[
              SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 8),
            ],
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Android降级
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            if (showDragHandle) ...[
              SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 8),
            ],
            Expanded(child: child),
          ],
        ),
      );
    }
  }
}

/// 毛玻璃导航栏背景
class GlassmorphismAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onLeadingPressed;
  final double elevation;

  const GlassmorphismAppBar({
    Key? key,
    required this.title,
    this.leading,
    this.actions,
    this.onLeadingPressed,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.systemGrey5.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Leading
                    leading ??
                        GestureDetector(
                          onTap: onLeadingPressed ?? () => Navigator.pop(context),
                          child: Icon(
                            CupertinoIcons.back,
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                    // Title
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Actions
                    if (actions != null)
                      Row(
                        children: actions!,
                      )
                    else
                      SizedBox(width: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Android使用标准AppBar
      return AppBar(
        title: Text(title),
        leading: leading,
        actions: actions,
        elevation: elevation,
      );
    }
  }
}

/// 毛玻璃徽章（用于显示数字、状态等）
class GlassmorphismBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;

  const GlassmorphismBadge({
    Key? key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (backgroundColor ?? CupertinoColors.systemBlue)
                  .withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGrey5.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else {
      // Android降级
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}
