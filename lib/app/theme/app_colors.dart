import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 应用语义化设计色彩系统 (Design Tokens)
/// 遵循 UI/UX Pro Max 规范：Modern Precision Slate 风格
/// 兼具 Material 3 色彩层级与暗黑模式高对比度要求
class AppColors {
  AppColors._();

  // ==================== 核心品牌色 (Brand Colors) ====================
  /// 现代高精品牌红 (Crimson Flare) - 相比纯红更具质感与呼吸感
  static const Color primary = Color(0xFFE11D48);
  static const Color primaryLight = Color(0xFFFB7185);
  static const Color primaryDark = Color(0xFFBE123C);
  static const Color primaryLegacy = Color(0xFFFF0014);

  // 强调色 (Accent)
  static const Color accent = Color(0xFFF43F5E);
  static const Color accentLight = Color(0xFFFDA4AF);
  static const Color accentDark = Color(0xFF9F1239);

  // 容器色 (Containers)
  static const Color lightPrimaryContainer = Color(0xFFFFE4E6);
  static const Color lightOnPrimaryContainer = Color(0xFF881337);
  static const Color darkPrimaryContainer = Color(0xFF4C0519);
  static const Color darkOnPrimaryContainer = Color(0xFFFECDD3);

  // ==================== 状态色 (Semantic Status) ====================
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF047857);

  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444);   // Rose / Red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF0EA5E9);    // Sky Blue
  static const Color infoLight = Color(0xFFE0F2FE);
  static const Color infoDark = Color(0xFF0369A1);

  // 阴影与微光
  static const Color shadow = Color(0x1A000000);
  static const Color darkShadow = Color(0x40000000);
  static const Color primaryGlow = Color(0x33E11D48);

  // 品牌色透明度变体
  static const Color primaryLight5 = Color(0x0DE11D48);   // 5%
  static const Color primaryLight10 = Color(0x1AE11D48);  // 10%
  static const Color primaryLight20 = Color(0x33E11D48);  // 20%
  static const Color primaryLight25 = Color(0x40E11D48);  // 25%

  // ==================== 浅色表面层级 (Light Surfaces) ====================
  static const Color _lightBackground = Color(0xFFF8FAFC);         // Slate-50 基底
  static const Color _lightSurface = Color(0xFFFFFFFF);            // 纯白主卡片
  static const Color _lightSurfaceContainerLow = Color(0xFFF1F5F9); // Slate-100 次级区域
  static const Color _lightSurfaceVariant = Color(0xFFF1F5F9);     // 兼容原属性
  static const Color _lightSurfaceContainer = Color(0xFFE2E8F0);    // Slate-200 边框/输入框衬底
  static const Color _lightSurfaceContainerHigh = Color(0xFFCBD5E1);

  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightOnBackground = Color(0xFF0F172A);
  static const Color _lightOnSurface = Color(0xFF1E293B);
  static const Color _lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color _lightTextPrimary = Color(0xFF0F172A);        // Slate-900
  static const Color _lightTextSecondary = Color(0xFF64748B);      // Slate-500
  static const Color _lightTextTertiary = Color(0xFF94A3B8);       // Slate-400
  static const Color _lightBorder = Color(0xFFE2E8F0);             // Slate-200
  static const Color _lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color _lightDivider = Color(0xFFE2E8F0);

  // ==================== 深色表面层级 (Dark Surfaces) ====================
  // 采用深黑岩系（Deep Void Slate）代替原灰，彻底告别沉闷浑浊感
  static const Color _darkBackground = Color(0xFF0B0F19);          // 深邃太空灰底
  static const Color _darkSurface = Color(0xFF151D2C);             // 主卡片表面
  static const Color _darkSurfaceContainerLow = Color(0xFF101724); // 凹陷次级区域
  static const Color _darkSurfaceVariant = Color(0xFF1E293B);      // 兼容原属性
  static const Color _darkSurfaceContainer = Color(0xFF1E293B);    // 浮动卡片/控件
  static const Color _darkSurfaceContainerHigh = Color(0xFF273549);

  static const Color _darkOnPrimary = Color(0xFFFFFFFF);
  static const Color _darkOnBackground = Color(0xFFF8FAFC);
  static const Color _darkOnSurface = Color(0xFFE2E8F0);
  static const Color _darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color _darkTextPrimary = Color(0xFFF8FAFC);         // Slate-50
  static const Color _darkTextSecondary = Color(0xFF94A3B8);       // Slate-400
  static const Color _darkTextTertiary = Color(0xFF64748B);        // Slate-500
  static const Color _darkBorder = Color(0xFF1E293B);              // Slate-800
  static const Color _darkBorderSubtle = Color(0xFF162032);
  static const Color _darkDivider = Color(0xFF1E293B);

  // ==================== 渐变 (Gradients) ====================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
  );

  static const LinearGradient heroGlowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x22E11D48), Colors.transparent],
  );

  // ==================== 动态主题色彩获取 (Getters) ====================
  static Color get background =>
      Get.isDarkMode ? _darkBackground : _lightBackground;
  static Color get surface => Get.isDarkMode ? _darkSurface : _lightSurface;
  static Color get surfaceContainerLow =>
      Get.isDarkMode ? _darkSurfaceContainerLow : _lightSurfaceContainerLow;
  static Color get surfaceContainer =>
      Get.isDarkMode ? _darkSurfaceContainer : _lightSurfaceContainer;
  static Color get surfaceContainerHigh =>
      Get.isDarkMode ? _darkSurfaceContainerHigh : _lightSurfaceContainerHigh;
  static Color get surfaceVariant =>
      Get.isDarkMode ? _darkSurfaceVariant : _lightSurfaceVariant;

  static Color get primaryContainer =>
      Get.isDarkMode ? darkPrimaryContainer : lightPrimaryContainer;
  static Color get onPrimaryContainer =>
      Get.isDarkMode ? darkOnPrimaryContainer : lightOnPrimaryContainer;

  static Color get onPrimary =>
      Get.isDarkMode ? _darkOnPrimary : _lightOnPrimary;
  static Color get onBackground =>
      Get.isDarkMode ? _darkOnBackground : _lightOnBackground;
  static Color get onSurface =>
      Get.isDarkMode ? _darkOnSurface : _lightOnSurface;
  static Color get onSurfaceVariant =>
      Get.isDarkMode ? _darkOnSurfaceVariant : _lightOnSurfaceVariant;

  static Color get textPrimary =>
      Get.isDarkMode ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary =>
      Get.isDarkMode ? _darkTextSecondary : _lightTextSecondary;
  static Color get textTertiary =>
      Get.isDarkMode ? _darkTextTertiary : _lightTextTertiary;

  static Color get border => Get.isDarkMode ? _darkBorder : _lightBorder;
  static Color get borderSubtle =>
      Get.isDarkMode ? _darkBorderSubtle : _lightBorderSubtle;
  static Color get divider => Get.isDarkMode ? _darkDivider : _lightDivider;
}

/// BuildContext 快捷扩展，优先从本地 Theme 读取（性能与自适应度优于 Get.isDarkMode）
extension BuildContextAppColorsExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  Color get appPrimary => colorScheme.primary;
  Color get appBackground => colorScheme.surface;
  Color get appSurface => colorScheme.surface;
  Color get appTextPrimary =>
      isDarkMode ? AppColors._darkTextPrimary : AppColors._lightTextPrimary;
  Color get appTextSecondary =>
      isDarkMode ? AppColors._darkTextSecondary : AppColors._lightTextSecondary;
  Color get appBorder =>
      isDarkMode ? AppColors._darkBorder : AppColors._lightBorder;
}
