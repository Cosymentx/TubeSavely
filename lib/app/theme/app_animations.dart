import 'package:flutter/material.dart';

/// 应用动画系统
class AppAnimations {
  AppAnimations._();

  // 动画时长
  static const Duration durationXs = Duration(milliseconds: 100);
  static const Duration durationSm = Duration(milliseconds: 200);
  static const Duration durationMd = Duration(milliseconds: 300);
  static const Duration durationLg = Duration(milliseconds: 500);
  static const Duration durationXl = Duration(milliseconds: 800);

  // 缓动曲线
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveBounce = Curves.bounceOut;
  static const Curve curveElastic = Curves.elasticOut;

  // 页面过渡时间
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeInOut;

  // 按钮点击反馈时间
  static const Duration tapFeedbackDuration = Duration(milliseconds: 150);

  // 加载动画时间
  static const Duration loadingAnimationDuration = Duration(milliseconds: 1200);
}
