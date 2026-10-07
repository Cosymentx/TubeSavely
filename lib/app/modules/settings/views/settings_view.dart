import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../widgets/adaptive/responsive_layout.dart';
import '../controllers/settings_controller.dart';

/// 现代化应用设置视图（移动端 & 桌面端通用，移除 ScreenUtil 强依赖）
/// 遵循 UI/UX Pro Max 规范：优雅分组卡片式设计、精细化色彩指示与多端适配
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(
          '应用设置',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      cupertinoNavBar: const CupertinoNavigationBar(
        middle: Text('应用设置'),
      ),
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
              child: Center(
                child: ResponsiveContainer(
                  maxWidth: 800,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 外观与个性化
                      _buildSectionHeader(context, '界面与语言', Icons.palette_outlined),
                      _buildGroupContainer(
                        context,
                        children: [
                          _buildThemeTile(context),
                          _buildDivider(context),
                          _buildLanguageTile(context),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 2. 下载与网络
                      _buildSectionHeader(context, '下载与网络传输', Icons.cloud_download_outlined),
                      _buildGroupContainer(
                        context,
                        children: [
                          _buildDownloadPathTile(context),
                          _buildDivider(context),
                          _buildWifiOnlyTile(context),
                          _buildDivider(context),
                          _buildAutoDownloadTile(context),
                          _buildDivider(context),
                          _buildNotificationTile(context),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 3. 视频与格式处理
                      _buildSectionHeader(context, '媒体与处理策略', Icons.video_settings_outlined),
                      _buildGroupContainer(
                        context,
                        children: [
                          _buildVideoQualityTile(context),
                          _buildDivider(context),
                          _buildVideoFormatTile(context),
                          _buildDivider(context),
                          _buildVideoConvertTile(context),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 4. 存储与系统缓存
                      _buildSectionHeader(context, '存储与空间释放', Icons.storage_outlined),
                      _buildGroupContainer(
                        context,
                        children: [
                          _buildCacheTile(context),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 5. 关于与法律条款
                      _buildSectionHeader(context, '关于与条款', Icons.info_outline_rounded),
                      _buildGroupContainer(
                        context,
                        children: [
                          _buildAboutTile(context),
                          _buildDivider(context),
                          _buildPrivacyTile(context),
                          _buildDivider(context),
                          _buildTermsTile(context),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== 容器与头部布局 ====================

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs + 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContainer(BuildContext context, {required List<Widget> children}) {
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      endIndent: 16,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildIconBadge({required IconData icon, required Color color}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  // ==================== 1. 外观设置项 ====================

  Widget _buildThemeTile(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B),
        ),
        title: const Text('深色模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          isDark ? '已启用深色外观' : '已启用浅色外观',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Switch.adaptive(
          value: isDark,
          activeTrackColor: AppColors.primary,
          onChanged: (_) => controller.toggleTheme(),
        ),
        onTap: () => controller.toggleTheme(),
      );
    });
  }

  Widget _buildLanguageTile(BuildContext context) {
    return Obx(() {
      String languageName = '简体中文';
      switch (controller.currentLanguage.value) {
        case 'zh_CN':
        case 'zh':
          languageName = '简体中文';
          break;
        case 'en_US':
        case 'en':
          languageName = 'English';
          break;
        case 'ja_JP':
        case 'ja':
          languageName = '日本語';
          break;
        case 'ko_KR':
        case 'ko':
          languageName = '한국어';
          break;
      }

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: Icons.language_rounded,
          color: const Color(0xFF3B82F6),
        ),
        title: const Text('显示语言', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          languageName,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
        onTap: () => _showLanguageSelector(context),
      );
    });
  }

  void _showLanguageSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '选择显示语言',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildLanguageOption('简体中文', 'zh', 'CN'),
            _buildLanguageOption('English', 'en', 'US'),
            _buildLanguageOption('日本語', 'ja', 'JP'),
            _buildLanguageOption('한국어', 'ko', 'KR'),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildLanguageOption(String name, String languageCode, String countryCode) {
    return Obx(() {
      final isSelected = controller.currentLanguage.value == '${languageCode}_$countryCode' ||
          controller.currentLanguage.value == languageCode;

      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            : null,
        onTap: () {
          controller.setLanguage(languageCode, countryCode);
          Get.back();
        },
      );
    });
  }

  // ==================== 2. 下载与网络设置项 ====================

  Widget _buildDownloadPathTile(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: Icons.folder_open_rounded,
          color: const Color(0xFFF59E0B),
        ),
        title: const Text('默认下载路径', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          controller.downloadPath.value.isEmpty ? '系统默认下载目录' : controller.downloadPath.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
        onTap: () => controller.selectDownloadPath(),
      );
    });
  }

  Widget _buildWifiOnlyTile(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: Icons.wifi_rounded,
          color: const Color(0xFF0EA5E9),
        ),
        title: const Text('仅在 Wi-Fi 下下载', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '避免在蜂窝移动网络下消耗过多流量',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Switch.adaptive(
          value: controller.wifiOnly.value,
          activeTrackColor: AppColors.primary,
          onChanged: (val) => controller.setWifiOnly(val),
        ),
        onTap: () => controller.setWifiOnly(!controller.wifiOnly.value),
      );
    });
  }

  Widget _buildAutoDownloadTile(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: Icons.bolt_rounded,
          color: const Color(0xFF10B981),
        ),
        title: const Text('解析后自动下载', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '解析视频成功后直接开始下载任务',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Switch.adaptive(
          value: controller.autoDownload.value,
          activeTrackColor: AppColors.primary,
          onChanged: (val) => controller.setAutoDownload(val),
        ),
        onTap: () => controller.setAutoDownload(!controller.autoDownload.value),
      );
    });
  }

  Widget _buildNotificationTile(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: Icons.notifications_active_outlined,
          color: const Color(0xFF6366F1),
        ),
        title: const Text('下载完成通知', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '在系统通知栏实时显示任务完成提醒',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Switch.adaptive(
          value: controller.showNotification.value,
          activeTrackColor: AppColors.primary,
          onChanged: (val) => controller.setShowNotification(val),
        ),
        onTap: () => controller.setShowNotification(!controller.showNotification.value),
      );
    });
  }

  // ==================== 3. 视频与格式设置项 ====================

  Widget _buildVideoQualityTile(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: Icons.high_quality_rounded,
          color: const Color(0xFFEC4899),
        ),
        title: const Text('默认视频清晰度', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${controller.defaultVideoQuality.value}P',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
        onTap: () => _showQualitySelector(context),
      );
    });
  }

  void _showQualitySelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '选择默认视频清晰度',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildQualityOption(1080, '1080P 超清 (推荐)'),
            _buildQualityOption(720, '720P 高清'),
            _buildQualityOption(480, '480P 标清'),
            _buildQualityOption(360, '360P 流畅'),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildQualityOption(int quality, String label) {
    return Obx(() {
      final isSelected = controller.defaultVideoQuality.value == quality;

      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            : null,
        onTap: () {
          controller.setDefaultVideoQuality(quality);
          Get.back();
        },
      );
    });
  }

  Widget _buildVideoFormatTile(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: Icons.movie_filter_rounded,
          color: const Color(0xFF06B6D4),
        ),
        title: const Text('默认存储格式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          controller.defaultVideoFormat.value.toUpperCase(),
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
        onTap: () => _showFormatSelector(context),
      );
    });
  }

  void _showFormatSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '选择默认视频格式',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFormatOption('mp4', 'MP4 (最兼容)'),
            _buildFormatOption('mkv', 'MKV (多音轨/字幕支持)'),
            _buildFormatOption('mp3', 'MP3 (仅音频提取)'),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildFormatOption(String format, String label) {
    return Obx(() {
      final isSelected = controller.defaultVideoFormat.value == format;

      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            : null,
        onTap: () {
          controller.setDefaultVideoFormat(format);
          Get.back();
        },
      );
    });
  }

  Widget _buildVideoConvertTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      leading: _buildIconBadge(
        icon: Icons.transform_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      title: const Text('视频格式转换工具', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '快速调用本地转码工具，支持视频/音频转换与重封装',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
      onTap: () => Get.toNamed(Routes.CONVERT),
    );
  }

  // ==================== 4. 存储与缓存设置项 ====================

  Widget _buildCacheTile(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: _buildIconBadge(
          icon: Icons.cleaning_services_rounded,
          color: const Color(0xFFF97316),
        ),
        title: const Text('清除临时缓存', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '当前已占用缓存: ${controller.cacheSize.value}',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
        onTap: () => _showClearCacheConfirmation(context),
      );
    });
  }

  void _showClearCacheConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('确认清除缓存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          '清除缓存将释放网络临时文件与解析快照，不会删除您已下载的本地视频文件。',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定清除'),
          ),
        ],
      ),
    );
  }

  // ==================== 5. 关于与条款 ====================

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      leading: _buildIconBadge(
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF64748B),
      ),
      title: const Text('关于 TubeSavely', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '版本信息与开发者说明',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
      onTap: () => controller.showAboutApp(),
    );
  }

  Widget _buildPrivacyTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      leading: _buildIconBadge(
        icon: Icons.privacy_tip_outlined,
        color: const Color(0xFF64748B),
      ),
      title: const Text('隐私保护政策', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
      onTap: () => controller.showPrivacyPolicy(),
    );
  }

  Widget _buildTermsTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      leading: _buildIconBadge(
        icon: Icons.description_outlined,
        color: const Color(0xFF64748B),
      ),
      title: const Text('用户使用协议', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
      onTap: () => controller.showTermsOfService(),
    );
  }
}
