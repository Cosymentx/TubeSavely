import 'dart:io';
import 'package:flutter/material.dart';

/// 桌面端通用弹窗外层容器
class DesktopDialogWrapper extends StatelessWidget {
  const DesktopDialogWrapper({
    super.key,
    required this.child,
    this.width = 450,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMac = Platform.isMacOS;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(minWidth: 320, maxWidth: width),
        padding: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶栏关闭按钮
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: isMac ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  IconButton(
                    iconSize: 18,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
