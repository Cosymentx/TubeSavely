import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

/// 加载指示组件
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isOverlay;
  final Color? backgroundColor;

  const LoadingWidget({
    Key? key,
    this.message,
    this.isOverlay = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isCupertino)
          const CupertinoActivityIndicator(
            radius: 15,
          )
        else
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        if (message != null) ...[
          SizedBox(height: 16.h),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (isOverlay) {
      return Container(
        color: backgroundColor ?? Colors.black.withAlpha(102),
        child: Center(child: child),
      );
    }

    return Center(child: child);
  }
}

/// 空状态组件
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onRetry,
    this.retryButtonText = '重试',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 64.sp,
                color: AppColors.textSecondary.withAlpha(128),
              ),
            if (icon != null) SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              _buildRetryButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    if (isCupertino) {
      return CupertinoButton(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8.r),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        onPressed: onRetry,
        child: Text(
          retryButtonText ?? '重试',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onRetry,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      child: Text(
        retryButtonText ?? '重试',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 错误状态组件
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorStateWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryButtonText = '重试',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: title,
      subtitle: subtitle,
      icon: Icons.error_outline,
      onRetry: onRetry,
      retryButtonText: retryButtonText,
    );
  }
}

/// 骨架屏加载（占位符）
class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final double height;
  final double? width;
  final bool isHorizontal;
  final EdgeInsetsGeometry? padding;

  const SkeletonLoader({
    Key? key,
    this.itemCount = 3,
    this.height = 100,
    this.width,
    this.isHorizontal = false,
    this.padding,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.all(16.w),
      child: widget.isHorizontal
          ? _buildHorizontalSkeleton()
          : _buildVerticalSkeleton(),
    );
  }

  Widget _buildVerticalSkeleton() {
    return Column(
      children: List.generate(
        widget.itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildSkeletonItem(),
        ),
      ),
    );
  }

  Widget _buildHorizontalSkeleton() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          widget.itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: _buildSkeletonItem(),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.3 + (0.3 * _controller.value);
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(opacity),
            borderRadius: BorderRadius.circular(8.r),
          ),
        );
      },
    );
  }
}
