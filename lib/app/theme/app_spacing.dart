import 'package:flutter/material.dart';

/// 应用间距、断点与几何系统 (Layout & Spacing Tokens)
/// 遵循 8pt 基准网格与 UI/UX Pro Max 响应式自适应布局标准
class AppSpacing {
  AppSpacing._();

  // ==================== 响应式断点 (Responsive Breakpoints) ====================
  /// 紧凑型断点（手机、竖屏、小窗口）
  static const double breakpointCompact = 600.0;
  /// 中等断点（平板、折叠屏展开态、中等桌面窗口）
  static const double breakpointMedium = 1024.0;
  /// 宽屏断点（全屏桌面端、大显示器）
  static const double breakpointExpanded = 1440.0;

  // ==================== 桌面与移动端专属尺寸 (Shell Dimensions) ====================
  /// 桌面端侧边栏展开宽度
  static const double desktopSidebarWidth = 220.0;
  /// 桌面端紧凑图标导航宽度
  static const double desktopSidebarCollapsedWidth = 72.0;
  /// 桌面端顶部 Header 栏高度（含窗口控制区或工具栏）
  static const double desktopHeaderHeight = 52.0;
  /// 移动端沉浸式底部导航栏高度
  static const double mobileBottomBarHeight = 64.0;
  /// 桌面端内容区域最大阅读宽度（防止宽屏下排版失焦）
  static const double maxContentWidth = 1200.0;

  // ==================== 基础间距阶梯 (Spacing Scale - 8pt Grid) ====================
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // ==================== 页面内边距 (Page Paddings) ====================
  static const double pagePaddingHorizontal = 16.0;
  static const double pagePaddingVertical = 16.0;
  static const double pageMarginTop = 12.0;
  /// 桌面端主视窗舒适内边距
  static const double desktopContentPadding = 24.0;

  // ==================== 圆角系统 (Border Radius) ====================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2Xl = 28.0;
  static const double radiusRound = 999.0;

  // ==================== 图标与控件尺寸 (Component Sizes) ====================
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;

  // ==================== 细腻阴影系统 (Elevation & Shadows) ====================
  /// 微阴影（卡片轻微悬起）
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// 中等阴影（悬停、卡片）
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// 浮层阴影（弹窗、下拉菜单、浮动栏）
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// 品牌色微光阴影（用于高亮按钮或主要激活态）
  static const List<BoxShadow> shadowPrimaryGlow = [
    BoxShadow(
      color: Color(0x3DE11D48),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  // ==================== 动效时长 (Animation Durations) ====================
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Curve curveDefault = Curves.easeInOutCubic;
}
