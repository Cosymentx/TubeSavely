import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';

/// FFmpeg 安装状态
enum FFmpegInstallStatus {
  notInstalled, // 未安装
  downloading, // 下载中
  extracting, // 解压中
  installing, // 安装/授权中
  installed, // 已安装
  failed, // 安装失败
}

/// FFmpeg 安装进度回调
typedef FFmpegInstallProgressCallback = void Function(
  FFmpegInstallStatus status,
  double progress,
  String message,
);

/// 跨平台 FFmpeg 自动安装与环境管理器
///
/// 具备 macOS, Windows, Linux 自动下载预编译静态免安装包并在 App 沙盒中解压授权能力
class FFmpegInstallerService {
  static final FFmpegInstallerService _instance = FFmpegInstallerService._internal();

  factory FFmpegInstallerService() => _instance;

  FFmpegInstallerService._internal();

  // 各平台官方/成熟开源静态发布源
  static const String _winDownloadUrl =
      'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip';

  // macOS 官方静态独立可执行文件 ZIP
  static const String _macFfmpegUrl = 'https://evermeet.cx/ffmpeg/getrelease/zip';
  static const String _macFfprobeUrl = 'https://evermeet.cx/ffmpeg/getrelease/ffprobe/zip';

  // Linux x64 静态包
  static const String _linuxDownloadUrl =
      'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz';

  String? _customBinDir;
  String? _cachedFfmpegPath;
  String? _cachedFfprobePath;

  FFmpegInstallStatus _status = FFmpegInstallStatus.notInstalled;
  double _progress = 0.0;
  String _message = '';

  FFmpegInstallStatus get status => _status;
  double get progress => _progress;
  String get message => _message;

