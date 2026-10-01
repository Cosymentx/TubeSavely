import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// 平台检测和适配工具类
class PlatformUtil {
  PlatformUtil._();

  // ======================== 平台检测 ========================
  
  /// 是否为iOS平台
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  
  /// 是否为Android平台
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  
  /// 是否为Web平台
  static bool get isWeb => kIsWeb;
  
  /// 是否为桌面平台（macOS/Windows/Linux）
  static bool get isDesktop => 
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  // ======================== 设备类型检测 ========================
  
  /// 是否为手机设备（宽度 < 600）
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
  
  /// 是否为平板设备（宽度 >= 600）
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }
  
  /// 获取屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// 获取屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // ======================== iOS特定检测 ========================
  
  /// 是否有刘海（iPhone X及以后的机型）
  static bool hasNotch(BuildContext context) {
    return MediaQuery.of(context).viewPadding.top > 44;
  }
  
  /// 是否有动态岛（iPhone 14 Pro及以后）
  /// 动态岛的viewPadding.top通常 > 48
  static bool hasDynamicIsland(BuildContext context) {
    return MediaQuery.of(context).viewPadding.top > 48;
  }
  
  /// 是否为iPhone（物理检测）
  static bool get isPhysicallyIPhone {
    if (!isIOS) return false;
    try {
      return Platform.isIOS;
    } catch (e) {
      return false;
    }
  }
  
  /// 是否为iPad
  static bool get isPhysicallyIPad {
    if (!isIOS) return false;
    // iPad的userAgent中包含"iPad"字符
    // 或者通过MediaQuery检测：iPad的defaultLocale为null
    return false; // 在实际应用中需要额外逻辑检测
  }
  
  /// 获取顶部安全区高度
  static double getTopSafeArea(BuildContext context) {
    return MediaQuery.of(context).viewPadding.top;
  }
  
  /// 获取底部安全区高度
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).viewPadding.bottom;
  }

  // ======================== 屏幕方向 ========================
  
  /// 是否为横屏
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// 是否为竖屏
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // ======================== 主题检测 ========================
  
  /// 是否为暗色模式
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
  
  /// 是否为浅色模式
  static bool isLightMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.light;
  }

  // ======================== iOS系统版本 ========================
  
  /// 获取iOS系统版本（仅iOS）
  static Future<String> getIOSVersion() async {
    if (!isIOS) return 'N/A';
    try {
      // 需要通过platform channel获取实际版本
      // 这里仅作示意
      return 'iOS ${Platform.operatingSystemVersion}';
    } catch (e) {
      return 'Unknown';
    }
  }

  // ======================== 响应式布局辅助 ========================
  
  /// 获取响应式宽度
  /// - 手机：100%
  /// - 平板：70% 或 自定义比例
  static double getResponsiveWidth(BuildContext context, {double tabletRatio = 0.7}) {
    final screenWidth = getScreenWidth(context);
    if (isPhone(context)) {
      return screenWidth;
    } else {
      return screenWidth * tabletRatio;
    }
  }
  
  /// 获取响应式内边距
  /// - 手机：16pt
  /// - 平板：24pt
  static double getResponsivePadding(BuildContext context) {
    return isPhone(context) ? 16 : 24;
  }
  
  /// 获取响应式网格列数
  /// - 手机竖屏：2列
  /// - 手机横屏：3列
  /// - 平板竖屏：3列
  /// - 平板横屏：4列
  static int getGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    final isLand = isLandscape(context);
    
    if (width < 600) {
      // 手机
      return isLand ? 3 : 2;
    } else {
      // 平板
      return isLand ? 4 : 3;
    }
  }

  // ======================== 调试信息 ========================
  
  /// 获取完整的平台信息（用于调试）
  static String getPlatformInfo(BuildContext context) {
    return '''
Platform: ${_getPlatformName()}
Device Type: ${isPhone(context) ? 'Phone' : 'Tablet'}
Screen: ${getScreenWidth(context).toStringAsFixed(0)} x ${getScreenHeight(context).toStringAsFixed(0)}
Orientation: ${isPortrait(context) ? 'Portrait' : 'Landscape'}
Theme: ${isDarkMode(context) ? 'Dark' : 'Light'}
Top Safe Area: ${getTopSafeArea(context).toStringAsFixed(0)}
Bottom Safe Area: ${getBottomSafeArea(context).toStringAsFixed(0)}
Has Notch: ${hasNotch(context)}
Has Dynamic Island: ${hasDynamicIsland(context)}
    '''.trim();
  }

  /// 获取平台名称
  static String _getPlatformName() {
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    if (isWeb) return 'Web';
    return 'Unknown';
  }
}
