import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/providers/storage_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/constants.dart';
import '../widgets/desktop_dialog_wrapper.dart';
import 'desktop_about_dialog.dart';

/// 现代化桌面端设置弹窗 (UI/UX Pro Max 精密桌面规范)
class DesktopSettingDialog extends StatefulWidget {
  const DesktopSettingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => const DesktopDialogWrapper(
        width: 520,
        child: DesktopSettingDialog(),
      ),
    );
  }

  @override
  State<DesktopSettingDialog> createState() => _DesktopSettingDialogState();
}

class _DesktopSettingDialogState extends State<DesktopSettingDialog> {
  final StorageProvider _storage = Get.find<StorageProvider>();

  late ThemeMode _themeMode;
  late String _language;
  String _cacheDir = '';
  bool _autoRecode = false;
  String _downloadQuality = '720P';
  bool _mergeAudio = true;
  String _convertFormat = 'MP4';

  final List<String> _languages = ['简体中文', 'English', '日本語', '한국어'];
  final List<String> _qualities = ['480P', '720P', '1080P', '2K', '4K'];
  final List<String> _formats = ['MP4', 'MKV', 'MOV', 'AVI', 'WEBM', 'MP3', 'AAC', 'WAV', 'FLAC'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _themeMode = _storage.getThemeMode() ?? ThemeMode.system;

    final locale = Get.locale?.languageCode;
    if (locale == 'zh') {
      _language = '简体中文';
    } else if (locale == 'ja') {
      _language = '日本語';
    } else if (locale == 'ko') {
      _language = '한국어';
    } else {
      _language = 'English';
    }

    final savedDir = _storage.getDownloadPath();
    if (savedDir.isNotEmpty && await Directory(savedDir).exists()) {
      _cacheDir = savedDir;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      _cacheDir = docDir.path;
      _storage.setDownloadPath(_cacheDir);
    }

    if (mounted) setState(() {});
  }

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    if (mode == ThemeMode.dark) {
      Get.changeThemeMode(ThemeMode.dark);
      _storage.setThemeModeName('dark');
    } else if (mode == ThemeMode.light) {
      Get.changeThemeMode(ThemeMode.light);
      _storage.setThemeModeName('light');
    } else {
      Get.changeThemeMode(ThemeMode.system);
      _storage.setThemeModeName('system');
    }
  }

  void _changeLanguage(String lang) {
    setState(() {
      _language = lang;
    });
    Locale targetLocale;
    switch (lang) {
      case '简体中文':
        targetLocale = const Locale('zh', 'CN');
        break;
      case '日本語':
        targetLocale = const Locale('ja', 'JP');
        break;
      case '한국어':
        targetLocale = const Locale('ko', 'KR');
        break;
      default:
        targetLocale = const Locale('en', 'US');
        break;
    }
    Get.updateLocale(targetLocale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.settings_suggest_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'general_settings'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1. 主题选择 (分段胶囊按钮)
        _buildSettingRow(
          title: 'setting_theme'.tr,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeSegment('setting_theme_light'.tr, Icons.light_mode_rounded, ThemeMode.light),
                _buildThemeSegment('setting_theme_dark'.tr, Icons.dark_mode_rounded, ThemeMode.dark),
                _buildThemeSegment('setting_theme_system'.tr, Icons.devices_rounded, ThemeMode.system),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. 语言选择
        _buildSettingRow(
          title: 'setting_language'.tr,
          child: _buildDropdown(
            value: _language,
            items: _languages,
            onChanged: (val) {
              if (val != null) _changeLanguage(val);
            },
          ),
        ),

        _buildDivider(),
        Text(
          'video_settings'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 3. 缓存/存储目录
        _buildSettingRow(
          title: 'setting_cache_dir'.tr,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: Text(
                    _cacheDir,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.platform.getDirectoryPath(
                      initialDirectory: _cacheDir,
                      lockParentWindow: true,
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _cacheDir = result;
                      });
                      _storage.setDownloadPath(result);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.folder_open_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 4. 自动重编码
        _buildSettingRow(
          title: 'setting_recode'.tr,
          child: Switch.adaptive(
            value: _autoRecode,
            activeTrackColor: AppColors.primary,
            onChanged: (val) => setState(() => _autoRecode = val),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 5. 默认下载分辨率
        _buildSettingRow(
          title: 'setting_download_quality'.tr,
          child: _buildDropdown(
            value: _downloadQuality,
            items: _qualities,
            onChanged: (val) {
              if (val != null) setState(() => _downloadQuality = val);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 6. 自动合并音频
        _buildSettingRow(
          title: 'setting_merge_audio'.tr,
          child: Switch.adaptive(
            value: _mergeAudio,
            activeTrackColor: AppColors.primary,
            onChanged: (val) => setState(() => _mergeAudio = val),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 7. 默认转换格式
        _buildSettingRow(
          title: 'setting_convert_format'.tr,
          child: _buildDropdown(
            value: _convertFormat,
            items: _formats,
            onChanged: (val) {
              if (val != null) setState(() => _convertFormat = val);
            },
          ),
        ),

        _buildDivider(),
        Text(
          'other_settings'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        _buildLinkItem('visit_website'.tr, Icons.language_rounded, () {
          launchUrl(Uri.parse(Constants.WEB_URL), mode: LaunchMode.externalApplication);
        }),
        _buildLinkItem('privacy_policy'.tr, Icons.privacy_tip_outlined, () {
          launchUrl(Uri.parse(Constants.PRIVACY_URL), mode: LaunchMode.externalApplication);
        }),
        _buildLinkItem('terms_of_service'.tr, Icons.description_outlined, () {
          launchUrl(Uri.parse(Constants.TERMS_URL), mode: LaunchMode.externalApplication);
        }),
        _buildLinkItem('about_us'.tr, Icons.info_outline_rounded, () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.4),
            builder: (context) => const DesktopDialogWrapper(
              width: 380,
              child: DesktopAboutDialog(),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  Widget _buildThemeSegment(String label, IconData icon, ThemeMode mode) {
    final isSelected = _themeMode == mode;
    return InkWell(
      onTap: () => _changeTheme(mode),
      borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildSettingRow({required String title, required Widget child}) {
    return SizedBox(
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildLinkItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        value: items.contains(value) ? value : items.first,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            color: theme.colorScheme.surface,
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
            boxShadow: AppSpacing.shadowMd,
          ),
        ),
      ),
    );
  }
}
