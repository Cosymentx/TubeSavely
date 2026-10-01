import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:tubesavely/app/utils/logger.dart';
import 'package:tubesavely/app/utils/utils.dart';

/// FFmpeg安装状态
enum FFmpegInstallStatus {
  notInstalled,    // 未安装
  downloading,     // 下载中
  extracting,      // 解压中
  installing,      // 安装中
  installed,       // 已安装
  failed,          // 安装失败
}

/// FFmpeg安装进度回调
typedef FFmpegInstallProgressCallback = void Function(FFmpegInstallStatus status, double progress, String message);

/// FFmpeg安装器服务
///
/// 用于在Windows平台上一键安装FFmpeg
class FFmpegInstallerService {
  // 单例实现
  static final FFmpegInstallerService _instance = FFmpegInstallerService._internal();
  
  factory FFmpegInstallerService() => _instance;
  
  FFmpegInstallerService._internal();
  
  // FFmpeg下载URL
  static const String _ffmpegDownloadUrl = 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip';
  
  // 安装目录
  String? _installDir;
  
  // 当前安装状态
  FFmpegInstallStatus _status = FFmpegInstallStatus.notInstalled;
  
  // 安装进度
  double _progress = 0.0;
  
  // 安装消息
  String _message = '';
  
  // 获取安装状态
  FFmpegInstallStatus get status => _status;
  
  // 获取安装进度
  double get progress => _progress;
  
  // 获取安装消息
  String get message => _message;
  
