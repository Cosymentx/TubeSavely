import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_util.dart';

/// 菜单项
class MenuItemModel {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDangerous;

  MenuItemModel({
    required this.label,
    this.icon,
    required this.onTap,
    this.isDangerous = false,
  });
}

/// 自适应菜单 - 根据平台自动选择 Material 或 Cupertino 风格
class AdaptiveMenu extends StatelessWidget {
  final Widget child;
  final List<MenuItemModel> items;
  final Offset offset;

  const AdaptiveMenu({
    Key? key,
    required this.child,
    required this.items,
    this.offset = const Offset(0, 40),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return _buildCupertinoMenu(context);
    } else {
      return _buildMaterialMenu(context);
    }
  }

  /// 构建 Cupertino 风格菜单 (iOS)
  Widget _buildCupertinoMenu(BuildContext context) {
    return CupertinoActionSheetAction(
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            actions: items.map((item) {
              return CupertinoActionSheetAction(
                isDestructiveAction: item.isDangerous,
                onPressed: () {
                  Navigator.pop(context);
                  item.onTap();
                },
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon),
                      const SizedBox(width: 12),
                    ],
                    Text(item.label),
                  ],
                ),
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// 构建 Material 风格菜单 (Android)
  Widget _buildMaterialMenu(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: (index) {
        items[index].onTap();
      },
      itemBuilder: (context) {
        return items.asMap().entries.map((entry) {
          final item = entry.value;
          return PopupMenuItem(
            value: entry.key,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon),
                  const SizedBox(width: 12),
                ],
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.isDangerous ? Colors.red : null,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: child,
    );
  }
}

/// 显示自适应底部菜单
Future<void> showAdaptiveBottomMenu(
  BuildContext context, {
  required List<MenuItemModel> items,
}) {
  if (PlatformUtil.isIOS) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: items.map((item) {
          return CupertinoActionSheetAction(
            isDestructiveAction: item.isDangerous,
            onPressed: () {
              Navigator.pop(context);
              item.onTap();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon),
                  const SizedBox(width: 8),
                ],
                Text(item.label),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  } else {
    return showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            return ListTile(
              leading: item.icon != null ? Icon(item.icon) : null,
              title: Text(
                item.label,
                style: TextStyle(
                  color: item.isDangerous ? Colors.red : null,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                item.onTap();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
