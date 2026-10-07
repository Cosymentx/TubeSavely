import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../widgets/adaptive/responsive_layout.dart';
import '../controllers/profile_controller.dart';

/// 现代化响应式个人中心视图（移动端 & 桌面端通用，移除 ScreenUtil 强依赖）
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(
          '个人中心',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '应用设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: controller.goToSettings,
          ),
        ],
      ),
      cupertinoNavBar: CupertinoNavigationBar(
        middle: const Text('个人中心'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: controller.goToSettings,
          child: const Icon(CupertinoIcons.settings, size: 22),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: controller.refreshUserInfo,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsiveBuilder(
              builder: (context, screenType) {
                final isCompact = screenType == AppScreenType.compact;
                return ResponsiveContainer(
                  maxWidth: 800,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact
                        ? AppSpacing.pagePaddingHorizontal
                        : AppSpacing.desktopContentPadding,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      // 用户主体信息舱
                      _buildUserHeader(context),
                      const SizedBox(height: AppSpacing.lg),

                      // 核心资产卡片 (已登录状态展示)
                      _buildAssetOverview(context),

                      // 业务特权功能组
                      _buildSectionCard(
                        context: context,
                        title: '特权与服务',
                        items: [
                          _ProfileItemConfig(
                            icon: Icons.workspace_premium_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: '会员中心',
                            subtitle: '解锁超清画质与批量解析特权',
                            onTap: controller.goToMembership,
                          ),
                          _ProfileItemConfig(
                            icon: Icons.stars_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            title: '积分中心',
                            subtitle: '每日签到领取极速解析积分',
                            onTap: controller.goToCredits,
                          ),
                          _ProfileItemConfig(
                            icon: Icons.history_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: '下载历史',
                            onTap: controller.goToHistory,
                          ),
                          _ProfileItemConfig(
                            icon: Icons.download_rounded,
                            iconColor: AppColors.primary,
                            title: '下载任务',
                            onTap: controller.goToTasks,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 系统通用设置组
                      _buildSectionCard(
                        context: context,
                        title: '应用与系统',
                        items: [
                          _ProfileItemConfig(
                            icon: Icons.settings_rounded,
                            iconColor: const Color(0xFF64748B),
                            title: '通用设置',
                            subtitle: '存储路径、外观主题及下载线程',
                            onTap: controller.goToSettings,
                          ),
                          _ProfileItemConfig(
                            icon: Icons.widgets_rounded,
                            iconColor: const Color(0xFF64748B),
                            title: '媒体工具库',
                            onTap: controller.goToMore,
                          ),
                          if (controller.isDevModeEnabled())
                            _ProfileItemConfig(
                              icon: Icons.developer_mode_rounded,
                              iconColor: const Color(0xFFEF4444),
                              title: '开发者调试中心',
                              onTap: controller.goToDeveloper,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 关于与协议组
                      _buildSectionCard(
                        context: context,
                        title: '关于 TubeSavely',
                        items: [
                          _ProfileItemConfig(
                            icon: Icons.info_outline_rounded,
                            iconColor: const Color(0xFF64748B),
                            title: '关于应用',
                            onTap: () => _showAboutDialog(context),
                          ),
                          _ProfileItemConfig(
                            icon: Icons.system_update_alt_rounded,
                            iconColor: const Color(0xFF64748B),
                            title: '检查版本更新',
                            trailing: Text(
                              'v1.0.0',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onTap: () => Utils.showSnackbar('提示', '当前已是最新稳定版本'),
                          ),
                          _ProfileItemConfig(
                            icon: Icons.shield_outlined,
                            iconColor: const Color(0xFF64748B),
                            title: '隐私政策',
                            onTap: () => Utils.launchURL(Constants.PRIVACY_URL),
                          ),
                          _ProfileItemConfig(
                            icon: Icons.description_outlined,
                            iconColor: const Color(0xFF64748B),
                            title: '用户服务协议',
                            onTap: () => Utils.launchURL(Constants.TERMS_URL),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 退出登录按钮
                      _buildLogoutButton(context),
                      const SizedBox(height: AppSpacing.xxl),

                      // 底部版权标识
                      _buildFooter(context),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 1. 用户头部信息舱 ====================
  Widget _buildUserHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isLoggedIn = controller.isLoggedIn.value;
      final user = controller.user.value;

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
        child: isLoggedIn
            ? Row(
                children: [
                  // 头像环
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      image: user?.avatar != null
                          ? DecorationImage(
                              image: NetworkImage(user!.avatar!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: user?.avatar == null
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.lg),

                  // 用户名与会员角标
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? '尊贵会员',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            controller.getMembershipStatus(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 会员续费快捷入口
                  OutlinedButton(
                    onPressed: controller.goToMembership,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: const Text('特权升级', style: TextStyle(fontSize: 12)),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerLow,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 36,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '未登录 TubeSavely',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '登录同步多端下载记录并享高速特权',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: controller.login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: const Text('点击登录'),
                  ),
                ],
              ),
      );
    });
  }

  // ==================== 2. 核心资产概览卡片 ====================
  Widget _buildAssetOverview(BuildContext context) {
    return Obx(() {
      if (!controller.isLoggedIn.value) return const SizedBox.shrink();
      final user = controller.user.value;
      if (user == null) return const SizedBox.shrink();

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildAssetMetric(
                context: context,
                label: '可用积分',
                value: '${user.credits}',
                onTap: controller.goToCredits,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _buildAssetMetric(
                context: context,
                label: '会员到期',
                value: controller.getMembershipExpiry(),
                onTap: controller.goToMembership,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAssetMetric({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.dataLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 3. 功能分区卡片 ====================
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<_ProfileItemConfig> items,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;

            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: isLast
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(AppSpacing.radiusLg),
                          )
                        : BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.iconColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Icon(
                              item.icon,
                              size: 18,
                              color: item.iconColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (item.trailing != null) ...[
                            item.trailing!,
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: colorScheme.outlineVariant,
                    indent: 58,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ==================== 4. 退出登录按钮 ====================
  Widget _buildLogoutButton(BuildContext context) {
    return Obx(() {
      if (!controller.isLoggedIn.value) return const SizedBox.shrink();

      final isLoading = controller.isLoading.value;

      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              : const Icon(Icons.logout_rounded, size: 18),
          label: Text(isLoading ? '正在退出...' : '退出当前账号'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(
              color: AppColors.error.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          onPressed: isLoading ? null : controller.logout,
        ),
      );
    });
  }

  // ==================== 5. 底部版权与标志 ====================
  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'TubeSavely Cross-Platform Media Suite',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2024-2026 TubeSavely Team. All Rights Reserved.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ==================== 6. 关于应用弹窗 ====================
  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('关于 TubeSavely'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TubeSavely 是一款现代化全平台多媒体下载与处理工具箱，支持超高清视频解析下载、无损格式转换与极速压缩。',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _buildFeatureBullet('全网主流视频平台智能无损解析'),
            _buildFeatureBullet('多线程并行加速与断点续传支持'),
            _buildFeatureBullet('音视频格式转换与智能轻量化压缩'),
            _buildFeatureBullet('移动端与桌面端自适应双端流畅体验'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _ProfileItemConfig {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  _ProfileItemConfig({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });
}
