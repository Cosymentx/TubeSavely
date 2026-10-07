import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// 屏幕尺寸分级枚举（使用 AppScreenType 避免与 GetX 内置 ScreenType 冲突）
enum AppScreenType {
  /// 紧凑型 (< 600px)：手机、折叠屏竖屏、小窗口
  compact,

  /// 中等型 (600px ~ 1024px)：平板、折叠屏大屏、分屏桌面窗口
  medium,

  /// 展开型 (>= 1024px)：标准桌面显示器、宽屏
  expanded,
}

/// 响应式多态值解析工具
class AdaptiveValue<T> {
  final T compact;
  final T? medium;
  final T? expanded;

  const AdaptiveValue({
    required this.compact,
    this.medium,
    this.expanded,
  });

  T resolve(BuildContext context) {
    final type = context.screenType;
    switch (type) {
      case AppScreenType.expanded:
        return expanded ?? medium ?? compact;
      case AppScreenType.medium:
        return medium ?? compact;
      case AppScreenType.compact:
        return compact;
    }
  }
}

/// 响应式构建器 Widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppScreenType screenType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final AppScreenType screenType;
        if (screenWidth >= AppSpacing.breakpointMedium) {
          screenType = AppScreenType.expanded;
        } else if (screenWidth >= AppSpacing.breakpointCompact) {
          screenType = AppScreenType.medium;
        } else {
          screenType = AppScreenType.compact;
        }

        return builder(context, screenType);
      },
    );
  }
}

/// 桌面端防拉伸内容容器：在宽屏时自动限制最大宽度并水平居中
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// BuildContext 响应式辅助扩展
extension ResponsiveContextExtension on BuildContext {
  /// 获取当前屏幕类型
  AppScreenType get screenType {
    final width = MediaQuery.of(this).size.width;
    if (width >= AppSpacing.breakpointMedium) {
      return AppScreenType.expanded;
    } else if (width >= AppSpacing.breakpointCompact) {
      return AppScreenType.medium;
    }
    return AppScreenType.compact;
  }

  /// 是否为手机/紧凑型屏幕
  bool get isCompact => screenType == AppScreenType.compact;

  /// 是否为平板/中等屏幕
  bool get isMedium => screenType == AppScreenType.medium;

  /// 是否为宽屏桌面
  bool get isExpanded => screenType == AppScreenType.expanded;

  /// 是否为桌面平台（macOS / Windows / Linux）
  bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// 屏幕宽度
  double get screenWidth => MediaQuery.of(this).size.width;

  /// 屏幕高度
  double get screenHeight => MediaQuery.of(this).size.height;
}
