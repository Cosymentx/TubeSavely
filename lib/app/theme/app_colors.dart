import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 应用颜色定义
/// 根据当前主题自动切换颜色
class AppColors {
  AppColors._();

  // 主色调 - 这些颜色在深色和浅色主题中保持一致
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF2563EB);

  // 强调色 - 这些颜色在深色和浅色主题中保持一致
  static const Color accent = Color(0xFF0EA5E9);
  static const Color accentLight = Color(0xFF38BDF8);
  static const Color accentDark = Color(0xFF0284C7);

  // 状态色 - 这些颜色在深色和浅色主题中保持一致
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // 阴影色
  static const Color shadow = Color(0x1A000000);

  // 浅色主题颜色
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightOnBackground = Color(0xFF1E293B);
  static const Color _lightOnSurface = Color(0xFF334155);
  static const Color _lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color _lightTextPrimary = Color(0xFF1E293B);
  static const Color _lightTextSecondary = Color(0xFF64748B);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightDivider = Color(0xFFE2E8F0);

  // 暗色主题颜色
  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkSurfaceVariant = Color(0xFF334155);
  static const Color _darkOnPrimary = Color(0xFFFFFFFF);
  static const Color _darkOnBackground = Color(0xFFF8FAFC);
  static const Color _darkOnSurface = Color(0xFFE2E8F0);
  static const Color _darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color _darkTextPrimary = Color(0xFFF8FAFC);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);
  static const Color _darkBorder = Color(0xFF334155);
  static const Color _darkDivider = Color(0xFF334155);

  // 根据当前主题返回相应的颜色
  static Color get background =>
      Get.isDarkMode ? _darkBackground : _lightBackground;
  static Color get surface => Get.isDarkMode ? _darkSurface : _lightSurface;
  static Color get surfaceVariant =>
      Get.isDarkMode ? _darkSurfaceVariant : _lightSurfaceVariant;
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
  static Color get border => Get.isDarkMode ? _darkBorder : _lightBorder;
  static Color get divider => Get.isDarkMode ? _darkDivider : _lightDivider;
}
