import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_spacing.dart';

/// 现代化主题感知骨架屏微光组件 (UI/UX Pro Max 规范)
class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBaseColor = isDark
        ? const Color(0xFF1E293B) // Slate-800
        : const Color(0xFFE2E8F0); // Slate-200

    final defaultHighlightColor = isDark
        ? const Color(0xFF334155) // Slate-700
        : const Color(0xFFF8FAFC); // Slate-50

    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBaseColor,
      highlightColor: highlightColor ?? defaultHighlightColor,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// 基础骨架块 (支持矩形、圆角、胶囊体或圆形)
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppSpacing.radiusSm,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// 视频解析中的骨架占位卡片 (HomeView 解析中状态)
class VideoParseSkeletonCard extends StatelessWidget {
  const VideoParseSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部提示条
            Row(
              children: [
                const SkeletonBox(width: 16, height: 16, borderRadius: 4),
                const SizedBox(width: AppSpacing.xs),
                const SkeletonBox(width: 120, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 16:9 缩略图大骨架
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: const SkeletonBox(width: double.infinity, height: double.infinity),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 标题第一行与第二行
            const SkeletonBox(width: double.infinity, height: 16, borderRadius: 4),
            const SizedBox(height: 8),
            const SkeletonBox(width: 200, height: 16, borderRadius: 4),
            const SizedBox(height: AppSpacing.md),

            // 平台图标与作者胶囊
            Row(
              children: [
                const SkeletonBox(width: 24, height: 24, isCircle: true),
                const SizedBox(width: AppSpacing.xs),
                const SkeletonBox(width: 80, height: 12, borderRadius: 4),
                const Spacer(),
                const SkeletonBox(width: 60, height: 18, borderRadius: 4),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 规格选择胶囊骨架
            Row(
              children: const [
                SkeletonBox(width: 70, height: 28, borderRadius: AppSpacing.radiusRound),
                SizedBox(width: AppSpacing.sm),
                SkeletonBox(width: 70, height: 28, borderRadius: AppSpacing.radiusRound),
                SizedBox(width: AppSpacing.sm),
                SkeletonBox(width: 70, height: 28, borderRadius: AppSpacing.radiusRound),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 下载行动按钮骨架
            const SkeletonBox(
              width: double.infinity,
              height: 44,
              borderRadius: AppSpacing.radiusMd,
            ),
          ],
        ),
      ),
    );
  }
}

/// 任务卡片骨架屏 (TasksView / HistoryView 加载中状态)
class TaskCardSkeleton extends StatelessWidget {
  const TaskCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SkeletonShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩略图占位
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: const SkeletonBox(width: 100, height: 62),
            ),
            const SizedBox(width: AppSpacing.md),

            // 内容文本占位
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  const SkeletonBox(width: 140, height: 12, borderRadius: 4),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBox(width: 60, height: 10, borderRadius: 3),
                      SkeletonBox(width: 40, height: 10, borderRadius: 3),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 热门推荐视频骨架列表
class TrendingListSkeleton extends StatelessWidget {
  final int count;

  const TrendingListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) {
          return SizedBox(
            width: 220,
            child: SkeletonShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: const SkeletonBox(width: 220, height: 124),
                  ),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 200, height: 12, borderRadius: 3),
                  const SizedBox(height: 4),
                  const SkeletonBox(width: 110, height: 10, borderRadius: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
