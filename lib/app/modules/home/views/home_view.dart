import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/video_model.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/utils.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../widgets/adaptive/responsive_layout.dart';
import '../../../widgets/skeleton/skeleton_loading.dart';
import '../controllers/home_controller.dart';

/// 现代化响应式首页（完全适配移动端与桌面端，移除 ScreenUtil 强依赖）
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      body: SafeArea(
        top: false,
        child: ResponsiveBuilder(
          builder: (context, screenType) {
            final isCompact = screenType == AppScreenType.compact;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact
                    ? AppSpacing.pagePaddingHorizontal
                    : AppSpacing.desktopContentPadding,
                vertical: AppSpacing.lg,
              ),
              child: ResponsiveContainer(
                maxWidth: 1100,
                child: isCompact
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== 移动端紧凑型流式布局 ====================
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroSearchInput(context),
        const SizedBox(height: AppSpacing.xl),
        _buildDownloadOptions(context),
        _buildQuickActions(context),
        const SizedBox(height: AppSpacing.xl),
        _buildVideoTools(context),
        const SizedBox(height: AppSpacing.xl),
        _buildTrendingVideos(context),
        const SizedBox(height: AppSpacing.xl),
        _buildSupportedPlatforms(context),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  // ==================== 桌面端多列分栏布局 ====================
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部宽幅解析舱
        _buildHeroSearchInput(context),
        const SizedBox(height: AppSpacing.xl),

        // 解析选项（若有视频已解析，置于醒目位置）
        _buildDownloadOptions(context),

        // 主副双列区域
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左列（主内容区）：热门视频推荐与内容发现
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrendingVideos(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSupportedPlatforms(context),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),

            // 右列（工具侧边）：快捷工具箱与账户特权
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVideoTools(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  // ==================== 1. 核心解析搜索舱 (Hero Input) ====================
  Widget _buildHeroSearchInput(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '全网媒体智能解析下载',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              // 一键粘贴剪贴板
              TextButton.icon(
                icon: const Icon(Icons.content_paste_rounded, size: 15),
                label: const Text('粘贴链接', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null && data!.text!.trim().isNotEmpty) {
                    controller.urlController.text = data.text!.trim();
                    controller.parseVideo();
                  } else {
                    Utils.showSnackbar('提示', '剪切板中暂无有效链接');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 输入输入框与主行动按钮
          Obx(() {
            final isLoading = controller.isLoading.value;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101724) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: controller.urlController,
                      decoration: InputDecoration(
                        hintText: '粘贴 YouTube / Bilibili / TikTok 视频分享链接...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => controller.parseVideo(),
                    ),
                  ),
                  // 解析执行按钮
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.bolt_rounded, size: 18),
                        label: Text(isLoading ? '解析中...' : '解析'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                        onPressed: isLoading ? null : controller.parseVideo,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== 2. 视频工具箱 (Toolbox) ====================
  Widget _buildVideoTools(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_fix_high_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '媒体工具箱',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  context: context,
                  icon: Icons.swap_horiz_rounded,
                  title: '格式转换',
                  subtitle: 'MP4/MKV/MP3',
                  accentColor: const Color(0xFF3B82F6),
                  onTap: () => Get.toNamed(Routes.CONVERT),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildToolCard(
                  context: context,
                  icon: Icons.compress_rounded,
                  title: '无损压缩',
                  subtitle: '智能瘦身省空间',
                  accentColor: const Color(0xFF10B981),
                  onTap: () => Get.toNamed('/compress'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF101724) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 3. 热门视频发现 (Trending) ====================
  Widget _buildTrendingVideos(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final videos = controller.trendingVideos;
      if (videos.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: colorScheme.outlineVariant, width: 1),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '热门发现',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return _buildTrendingVideoCard(context, video);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrendingVideoCard(BuildContext context, VideoModel video) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => controller.openVideoDetail(video),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: video.thumbnail ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceContainerLow,
                    child: Icon(
                      Icons.movie_creation_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.author ?? '媒体创作者',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 4. 下载选项卡片 (Download Options) ====================
  Widget _buildDownloadOptions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final video = controller.currentVideo.value;

      if (isLoading && video == null) {
        return const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xl),
          child: VideoParseSkeletonCard(),
        );
      }

      if (video == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: AppSpacing.shadowPrimaryGlow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '解析就绪：请选择规格',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 视频基本信息
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: SizedBox(
                    width: 110,
                    height: 66,
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnail ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Icons.video_library_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '平台: ${video.platform ?? "网络视频"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 清晰度与格式胶囊
            Text('清晰度', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: ['1080P', '720P', '480P'].map((q) {
                final isSelected = controller.selectedQuality.value == q;
                return ChoiceChip(
                  label: Text(q, style: AppTextStyles.dataSmall),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  onSelected: (_) => controller.setQuality(q),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // 格式
            Text('格式', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: ['MP4', 'MKV', 'MP3'].map((f) {
                final isSelected = controller.selectedFormat.value == f;
                return ChoiceChip(
                  label: Text(f, style: AppTextStyles.dataSmall),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  onSelected: (_) => controller.setFormat(f),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 开始下载 CTA
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('立即开始高速下载'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onPressed: controller.downloadVideo,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ==================== 5. 会员与充值快捷卡片 ====================
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: '升级高级特权',
            subtitle: '不限速 · 批量下载',
            icon: Icons.workspace_premium_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            ),
            onTap: controller.goToMembership,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildActionCard(
            title: '账户积分充值',
            subtitle: '极速转码与专属解析',
            icon: Icons.stars_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            onTap: controller.goToCredits,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(gradient: gradient),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 6. 支持的平台徽章 ====================
  Widget _buildSupportedPlatforms(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final platforms = controller.supportedPlatforms;
      if (platforms.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: colorScheme.outlineVariant, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.public_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '支持的热门站点',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: platforms.map((p) {
                final name = p['name'] ?? '';
                return Chip(
                  avatar: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  backgroundColor: colorScheme.surfaceContainerLow,
                  side: BorderSide(color: colorScheme.outlineVariant),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}