  /// 检查FFmpeg是否已安装
  ///
  /// 返回是否已安装
  Future<bool> isFFmpegInstalled() async {
    try {
      // 尝试在系统路径中查找FFmpeg
      final result = await Process.run('where', ['ffmpeg']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return true;
      }
      
      // 尝试在常见安装位置查找FFmpeg
      final List<String> commonPaths = [
        'C:\\ffmpeg\\bin\\ffmpeg.exe',
        'C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe',
        'C:\\Program Files (x86)\\ffmpeg\\bin\\ffmpeg.exe',
        'D:\\ffmpeg\\bin\\ffmpeg.exe',
      ];
      
      for (final path in commonPaths) {
        final file = File(path);
        if (await file.exists()) {
          return true;
        }
      }
      
      // 检查应用程序目录中是否已安装FFmpeg
      final appDir = await getApplicationDocumentsDirectory();
      final ffmpegPath = '${appDir.path}\\ffmpeg\\bin\\ffmpeg.exe';
      final ffmpegFile = File(ffmpegPath);
      if (await ffmpegFile.exists()) {
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.e('Error checking FFmpeg installation: $e');
      return false;
    }
  }
  
  /// 安装FFmpeg
  ///
  /// [onProgress] 安装进度回调
  /// 返回是否安装成功
  Future<bool> installFFmpeg({FFmpegInstallProgressCallback? onProgress}) async {
    try {
      // 更新状态
      _status = FFmpegInstallStatus.downloading;
      _progress = 0.0;
      _message = '正在下载FFmpeg...';
      onProgress?.call(_status, _progress, _message);
      
      // 获取应用程序目录
      final appDir = await getApplicationDocumentsDirectory();
      _installDir = '${appDir.path}\\ffmpeg';
      
      // 创建临时目录
      final tempDir = await getTemporaryDirectory();
      final zipFilePath = '${tempDir.path}\\ffmpeg.zip';
      
      // 下载FFmpeg
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_ffmpegDownloadUrl));
      final response = await client.send(request);
      
      final contentLength = response.contentLength ?? 0;
      int receivedBytes = 0;
      
      final file = File(zipFilePath);
      final sink = file.openWrite();
      
      await response.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        
        if (contentLength > 0) {
          _progress = receivedBytes / contentLength;
          _message = '下载中: ${(_progress * 100).toStringAsFixed(1)}%';
          onProgress?.call(_status, _progress, _message);
        }
      }).asFuture();
      
      await sink.close();
      
      // 更新状态
      _status = FFmpegInstallStatus.extracting;
      _progress = 0.0;
      _message = '正在解压FFmpeg...';
      onProgress?.call(_status, _progress, _message);
      
      // 解压FFmpeg
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // 创建安装目录
      final installDir = Directory(_installDir!);
      if (await installDir.exists()) {
        await installDir.delete(recursive: true);
      }
      await installDir.create(recursive: true);
      
      // 解压文件
      for (int i = 0; i < archive.length; i++) {
        final file = archive[i];
        final filename = file.name;
        
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File('${_installDir!}\\$filename');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          final dir = Directory('${_installDir!}\\$filename');
          await dir.create(recursive: true);
        }
        
        _progress = i / archive.length;
        _message = '解压中: ${(_progress * 100).toStringAsFixed(1)}%';
        onProgress?.call(_status, _progress, _message);
      }
      
      // 更新状态
      _status = FFmpegInstallStatus.installing;
      _progress = 0.0;
      _message = '正在配置FFmpeg...';
      onProgress?.call(_status, _progress, _message);
      
      // 添加到系统环境变量
      final binDir = '${_installDir!}\\bin';
      
      // 检查FFmpeg是否可用
      final ffmpegPath = '$binDir\\ffmpeg.exe';
      final ffmpegFile = File(ffmpegPath);
      if (!await ffmpegFile.exists()) {
        throw Exception('FFmpeg executable not found after extraction');
      }
      
      // 检查FFprobe是否可用
      final ffprobePath = '$binDir\\ffprobe.exe';
      final ffprobeFile = File(ffprobePath);
      if (!await ffprobeFile.exists()) {
        throw Exception('FFprobe executable not found after extraction');
      }
      
      // 获取FFmpeg版本信息
      final versionResult = await Process.run(ffmpegPath, ['-version']);
      if (versionResult.exitCode != 0) {
        throw Exception('Failed to get FFmpeg version');
      }
      
      // 更新状态
      _status = FFmpegInstallStatus.installed;
      _progress = 1.0;
      _message = 'FFmpeg安装成功';
      onProgress?.call(_status, _progress, _message);
      
      // 删除临时文件
      await file.delete();
      
      return true;
    } catch (e) {
      Logger.e('Error installing FFmpeg: $e');
      
      // 更新状态
      _status = FFmpegInstallStatus.failed;
      _progress = 0.0;
      _message = '安装失败: $e';
      onProgress?.call(_status, _progress, _message);
      
      return false;
    }
  }
  
  /// 获取已安装的FFmpeg路径
  ///
  /// 返回FFmpeg可执行文件路径，未安装返回null
  Future<String?> getFFmpegPath() async {
    try {
      // 尝试在系统路径中查找FFmpeg
      final result = await Process.run('where', ['ffmpeg']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return result.stdout.toString().trim().split('\n').first;
      }
      
      // 尝试在常见安装位置查找FFmpeg
      final List<String> commonPaths = [
        'C:\\ffmpeg\\bin\\ffmpeg.exe',
        'C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe',
        'C:\\Program Files (x86)\\ffmpeg\\bin\\ffmpeg.exe',
        'D:\\ffmpeg\\bin\\ffmpeg.exe',
      ];
      
      for (final path in commonPaths) {
        final file = File(path);
        if (await file.exists()) {
          return path;
        }
      }
      
      // 检查应用程序目录中是否已安装FFmpeg
      final appDir = await getApplicationDocumentsDirectory();
      final ffmpegPath = '${appDir.path}\\ffmpeg\\bin\\ffmpeg.exe';
      final ffmpegFile = File(ffmpegPath);
      if (await ffmpegFile.exists()) {
        return ffmpegPath;
      }
      
      return null;
    } catch (e) {
      Logger.e('Error getting FFmpeg path: $e');
      return null;
    }
  }
  
  /// 获取已安装的FFprobe路径
  ///
  /// 返回FFprobe可执行文件路径，未安装返回null
  Future<String?> getFFprobePath() async {
    try {
      // 尝试在系统路径中查找FFprobe
      final result = await Process.run('where', ['ffprobe']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return result.stdout.toString().trim().split('\n').first;
      }
      
      // 尝试在常见安装位置查找FFprobe
      final List<String> commonPaths = [
        'C:\\ffmpeg\\bin\\ffprobe.exe',
        'C:\\Program Files\\ffmpeg\\bin\\ffprobe.exe',
        'C:\\Program Files (x86)\\ffmpeg\\bin\\ffprobe.exe',
        'D:\\ffmpeg\\bin\\ffprobe.exe',
      ];
      
      for (final path in commonPaths) {
        final file = File(path);
        if (await file.exists()) {
          return path;
        }
      }
      
      // 检查应用程序目录中是否已安装FFprobe
      final appDir = await getApplicationDocumentsDirectory();
      final ffprobePath = '${appDir.path}\\ffmpeg\\bin\\ffprobe.exe';
      final ffprobeFile = File(ffprobePath);
      if (await ffprobeFile.exists()) {
        return ffprobePath;
      }
      
      return null;
    } catch (e) {
      Logger.e('Error getting FFprobe path: $e');
      return null;
    }
  }
}
