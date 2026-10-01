import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tubesavely/app/services/video_processing/ffmpeg_installer_service.dart';
import 'package:tubesavely/app/theme/app_colors.dart';
import 'package:tubesavely/app/utils/logger.dart';
import 'package:tubesavely/app/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// FFmpeg安装对话框
///
/// 用于提示用户安装FFmpeg
class FFmpegInstallDialog extends StatefulWidget {
  const FFmpegInstallDialog({Key? key}) : super(key: key);

  @override
  State<FFmpegInstallDialog> createState() => _FFmpegInstallDialogState();
}

class _FFmpegInstallDialogState extends State<FFmpegInstallDialog> {
  // FFmpeg安装器服务
  final FFmpegInstallerService _installerService = FFmpegInstallerService();
  
  // 安装状态
  FFmpegInstallStatus _status = FFmpegInstallStatus.notInstalled;
  
  // 安装进度
  double _progress = 0.0;
  
  // 安装消息
  String _message = '';
  
  // 是否正在安装
  bool _isInstalling = false;
  
  @override
  void initState() {
    super.initState();
    _checkFFmpegInstallation();
  }
  
  /// 检查FFmpeg是否已安装
  Future<void> _checkFFmpegInstallation() async {
    final isInstalled = await _installerService.isFFmpegInstalled();
    
    if (isInstalled) {
      setState(() {
        _status = FFmpegInstallStatus.installed;
        _progress = 1.0;
        _message = 'FFmpeg已安装';
      });
    } else {
      setState(() {
        _status = FFmpegInstallStatus.notInstalled;
        _progress = 0.0;
        _message = 'FFmpeg未安装';
      });
    }
  }
  
  /// 安装FFmpeg
  Future<void> _installFFmpeg() async {
    if (_isInstalling) return;
    
    setState(() {
      _isInstalling = true;
    });
    
    try {
      final success = await _installerService.installFFmpeg(
        onProgress: (status, progress, message) {
          setState(() {
            _status = status;
            _progress = progress;
            _message = message;
          });
        },
      );
      
      if (success) {
        Utils.showSnackbar('成功', 'FFmpeg安装成功');
        
        // 关闭对话框并返回成功
        Get.back(result: true);
      } else {
        Utils.showSnackbar('错误', 'FFmpeg安装失败', isError: true);
        
        setState(() {
          _isInstalling = false;
          _status = FFmpegInstallStatus.failed;
          _message = 'FFmpeg安装失败';
        });
      }
    } catch (e) {
      Logger.e('Error installing FFmpeg: $e');
      Utils.showSnackbar('错误', '安装FFmpeg时出错: $e', isError: true);
      
      setState(() {
        _isInstalling = false;
        _status = FFmpegInstallStatus.failed;
        _message = '安装出错: $e';
      });
    }
  }
  
  /// 打开FFmpeg官网
  Future<void> _openFFmpegWebsite() async {
    const url = 'https://ffmpeg.org/download.html';
    
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        Utils.showSnackbar('错误', '无法打开网页: $url', isError: true);
      }
    } catch (e) {
      Logger.e('Error opening FFmpeg website: $e');
      Utils.showSnackbar('错误', '打开网页时出错: $e', isError: true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('安装FFmpeg'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FFmpeg是一个用于处理视频和音频的开源工具，用于视频下载和转换。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '您的系统中未安装FFmpeg，需要安装才能使用视频下载和转换功能。',
              style: TextStyle(fontSize: 14),
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
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('取消'),
        ),
        if (_status == FFmpegInstallStatus.installed)
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('确定'),
          ),
      ],
    );
  }
  
  /// 构建安装选项
  Widget _buildInstallOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '您可以选择以下安装方式：',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.download),
          title: const Text('自动安装'),
          subtitle: const Text('应用将自动下载并安装FFmpeg'),
          onTap: _installFFmpeg,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.language),
          title: const Text('手动安装'),
          subtitle: const Text('访问FFmpeg官网下载并安装'),
          onTap: _openFFmpegWebsite,
        ),
      ],
    );
  }
  
  /// 构建安装进度
  Widget _buildInstallProgress() {
    String statusText;
    IconData statusIcon;
    
    switch (_status) {
      case FFmpegInstallStatus.downloading:
        statusText = '下载中';
        statusIcon = Icons.download;
        break;
      case FFmpegInstallStatus.extracting:
        statusText = '解压中';
        statusIcon = Icons.folder_zip;
        break;
      case FFmpegInstallStatus.installing:
        statusText = '安装中';
        statusIcon = Icons.settings;
        break;
      case FFmpegInstallStatus.installed:
        statusText = '已安装';
        statusIcon = Icons.check_circle;
        break;
      case FFmpegInstallStatus.failed:
        statusText = '安装失败';
        statusIcon = Icons.error;
        break;
      default:
        statusText = '准备中';
        statusIcon = Icons.hourglass_empty;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(statusIcon, color: _status == FFmpegInstallStatus.failed ? Colors.red : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _status == FFmpegInstallStatus.failed ? Colors.red : AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _status == FFmpegInstallStatus.failed ? Colors.red : AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(_message),
        if (_status == FFmpegInstallStatus.failed)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: _installFFmpeg,
              child: const Text('重试'),
            ),
          ),
      ],
    );
  }
}
