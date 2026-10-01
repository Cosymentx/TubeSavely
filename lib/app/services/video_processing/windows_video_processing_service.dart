import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:tubesavely/app/utils/logger.dart';
import 'package:tubesavely/app/utils/utils.dart';
import 'package:tubesavely/app/widgets/ffmpeg_install_dialog.dart';
import 'video_processing_service.dart';

/// Windows平台的视频处理服务
///
/// 使用系统命令行调用FFmpeg或其他Windows兼容的工具处理视频
class WindowsVideoProcessingService implements VideoProcessingService {
  // 单例实现
  static final WindowsVideoProcessingService _instance =
      WindowsVideoProcessingService._internal();

  factory WindowsVideoProcessingService() => _instance;

  WindowsVideoProcessingService._internal();

  // FFmpeg可执行文件路径
  String? _ffmpegPath;
  String? _ffprobePath;

  // 检查FFmpeg是否已安装
  bool _isFFmpegInstalled = false;

  // FFmpeg版本信息
  String? _ffmpegVersion;

  // 初始化方法，检查FFmpeg是否已安装
  Future<void> _initialize() async {
    if (_ffmpegPath != null && _ffprobePath != null) {
      return;
    }

    try {
      // 尝试在系统路径中查找FFmpeg
      final result = await Process.run('where', ['ffmpeg']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        _ffmpegPath = result.stdout.toString().trim().split('\n').first;
        Logger.d('Found FFmpeg at: $_ffmpegPath');

        // 查找FFprobe
        final ffprobeResult = await Process.run('where', ['ffprobe']);
        if (ffprobeResult.exitCode == 0 &&
            ffprobeResult.stdout.toString().trim().isNotEmpty) {
          _ffprobePath =
              ffprobeResult.stdout.toString().trim().split('\n').first;
          Logger.d('Found FFprobe at: $_ffprobePath');

          // 获取FFmpeg版本信息
          final versionResult = await Process.run(_ffmpegPath!, ['-version']);
          if (versionResult.exitCode == 0) {
            final versionOutput = versionResult.stdout.toString();
            final versionMatch =
                RegExp(r'ffmpeg version (\S+)').firstMatch(versionOutput);
            if (versionMatch != null) {
              _ffmpegVersion = versionMatch.group(1);
              Logger.d('FFmpeg version: $_ffmpegVersion');
            }
          }

          _isFFmpegInstalled = true;
        }
      } else {
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
            _ffmpegPath = path;

            // 查找对应的FFprobe
            final ffprobePath = path.replaceAll('ffmpeg.exe', 'ffprobe.exe');
            final ffprobeFile = File(ffprobePath);
            if (await ffprobeFile.exists()) {
              _ffprobePath = ffprobePath;
              _isFFmpegInstalled = true;

              // 获取FFmpeg版本信息
              final versionResult =
                  await Process.run(_ffmpegPath!, ['-version']);
              if (versionResult.exitCode == 0) {
                final versionOutput = versionResult.stdout.toString();
                final versionMatch =
                    RegExp(r'ffmpeg version (\S+)').firstMatch(versionOutput);
                if (versionMatch != null) {
                  _ffmpegVersion = versionMatch.group(1);
                  Logger.d('FFmpeg version: $_ffmpegVersion');
                }
              }

              break;
            }
          }
        }

        if (!_isFFmpegInstalled) {
          Logger.w('FFmpeg not found in system path or common locations');
        }
      }
    } catch (e) {
      Logger.e('Error checking FFmpeg installation: $e');
      _isFFmpegInstalled = false;
    }
  }

  /// 获取FFmpeg版本信息
  String? getFFmpegVersion() {
    return _ffmpegVersion;
  }

  @override
  Future<Map<String, dynamic>?> getMediaInfo(String filePath) async {
    await _initialize();

    if (!_isFFmpegInstalled || _ffprobePath == null) {
      // 提示安装FFmpeg
      final installed = await promptInstallFFmpeg();
      if (!installed) {
        Utils.showSnackbar('提示', 'Windows平台需要安装FFmpeg才能获取媒体信息');
        return null;
      }
    }

    try {
      final result = await Process.run(_ffprobePath!, [
        '-v',
        'quiet',
        '-print_format',
        'json',
        '-show_format',
        '-show_streams',
        filePath
      ]);

      if (result.exitCode == 0) {
        final jsonStr = result.stdout.toString();
        final Map<String, dynamic> jsonData = jsonDecode(jsonStr);

        final Map<String, dynamic> mediaInfo = {};

        // 提取格式信息
        if (jsonData.containsKey('format')) {
          final format = jsonData['format'];
          mediaInfo['duration'] = format['duration'];
          mediaInfo['size'] = int.tryParse(format['size'] ?? '0') ?? 0;
          mediaInfo['bitrate'] = format['bit_rate'];
          mediaInfo['format'] = format['format_name'];
        }

        // 提取视频流信息
        if (jsonData.containsKey('streams')) {
          final streams = jsonData['streams'];
          for (final stream in streams) {
            if (stream['codec_type'] == 'video') {
              mediaInfo['width'] = stream['width'];
              mediaInfo['height'] = stream['height'];
              mediaInfo['codec'] = stream['codec_name'];
              mediaInfo['frameRate'] = stream['r_frame_rate'];
              break;
            }
          }
        }

        return mediaInfo;
      } else {
        Logger.e('FFprobe error: ${result.stderr}');
        return null;
      }
    } catch (e) {
      Logger.e('Error getting media information: $e');
      return null;
    }
  }

  @override
  Future<String?> convertVideo(
    String sourcePath,
    String outputPath, {
    Map<String, dynamic>? options,
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  }) async {
    await _initialize();

    if (!_isFFmpegInstalled || _ffmpegPath == null) {
      // 提示安装FFmpeg
      final installed = await promptInstallFFmpeg();
      if (!installed) {
        Utils.showSnackbar('提示', 'Windows平台需要安装FFmpeg才能转换视频');
        onFailure?.call(Exception('FFmpeg not installed'));
        return null;
      }
    }

    try {
      // 检查源文件是否存在
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // 构建FFmpeg命令参数
      final videoCodec = options?['videoCodec'] ?? 'libx264';
      final audioCodec = options?['audioCodec'] ?? 'aac';
      final videoBitrate = options?['videoBitrate'] ?? '1500k';
      final audioBitrate = options?['audioBitrate'] ?? '128k';
      final preset = options?['preset'] ?? 'medium';
      final width = options?['width'];
      final height = options?['height'];

      final List<String> arguments = [
        '-hide_banner',
        '-i',
        sourcePath,
        '-c:v',
        videoCodec,
        '-preset',
        preset,
        '-b:v',
        videoBitrate,
      ];

      if (width != null && height != null) {
        arguments.addAll([
          '-vf',
          'scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2',
        ]);
      }

      arguments
          .addAll(['-c:a', audioCodec, '-b:a', audioBitrate, '-y', outputPath]);

      Logger.d('FFmpeg convert command: $_ffmpegPath ${arguments.join(' ')}');

      // 创建进度监控
      final progressRegExp = RegExp(r'time=(\d+:\d+:\d+\.\d+)');
      double totalDuration = 0;

      // 获取视频总时长
      final mediaInfo = await getMediaInfo(sourcePath);
      if (mediaInfo != null && mediaInfo.containsKey('duration')) {
        totalDuration = double.tryParse(mediaInfo['duration'] ?? '0') ?? 0;
      }

      // 执行FFmpeg命令
      final process = await Process.start(_ffmpegPath!, arguments);

      // 监听标准错误输出以获取进度
      process.stderr.transform(utf8.decoder).listen((data) {
        final match = progressRegExp.firstMatch(data);
        if (match != null && totalDuration > 0) {
          final timeStr = match.group(1);
          if (timeStr != null) {
            final parts = timeStr.split(':');
            final hours = int.parse(parts[0]);
            final minutes = int.parse(parts[1]);
            final seconds = double.parse(parts[2]);

            final currentTime = hours * 3600 + minutes * 60 + seconds;
            final progress = (currentTime / totalDuration) * 100;

            onProgress?.call(
                VideoProcessingProgressType.convert, progress.clamp(0, 100));
          }
        }
      });

      // 等待进程完成
      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        Logger.d('FFmpeg convert success: $outputPath');
        onProgress?.call(VideoProcessingProgressType.convert, 100);
        return outputPath;
      } else {
        final failMessage = 'FFmpeg convert failed with code: $exitCode';
        Logger.e(failMessage);
        onFailure?.call(Exception(failMessage));
        return null;
      }
    } catch (e) {
      Logger.e('Error converting video: $e');
      onFailure?.call(Exception('Error converting video: $e'));
      return null;
    }
  }

  @override
  Future<String?> recodeVideo(
    String sourcePath,
    String outputPath, {
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  }) async {
    // 使用转换方法，但使用特定的编码器参数
    return await convertVideo(
      sourcePath,
      outputPath,
      options: {
        'videoCodec': 'mpeg4',
        'preset': 'medium',
      },
      onProgress: (type, progress) {
        onProgress?.call(VideoProcessingProgressType.recode, progress);
      },
      onFailure: onFailure,
    );
  }

  @override
  Future<String?> extractAudio(
    String sourcePath,
    String outputPath, {
    String format = 'mp3',
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  }) async {
    await _initialize();

    if (!_isFFmpegInstalled || _ffmpegPath == null) {
      // 提示安装FFmpeg
      final installed = await promptInstallFFmpeg();
      if (!installed) {
        Utils.showSnackbar('提示', 'Windows平台需要安装FFmpeg才能提取音频');
        onFailure?.call(Exception('FFmpeg not installed'));
        return null;
      }
    }

    try {
      // 根据格式选择不同的编码器
      String audioCodec;
      String audioBitrate = '192k';

      switch (format.toLowerCase()) {
        case 'mp3':
          audioCodec = 'libmp3lame';
          break;
        case 'aac':
          audioCodec = 'aac';
          break;
        case 'flac':
          audioCodec = 'flac';
          break;
        case 'wav':
          audioCodec = 'pcm_s16le';
          break;
        default:
          audioCodec = 'libmp3lame';
          break;
      }

      final List<String> arguments = [
        '-hide_banner',
        '-i',
        sourcePath,
        '-vn',
        '-c:a',
        audioCodec,
        '-b:a',
        audioBitrate,
        '-y',
        outputPath
      ];

      Logger.d(
          'FFmpeg extract audio command: $_ffmpegPath ${arguments.join(' ')}');

      // 创建进度监控
      final progressRegExp = RegExp(r'time=(\d+:\d+:\d+\.\d+)');
      double totalDuration = 0;

      // 获取视频总时长
      final mediaInfo = await getMediaInfo(sourcePath);
      if (mediaInfo != null && mediaInfo.containsKey('duration')) {
        totalDuration = double.tryParse(mediaInfo['duration'] ?? '0') ?? 0;
      }

      // 执行FFmpeg命令
      final process = await Process.start(_ffmpegPath!, arguments);

      // 监听标准错误输出以获取进度
      process.stderr.transform(utf8.decoder).listen((data) {
        final match = progressRegExp.firstMatch(data);
        if (match != null && totalDuration > 0) {
          final timeStr = match.group(1);
          if (timeStr != null) {
            final parts = timeStr.split(':');
            final hours = int.parse(parts[0]);
            final minutes = int.parse(parts[1]);
            final seconds = double.parse(parts[2]);

            final currentTime = hours * 3600 + minutes * 60 + seconds;
            final progress = (currentTime / totalDuration) * 100;

            onProgress?.call(
                VideoProcessingProgressType.extract, progress.clamp(0, 100));
          }
        }
      });

      // 等待进程完成
      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        Logger.d('FFmpeg extract audio success: $outputPath');
        onProgress?.call(VideoProcessingProgressType.extract, 100);
        return outputPath;
      } else {
        final failMessage = 'FFmpeg extract audio failed with code: $exitCode';
        Logger.e(failMessage);
        onFailure?.call(Exception(failMessage));
        return null;
      }
    } catch (e) {
      Logger.e('Error extracting audio: $e');
      onFailure?.call(Exception('Error extracting audio: $e'));
      return null;
    }
  }

  @override
  Future<String?> downloadVideo(
    String videoUrl,
    String outputPath, {
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  }) async {
    await _initialize();

    if (!_isFFmpegInstalled || _ffmpegPath == null) {
      // 提示安装FFmpeg
      final installed = await promptInstallFFmpeg();
      if (!installed) {
        Utils.showSnackbar('提示', 'Windows平台需要安装FFmpeg才能下载视频');
        onFailure?.call(Exception('FFmpeg not installed'));
        return null;
      }
    }

    try {
      final List<String> arguments = [
        '-hide_banner',
        '-i',
        videoUrl,
        '-c',
        'copy',
        '-bsf:a',
        'aac_adtstoasc',
        '-y',
        outputPath
      ];

      Logger.d('FFmpeg download command: $_ffmpegPath ${arguments.join(' ')}');

      // 执行FFmpeg命令
      final process = await Process.start(_ffmpegPath!, arguments);

      // 监听标准错误输出
      process.stderr.transform(utf8.decoder).listen((data) {
        // 下载进度无法准确获取，只能显示处理中
        onProgress?.call(VideoProcessingProgressType.download, 50);
      });

      // 等待进程完成
      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        Logger.d('FFmpeg download success: $outputPath');
        onProgress?.call(VideoProcessingProgressType.download, 100);
        return outputPath;
      } else {
        final failMessage = 'FFmpeg download failed with code: $exitCode';
        Logger.e(failMessage);
        onFailure?.call(Exception(failMessage));
        return null;
      }
    } catch (e) {
      Logger.e('Error downloading video: $e');
      onFailure?.call(Exception('Error downloading video: $e'));
      return null;
    }
  }

  @override
  Future<String?> getVideoThumbnail(
    String sourcePath,
    String outputPath, {
    int timeMs = 0,
  }) async {
    await _initialize();

    if (!_isFFmpegInstalled || _ffmpegPath == null) {
      Utils.showSnackbar('提示', 'Windows平台需要安装FFmpeg才能获取视频缩略图');
      return null;
    }

    try {
      final timeStr = (timeMs / 1000).toStringAsFixed(3);
      final List<String> arguments = [
        '-hide_banner',
        '-i',
        sourcePath,
        '-ss',
        timeStr,
        '-vframes',
        '1',
        '-y',
        outputPath
      ];

      Logger.d('FFmpeg thumbnail command: $_ffmpegPath ${arguments.join(' ')}');

      // 执行FFmpeg命令
      final result = await Process.run(_ffmpegPath!, arguments);

      if (result.exitCode == 0) {
        Logger.d('FFmpeg thumbnail success: $outputPath');
        return outputPath;
      } else {
        Logger.e('FFmpeg thumbnail failed: ${result.stderr}');
        return null;
      }
    } catch (e) {
      Logger.e('Error getting video thumbnail: $e');
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async {
    await _initialize();
    return _isFFmpegInstalled;
  }

  /// 提示安装FFmpeg
  ///
  /// 显示安装对话框，引导用户安装FFmpeg
  /// 返回是否安装成功
  Future<bool> promptInstallFFmpeg() async {
    // 检查是否已安装
    if (_isFFmpegInstalled) {
      return true;
    }

    // 显示安装对话框
    final result = await Get.dialog<bool>(
      const FFmpegInstallDialog(),
      barrierDismissible: false,
    );

    // 如果用户取消安装，返回false
    if (result != true) {
      return false;
    }

    // 重新初始化
    _ffmpegPath = null;
    _ffprobePath = null;
    _isFFmpegInstalled = false;
    await _initialize();

    return _isFFmpegInstalled;
  }

  @override
  List<String> getSupportedVideoFormats() {
    return [
      'mp4',
      'mkv',
      'avi',
      'mov',
      'webm',
      'flv',
      '3gp',
      'wmv',
      'mpg',
      'mpeg',
      'ts',
      'm4v',
    ];
  }

  @override
  List<String> getSupportedAudioFormats() {
    return [
      'mp3',
      'aac',
      'flac',
      'wav',
      'ogg',
      'm4a',
      'wma',
    ];
  }
}
