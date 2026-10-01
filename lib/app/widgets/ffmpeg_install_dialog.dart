import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/video_processing/ffmpeg_installer_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 跨平台通用的 FFmpeg 友好安装引导对话框
class FFmpegInstallDialog extends StatefulWidget {
  const FFmpegInstallDialog({Key? key}) : super(key: key);

  /// 快速弹出安装引导对话框
  static Future<bool> show() async {
    final result = await Get.dialog<bool>(
      const FFmpegInstallDialog(),
      barrierDismissible: false,
    );
    return result == true;
  }

  @override
  State<FFmpegInstallDialog> createState() => _FFmpegInstallDialogState();
}

class _FFmpegInstallDialogState extends State<FFmpegInstallDialog> {
  final FFmpegInstallerService _installerService = FFmpegInstallerService();

  FFmpegInstallStatus _status = FFmpegInstallStatus.notInstalled;
  double _progress = 0.0;
  String _message = '';
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _checkInstallation();
  }

  Future<void> _checkInstallation() async {
    final installed = await _installerService.isFFmpegInstalled();
    if (mounted) {
      setState(() {
        if (installed) {
          _status = FFmpegInstallStatus.installed;
          _progress = 1.0;
          _message = 'ffmpeg_installed_success'.tr;
        } else {
          _status = FFmpegInstallStatus.notInstalled;
          _progress = 0.0;
          _message = 'ffmpeg_not_found'.tr;
        }
      });
    }
  }

  Future<void> _installFFmpeg() async {
    if (_isInstalling) return;

    setState(() {
      _isInstalling = true;
    });

    final success = await _installerService.installFFmpeg(
      onProgress: (status, progress, message) {
        if (mounted) {
          setState(() {
            _status = status;
            _progress = progress;
            _message = message;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isInstalling = false;
      });

      if (success) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Get.back(result: true);
        });
      }
    }
  }

  Future<void> _openFFmpegWebsite() async {
    final uri = Uri.parse('https://ffmpeg.org/download.html');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      title: Row(
        children: [
          const Icon(Icons.video_settings, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ffmpeg_install_title'.tr,
              style: AppTextStyles.titleMedium,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ffmpeg_install_desc'.tr,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'ffmpeg_not_found'.tr,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (_status == FFmpegInstallStatus.notInstalled || _status == FFmpegInstallStatus.failed)
              _buildInstallOptions()
            else
              _buildInstallProgress(),
          ],
        ),
      ),
      actions: [
        if (!_isInstalling)
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
        if (_status == FFmpegInstallStatus.installed)
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('confirm'.tr),
          ),
      ],
    );
  }

  Widget _buildInstallOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ffmpeg_install_options'.tr,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              side: const BorderSide(color: AppColors.primaryLight25),
            ),
            tileColor: AppColors.primaryLight5,
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.flash_on, color: Colors.white, size: 20),
            ),
            title: Text('ffmpeg_auto_install'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('ffmpeg_auto_install_desc'.tr, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            onTap: _installFFmpeg,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.open_in_browser, color: Colors.white, size: 20),
            ),
            title: Text('ffmpeg_manual_install'.tr, style: AppTextStyles.bodyMedium),
            subtitle: Text('ffmpeg_manual_install_desc'.tr, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            onTap: _openFFmpegWebsite,
          ),
        ),
      ],
    );
  }

  Widget _buildInstallProgress() {
    Color statusColor = AppColors.primary;
    IconData statusIcon = Icons.downloading;

    if (_status == FFmpegInstallStatus.installed) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (_status == FFmpegInstallStatus.failed) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _message,
                  style: AppTextStyles.bodyMedium.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          if (_status == FFmpegInstallStatus.failed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _installFFmpeg,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text('retry'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
