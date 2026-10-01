import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_util.dart';

/// 自适应开关 - 根据平台自动选择 Material 或 Cupertino 风格
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const AdaptiveSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return _buildCupertinoSwitch();
    } else {
      return _buildMaterialSwitch();
    }
  }

  /// 构建 Cupertino 风格开关 (iOS)
  Widget _buildCupertinoSwitch() {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }

  /// 构建 Material 风格开关 (Android)
  Widget _buildMaterialSwitch() {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      inactiveThumbColor: inactiveColor,
    );
  }
}
