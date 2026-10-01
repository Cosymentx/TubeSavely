import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 应用间距系统 - 遵循8pt基准
class AppSpacing {
  AppSpacing._();

  // 基础间距
  static double xs = 4.w;     // 4pt
  static double sm = 8.w;     // 8pt
  static double md = 12.w;    // 12pt
  static double lg = 16.w;    // 16pt
  static double xl = 24.w;    // 24pt
  static double xxl = 32.w;   // 32pt
  static double xxxl = 48.w;  // 48pt

  // 页面间距
  static double pagePaddingHorizontal = 16.w;
  static double pagePaddingVertical = 16.h;
  static double pageMarginTop = 12.h;

  // 圆角半径
  static double radiusSm = 8.r;
  static double radiusMd = 12.r;
  static double radiusLg = 16.r;
  static double radiusXl = 20.r;
  static double radiusRound = 999.r;

  // 图标大小
  static double iconSm = 16.w;
  static double iconMd = 24.w;
  static double iconLg = 32.w;
  static double iconXl = 48.w;

  // 按钮高度
  static double buttonHeightSm = 32.h;
  static double buttonHeightMd = 40.h;
  static double buttonHeightLg = 48.h;
}