  /// 获取 App 专属的 FFmpeg 沙盒存放目录
  Future<String> getAppFFmpegBinDir() async {
    if (_customBinDir != null) return _customBinDir!;

    Directory baseDir;
    if (Platform.isMacOS || Platform.isLinux) {
      baseDir = await getApplicationSupportDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final dir = Directory(p.join(baseDir.path, 'ffmpeg_bin'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _customBinDir = dir.path;
    return _customBinDir!;
  }

  /// 检查 FFmpeg 是否已安装或已配置沙盒运行环境
  Future<bool> isFFmpegInstalled() async {
    final path = await getFFmpegPath();
    return path != null && path.isNotEmpty;
  }

  /// 获取可执行的 FFmpeg 完整路径
  Future<String?> getFFmpegPath() async {
    if (_cachedFfmpegPath != null && await File(_cachedFfmpegPath!).exists()) {
      return _cachedFfmpegPath;
    }

    try {
      // 1. 优先检测系统全局 PATH
      if (Platform.isWindows) {
        final result = await Process.run('where', ['ffmpeg']);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          _cachedFfmpegPath = result.stdout.toString().trim().split('\r\n').first;
          return _cachedFfmpegPath;
        }
      } else {
        final result = await Process.run('which', ['ffmpeg']);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          _cachedFfmpegPath = result.stdout.toString().trim().split('\n').first;
          return _cachedFfmpegPath;
        }
      }

      // 2. 检测 App 专属沙盒目录
      final binDir = await getAppFFmpegBinDir();
      final appFFmpegFile = File(p.join(binDir, Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg'));
      if (await appFFmpegFile.exists()) {
        _cachedFfmpegPath = appFFmpegFile.path;
        return _cachedFfmpegPath;
      }

      // 3. 常见系统安装路径探查
      final commonPaths = <String>[];
      if (Platform.isMacOS) {
        commonPaths.addAll([
          '/opt/homebrew/bin/ffmpeg',
          '/usr/local/bin/ffmpeg',
          '/usr/bin/ffmpeg',
        ]);
      } else if (Platform.isWindows) {
        commonPaths.addAll([
          'C:\\ffmpeg\\bin\\ffmpeg.exe',
          'C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe',
          'C:\\Program Files (x86)\\ffmpeg\\bin\\ffmpeg.exe',
          'D:\\ffmpeg\\bin\\ffmpeg.exe',
        ]);
      } else if (Platform.isLinux) {
        commonPaths.addAll([
          '/usr/bin/ffmpeg',
          '/usr/local/bin/ffmpeg',
          '/snap/bin/ffmpeg',
        ]);
      }

      for (final pth in commonPaths) {
        if (await File(pth).exists()) {
          _cachedFfmpegPath = pth;
          return _cachedFfmpegPath;
        }
      }
    } catch (e) {
      Logger.w('Error checking FFmpeg path: $e');
    }

    return null;
  }

  /// 获取可执行的 FFprobe 完整路径
  Future<String?> getFFprobePath() async {
    if (_cachedFfprobePath != null && await File(_cachedFfprobePath!).exists()) {
      return _cachedFfprobePath;
    }

    try {
      if (Platform.isWindows) {
        final result = await Process.run('where', ['ffprobe']);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          _cachedFfprobePath = result.stdout.toString().trim().split('\r\n').first;
          return _cachedFfprobePath;
        }
      } else {
        final result = await Process.run('which', ['ffprobe']);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          _cachedFfprobePath = result.stdout.toString().trim().split('\n').first;
          return _cachedFfprobePath;
        }
      }

      final binDir = await getAppFFmpegBinDir();
      final appFFprobeFile = File(p.join(binDir, Platform.isWindows ? 'ffprobe.exe' : 'ffprobe'));
      if (await appFFprobeFile.exists()) {
        _cachedFfprobePath = appFFprobeFile.path;
        return _cachedFfprobePath;
      }

      final commonPaths = <String>[];
      if (Platform.isMacOS) {
        commonPaths.addAll([
          '/opt/homebrew/bin/ffprobe',
          '/usr/local/bin/ffprobe',
          '/usr/bin/ffprobe',
        ]);
      } else if (Platform.isWindows) {
        commonPaths.addAll([
          'C:\\ffmpeg\\bin\\ffprobe.exe',
          'C:\\Program Files\\ffmpeg\\bin\\ffprobe.exe',
          'D:\\ffmpeg\\bin\\ffprobe.exe',
        ]);
      } else if (Platform.isLinux) {
        commonPaths.addAll([
          '/usr/bin/ffprobe',
          '/usr/local/bin/ffprobe',
        ]);
      }

      for (final pth in commonPaths) {
        if (await File(pth).exists()) {
          _cachedFfprobePath = pth;
          return _cachedFfprobePath;
        }
      }
    } catch (e) {
      Logger.w('Error checking FFprobe path: $e');
    }

    return null;
  }

  /// 执行自动跨平台安装
  Future<bool> installFFmpeg({FFmpegInstallProgressCallback? onProgress}) async {
    _status = FFmpegInstallStatus.downloading;
    _progress = 0.0;
    _message = 'ffmpeg_downloading'.tr;
    onProgress?.call(_status, _progress, _message);

    try {
      final binDir = await getAppFFmpegBinDir();
      final tempDir = await getTemporaryDirectory();

      if (Platform.isWindows) {
        await _installForWindows(binDir, tempDir, onProgress);
      } else if (Platform.isMacOS) {
        await _installForMacOS(binDir, tempDir, onProgress);
      } else if (Platform.isLinux) {
        await _installForLinux(binDir, tempDir, onProgress);
      } else {
        throw UnsupportedError('当前平台暂不支持自动安装 FFmpeg');
      }

      // 验证生成的文件
      _status = FFmpegInstallStatus.installing;
      _message = 'ffmpeg_setting_up'.tr;
      onProgress?.call(_status, 0.95, _message);

      // 非 Windows 赋予可执行权限
      if (!Platform.isWindows) {
        final ffmpegPath = p.join(binDir, 'ffmpeg');
        final ffprobePath = p.join(binDir, 'ffprobe');
        await Process.run('chmod', ['+x', ffmpegPath]);
        if (await File(ffprobePath).exists()) {
          await Process.run('chmod', ['+x', ffprobePath]);
        }
      }

      // 清除缓存并重新探查
      _cachedFfmpegPath = null;
      _cachedFfprobePath = null;
      final finalPath = await getFFmpegPath();

      if (finalPath != null && await File(finalPath).exists()) {
        _status = FFmpegInstallStatus.installed;
        _progress = 1.0;
        _message = 'ffmpeg_installed_success'.tr;
        onProgress?.call(_status, _progress, _message);
        return true;
      } else {
        throw Exception('安装后未检测到有效可执行文件');
      }
    } catch (e) {
      Logger.e('Error during FFmpeg auto installation: $e');
      _status = FFmpegInstallStatus.failed;
      _progress = 0.0;
      _message = 'ffmpeg_install_failed'.tr;
      onProgress?.call(_status, _progress, _message);
      return false;
    }
  }

  /// macOS 安装逻辑 (下载官方静态包解压至沙盒)
  Future<void> _installForMacOS(
    String binDir,
    Directory tempDir,
    FFmpegInstallProgressCallback? onProgress,
  ) async {
    // 1. 下载 ffmpeg zip
    final ffmpegZipPath = p.join(tempDir.path, 'ffmpeg_mac.zip');
    await _downloadFile(
      _macFfmpegUrl,
      ffmpegZipPath,
      progressWeight: 0.5,
      progressBase: 0.0,
      onProgress: onProgress,
    );

    // 2. 解压 ffmpeg
    _status = FFmpegInstallStatus.extracting;
    _message = 'ffmpeg_extracting'.tr;
    onProgress?.call(_status, 0.55, _message);
    await _unzipSingleFile(ffmpegZipPath, binDir, 'ffmpeg');

    // 3. 下载 ffprobe zip
    final ffprobeZipPath = p.join(tempDir.path, 'ffprobe_mac.zip');
    await _downloadFile(
      _macFfprobeUrl,
      ffprobeZipPath,
      progressWeight: 0.35,
      progressBase: 0.6,
      onProgress: onProgress,
    );

    // 4. 解压 ffprobe
    await _unzipSingleFile(ffprobeZipPath, binDir, 'ffprobe');
  }

  /// Windows 安装逻辑
  Future<void> _installForWindows(
    String binDir,
    Directory tempDir,
    FFmpegInstallProgressCallback? onProgress,
  ) async {
    final zipPath = p.join(tempDir.path, 'ffmpeg_win.zip');
    await _downloadFile(
      _winDownloadUrl,
      zipPath,
      progressWeight: 0.7,
      progressBase: 0.0,
      onProgress: onProgress,
    );

    _status = FFmpegInstallStatus.extracting;
    _message = 'ffmpeg_extracting'.tr;
    onProgress?.call(_status, 0.75, _message);

    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      if (file.isFile && (file.name.endsWith('ffmpeg.exe') || file.name.endsWith('ffprobe.exe'))) {
        final outName = file.name.split('/').last;
        final targetFile = File(p.join(binDir, outName));
        await targetFile.writeAsBytes(file.content as List<int>);
      }
    }
  }

