import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_util.dart';

/// 适配型 Scaffold - 同时支持 iOS 和 Android
/// 内部自动处理平台差异，页面只需调用
class AdaptiveScaffold extends StatelessWidget {
  /// Android AppBar
  final PreferredSizeWidget? appBar;
  
  /// iOS CupertinoNavigationBar
  final CupertinoNavigationBar? cupertinoNavBar;
  
  /// 主体内容
  final Widget body;
  
  /// 浮动操作按钮 (仅 Android)
  final Widget? floatingActionButton;
  
  /// 底部导航栏 (Material)
  final Widget? bottomNavigationBar;
  
  /// iOS 底部工具栏
  final CupertinoTabBar? cupertinoBottomTabBar;
  
  /// 背景色
  final Color? backgroundColor;
  
  /// 抽屉菜单 (仅 Android)
  final Widget? drawer;

  const AdaptiveScaffold({
    Key? key,
    this.appBar,
    this.cupertinoNavBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.cupertinoBottomTabBar,
    this.backgroundColor,
    this.drawer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      Widget content = body;
      if (bottomNavigationBar != null) {
        content = Column(
          children: [
            Expanded(child: content),
            bottomNavigationBar!,
          ],
        );
      }
      return CupertinoPageScaffold(
        navigationBar: cupertinoNavBar,
        backgroundColor: backgroundColor,
        child: content,
      );
    } else {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: backgroundColor,
        drawer: drawer,
      );
    }
  }
}

/// 适配型 AppBar - 同时支持 Material AppBar 和 Cupertino NavigationBar
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 标题
  final String title;
  
  /// 标题样式
  final TextStyle? titleStyle;
  
  /// 右侧操作按钮
  final List<Widget> actions;
  
  /// 左侧返回按钮
  final bool showLeading;
  
  /// 返回按钮回调
  final VoidCallback? onLeadingPressed;
  
  /// 背景色 (Android)
  final Color? backgroundColor;
  
  /// 右侧 iOS 按钮组件
  final Widget? cupertinoTrailing;

  const AdaptiveAppBar({
    Key? key,
    required this.title,
    this.titleStyle,
    this.actions = const [],
    this.showLeading = true,
    this.onLeadingPressed,
    this.backgroundColor,
    this.cupertinoTrailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(title, style: titleStyle),
        trailing: cupertinoTrailing,
        backgroundColor: backgroundColor,
      );
    } else {
      return AppBar(
        title: Text(title, style: titleStyle),
        backgroundColor: backgroundColor,
        actions: actions,
        leading: showLeading
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onLeadingPressed ?? () => Navigator.pop(context),
              )
            : null,
      );
    }
  }

  @override
  Size get preferredSize {
    if (PlatformUtil.isIOS) {
      return const Size.fromHeight(44);
    }
    return const Size.fromHeight(56);
  }
}

/// 适配型按钮 - 同时支持 Material 和 Cupertino
class AdaptiveButton extends StatelessWidget {
  /// 按钮标签
  final String label;
  
  /// 点击回调
  final VoidCallback onPressed;
  
  /// 是否为主按钮
  final bool isPrimary;
  
  /// 是否禁用
  final bool isEnabled;
  
  /// 是否为加载状态
  final bool isLoading;
  
  /// 图标 (可选)
  final IconData? icon;
  
  /// 自定义宽度
  final double? width;

  const AdaptiveButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isEnabled = true,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return CupertinoButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        child: SizedBox(
          width: width,
          child: isLoading
              ? const CupertinoActivityIndicator()
              : Text(label),
        ),
      );
    } else {
      return SizedBox(
        width: width,
        child: ElevatedButton.icon(
          onPressed: isEnabled && !isLoading ? onPressed : null,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon ?? Icons.check),
          label: Text(label),
        ),
      );
    }
  }
}

/// 适配型文本输入框 - 同时支持 Material 和 Cupertino
class AdaptiveTextField extends StatefulWidget {
  /// 输入框标签
  final String label;
  
  /// 提示文本
  final String? hint;
  
  /// 控制器
  final TextEditingController? controller;
  
  /// 输入框类型
  final TextInputType keyboardType;
  
  /// 前缀图标
  final IconData? prefixIcon;
  
  /// 后缀图标
  final IconData? suffixIcon;
  
  /// 后缀图标点击回调
  final VoidCallback? onSuffixIconPressed;
  
  /// 值改变回调
  final ValueChanged<String>? onChanged;
  
  /// 提交回调
  final VoidCallback? onSubmitted;
  
  /// 验证函数
  final String? Function(String?)? validator;
  
  /// 行数
  final int maxLines;
  
  /// 最小行数
  final int minLines;
  
  /// 是否隐藏输入 (密码)
  final bool obscureText;

  const AdaptiveTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
  }) : super(key: key);

  @override
  State<AdaptiveTextField> createState() => _AdaptiveTextFieldState();
}

class _AdaptiveTextFieldState extends State<AdaptiveTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return CupertinoTextField(
        controller: widget.controller,
        focusNode: _focusNode,
        placeholder: widget.hint,
        keyboardType: widget.keyboardType,
        prefix: widget.prefixIcon != null
            ? Icon(widget.prefixIcon)
            : null,
        suffix: widget.suffixIcon != null
            ? GestureDetector(
                onTap: widget.onSuffixIconPressed,
                child: Icon(widget.suffixIcon),
              )
            : null,
        onChanged: widget.onChanged,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
      );
    } else {
      return TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon)
              : null,
          suffixIcon: widget.suffixIcon != null
              ? IconButton(
                  icon: Icon(widget.suffixIcon),
                  onPressed: widget.onSuffixIconPressed,
                )
              : null,
        ),
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        validator: widget.validator,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
      );
    }
  }
}

/// 适配型对话框 - 同时支持 AlertDialog 和 CupertinoAlertDialog
class AdaptiveAlertDialog extends StatelessWidget {
  /// 标题
  final String title;
  
  /// 内容
  final String content;
  
  /// 取消按钮文本
  final String cancelText;
  
  /// 确认按钮文本
  final String confirmText;
  
  /// 取消回调
  final VoidCallback? onCancel;
  
  /// 确认回调
  final VoidCallback? onConfirm;

  const AdaptiveAlertDialog({
    Key? key,
    required this.title,
    required this.content,
    this.cancelText = '取消',
    this.confirmText = '确认',
    this.onCancel,
    this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            onPressed: onConfirm ?? () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text(confirmText),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: onConfirm ?? () => Navigator.pop(context),
            child: Text(confirmText),
          ),
        ],
      );
    }
  }
}
