import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_util.dart';

/// 自适应输入框 - 根据平台自动选择 Material 或 Cupertino 风格
class AdaptiveTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String placeholder;
  final String? label;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final Color? fillColor;
  final bool filled;
  final Border? border;
  final Color? borderColor;

  const AdaptiveTextField({
    Key? key,
    this.controller,
    required this.placeholder,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.contentPadding,
    this.borderRadius,
    this.fillColor,
    this.filled = true,
    this.border,
    this.borderColor,
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
      return _buildCupertinoTextField();
    } else {
      return _buildMaterialTextField();
    }
  }

  /// 构建 Cupertino 风格输入框 (iOS)
  Widget _buildCupertinoTextField() {
    return CupertinoTextField(
      controller: widget.controller,
      placeholder: widget.placeholder,
      placeholderStyle: TextStyle(
        color: Colors.grey[400],
      ),
      padding: widget.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.fillColor ?? CupertinoColors.systemBackground,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: widget.borderColor ?? Colors.grey[300]!,
          width: 1,
        ),
      ),
      prefix: widget.prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: widget.prefixIcon,
            )
          : null,
      suffix: widget.suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: widget.suffixIcon,
            )
          : null,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted?.call(),
      focusNode: _focusNode,
    );
  }

  /// 构建 Material 风格输入框 (Android)
  Widget _buildMaterialTextField() {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        label: widget.label != null ? Text(widget.label!) : null,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: widget.filled,
        fillColor: widget.fillColor,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          borderSide: widget.border != null
              ? widget.border!.top
              : BorderSide(
                  color: widget.borderColor ?? Colors.grey[300]!,
                  width: 1,
                ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.borderColor ?? Colors.blue,
            width: 2,
          ),
        ),
      ),
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted?.call(),
      focusNode: _focusNode,
    );
  }
}