  /// Linux 安装逻辑 (提取 static tar.xz 或通过系统包管理器安装)
  Future<void> _installForLinux(
    String binDir,
    Directory tempDir,
    FFmpegInstallProgressCallback? onProgress,
  ) async {
    // Linux 环境尝试使用 apt-get 安装或下载预编译静态包
    try {
      final aptRes = await Process.run('apt-get', ['-v']);
      if (aptRes.exitCode == 0) {
        _status = FFmpegInstallStatus.installing;
        _message = '正在通过系统包管理器安装...';
        onProgress?.call(_status, 0.5, _message);
        await Process.run('pkexec', ['apt-get', 'install', '-y', 'ffmpeg']);
      }
    } catch (_) {}
  }

  /// 通用流式下载器并附带加权进度
  Future<void> _downloadFile(
    String url,
    String savePath, {
    required double progressWeight,
    required double progressBase,
    FFmpegInstallProgressCallback? onProgress,
  }) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);

    final contentLength = response.contentLength ?? 0;
    int receivedBytes = 0;

    final file = File(savePath);
    final sink = file.openWrite();

    await response.stream.listen((chunk) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (contentLength > 0) {
        final currentPart = (receivedBytes / contentLength).clamp(0.0, 1.0);
        _progress = progressBase + currentPart * progressWeight;
        final pct = (_progress * 100).toStringAsFixed(1);
        _message = 'ffmpeg_download_progress'.trParams({'progress': pct});
        onProgress?.call(_status, _progress, _message);
      }
    }).asFuture();

    await sink.close();
  }

  /// 解压单文件 ZIP
  Future<void> _unzipSingleFile(String zipPath, String destDir, String expectedPrefix) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      if (file.isFile && file.name.contains(expectedPrefix)) {
        final outName = file.name.split('/').last;
        final targetFile = File(p.join(destDir, outName));
        await targetFile.writeAsBytes(file.content as List<int>);
      }
    }
  }
}
