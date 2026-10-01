import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../utils/constants.dart';
import '../widgets/desktop_dialog_wrapper.dart';
import 'desktop_about_dialog.dart';

/// 桌面端设置弹窗
class DesktopSettingDialog extends StatefulWidget {
  const DesktopSettingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => const DesktopDialogWrapper(
        width: 480,
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
    final primaryColor = theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('general_settings'.tr),
        const SizedBox(height: 8),

        // 主题设置
        _buildSettingRow(
          title: 'setting_theme'.tr,
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: primaryColor, width: 0.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeButton('setting_theme_light'.tr, ThemeMode.light),
                  Container(width: 0.8, color: primaryColor),
                  _buildThemeButton('setting_theme_dark'.tr, ThemeMode.dark),
                  Container(width: 0.8, color: primaryColor),
                  _buildThemeButton('setting_theme_system'.tr, ThemeMode.system),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 语言设置
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
        _buildSectionTitle('video_settings'.tr),
        const SizedBox(height: 8),

        // 缓存目录
        _buildSettingRow(
          title: 'setting_cache_dir'.tr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  _cacheDir,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                iconSize: 20,
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.folder_open,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                onPressed: () async {
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 自动重编码
        _buildSettingRow(
          title: 'setting_recode'.tr,
          child: Switch.adaptive(
            value: _autoRecode,
            activeColor: Colors.white,
            activeTrackColor: primaryColor,
            onChanged: (val) {
              setState(() {
                _autoRecode = val;
              });
            },
          ),
        ),
        const SizedBox(height: 10),

        // 默认下载分辨率
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
        const SizedBox(height: 10),

        // 自动合并音频
        _buildSettingRow(
          title: 'setting_merge_audio'.tr,
          child: Switch.adaptive(
            value: _mergeAudio,
            activeColor: Colors.white,
            activeTrackColor: primaryColor,
            onChanged: (val) {
              setState(() {
                _mergeAudio = val;
              });
            },
          ),
        ),
        const SizedBox(height: 10),

        // 默认转换格式
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
        _buildSectionTitle('other_settings'.tr),
        const SizedBox(height: 6),

        _buildLinkItem('visit_website'.tr, () {
          launchUrl(Uri.parse(Constants.WEB_URL), mode: LaunchMode.externalApplication);
        }),
        _buildLinkItem('privacy_policy'.tr, () {
          launchUrl(Uri.parse('https://tubesavely.com/privacy'), mode: LaunchMode.externalApplication);
        }),
        _buildLinkItem('about_us'.tr, () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.35),
            builder: (context) => const DesktopDialogWrapper(
              width: 380,
              child: DesktopAboutDialog(),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeButton(String label, ThemeMode mode) {
    final isSelected = _themeMode == mode;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => _changeTheme(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        color: isSelected ? primaryColor : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: Theme.of(context).dividerColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSettingRow({required String title, required Widget child}) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildLinkItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        value: items.contains(value) ? value : items.first,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        buttonStyleData: const ButtonStyleData(
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
