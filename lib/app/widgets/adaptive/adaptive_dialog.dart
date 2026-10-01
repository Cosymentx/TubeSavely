import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_util.dart';

/// 自适应弹框 - 根据平台自动选择 Material 或 Cupertino 风格
class AdaptiveDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmButtonText;
  final String? cancelButtonText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerousAction;
  final Widget? content;

  const AdaptiveDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmButtonText = '确认',
    this.cancelButtonText = '取消',
    this.onConfirm,
    this.onCancel,
    this.isDangerousAction = false,
    this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return _buildCupertinoDialog(context);
    } else {
      return _buildMaterialDialog(context);
    }
  }

  /// 构建 Cupertino 风格弹框 (iOS)
  Widget _buildCupertinoDialog(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: content ?? Text(message),
      actions: [
        if (cancelButtonText != null)
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(cancelButtonText!),
          ),
        if (confirmButtonText != null)
          CupertinoDialogAction(
            isDefaultAction: !isDangerousAction,
            isDestructiveAction: isDangerousAction,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: Text(confirmButtonText!),
          ),
      ],
    );
  }

  /// 构建 Material 风格弹框 (Android)
  Widget _buildMaterialDialog(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content ?? Text(message),
      actions: [
        if (cancelButtonText != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(cancelButtonText!),
          ),
        if (confirmButtonText != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: Text(
              confirmButtonText!,
              style: TextStyle(
                color: isDangerousAction ? Colors.red : Colors.blue,
              ),
            ),
          ),
      ],
    );
  }
}

/// 显示自适应弹框的工具方法
Future<bool?> showAdaptiveDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmButtonText = '确认',
  String? cancelButtonText = '取消',
  bool isDangerousAction = false,
  Widget? content,
}) {
  return showDialog<bool?>(
    context: context,
    builder: (context) => AdaptiveDialog(
      title: title,
      message: message,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
      isDangerousAction: isDangerousAction,
      content: content,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
  );
}
