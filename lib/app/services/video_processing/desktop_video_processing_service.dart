import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:tubesavely/app/utils/logger.dart';
import 'package:tubesavely/app/utils/utils.dart';
import 'package:tubesavely/app/widgets/ffmpeg_install_dialog.dart';
import 'ffmpeg_installer_service.dart';
import 'video_processing_service.dart';

/// 跨平台桌面端（macOS, Windows, Linux）视频处理服务
///
/// 基于 FFmpeg/FFprobe CLI 原生进程调度，支持全核心多线程、硬件加速及流直通复用
class DesktopVideoProcessingService implements VideoProcessingService {
  static final DesktopVideoProcessingService _instance =
      DesktopVideoProcessingService._internal();

  factory DesktopVideoProcessingService() => _instance;

  DesktopVideoProcessingService._internal();

  final FFmpegInstallerService _installerService = FFmpegInstallerService();

  String? _ffmpegPath;
  String? _ffprobePath;
  String? _ffmpegVersion;
  bool _isFFmpegInstalled = false;

  /// 初始化并检测 FFmpeg/FFprobe
  Future<void> _initialize() async {
    _ffmpegPath = await _installerService.getFFmpegPath();
    _ffprobePath = await _installerService.getFFprobePath();

    if (_ffmpegPath != null && await File(_ffmpegPath!).exists()) {
      _isFFmpegInstalled = true;
      try {
        final versionResult = await Process.run(_ffmpegPath!, ['-version']);
        if (versionResult.exitCode == 0) {
          final versionMatch = RegExp(r'ffmpeg version (\S+)').firstMatch(versionResult.stdout.toString());
          if (versionMatch != null) {
            _ffmpegVersion = versionMatch.group(1);
          }
        }
      } catch (e) {
        Logger.d('Failed to parse FFmpeg version: $e');
      }
    } else {
      _isFFmpegInstalled = false;
    }
  }

  /// 获取 FFmpeg 版本
  String? getFFmpegVersion() => _ffmpegVersion;

  /// 提示安装 FFmpeg 对话框（跨平台）
  Future<bool> promptInstallFFmpeg() async {
    await _initialize();
    if (_isFFmpegInstalled) return true;

    final result = await Get.dialog<bool>(
      const FFmpegInstallDialog(),
      barrierDismissible: false,
    );

    if (result == true) {
      await _initialize();
      return _isFFmpegInstalled;
    }
    return false;
  }

  @override
  Future<bool> isAvailable() async {
    await _initialize();
    return _isFFmpegInstalled;
  }

  @override
  Future<Map<String, dynamic>?> getMediaInfo(String filePath) async {
    await _initialize();

    if (!_isFFmpegInstalled || _ffprobePath == null) {
      final installed = await promptInstallFFmpeg();
      if (!installed || _ffprobePath == null) {
        Utils.showSnackbar('tips'.tr, 'ffmpeg_not_found'.tr);
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
        filePath,
      ]);

      if (result.exitCode == 0) {
        final jsonStr = result.stdout.toString();
        final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
        final Map<String, dynamic> mediaInfo = {};

        // 提取容器与格式信息
        if (jsonData.containsKey('format')) {
          final format = jsonData['format'];
          mediaInfo['duration'] = format['duration'];
          mediaInfo['size'] = int.tryParse(format['size']?.toString() ?? '0') ?? 0;
          mediaInfo['bitrate'] = format['bit_rate'];
          mediaInfo['format'] = format['format_name'];
        }

        // 提取音视频流信息
        if (jsonData.containsKey('streams') && jsonData['streams'] is List) {
          final streams = jsonData['streams'] as List;
          for (final stream in streams) {
            final codecType = stream['codec_type'];
            if (codecType == 'video' && !mediaInfo.containsKey('width')) {
              mediaInfo['width'] = stream['width'];
              mediaInfo['height'] = stream['height'];
              mediaInfo['codec'] = stream['codec_name'];
              mediaInfo['frameRate'] = stream['r_frame_rate'];
            } else if (codecType == 'audio' && !mediaInfo.containsKey('audioCodec')) {
              mediaInfo['audioCodec'] = stream['codec_name'];
              mediaInfo['audioBitrate'] = stream['bit_rate'];
              mediaInfo['sampleRate'] = stream['sample_rate'];
            }
          }
        }

        return mediaInfo;
      } else {
        Logger.e('FFprobe error: ${result.stderr}');
        return null;
      }
    } catch (e) {
      Logger.e('Error getting media info: $e');
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
      final installed = await promptInstallFFmpeg();
      if (!installed || _ffmpegPath == null) {
        Utils.showSnackbar('tips'.tr, 'ffmpeg_not_found'.tr);
        onFailure?.call(Exception('FFmpeg not installed'));
        return null;
      }
    }

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // 获取视频总时长以计算进度
      final mediaInfo = await getMediaInfo(sourcePath);
      final double totalDuration = double.tryParse(mediaInfo?['duration']?.toString() ?? '0') ?? 0.0;

      final bool isCopyStream = options?['copyStream'] == true;
      final List<String> arguments = ['-hide_banner', '-threads', '0', '-y', '-i', sourcePath];

      if (isCopyStream) {
        // Stream Copy 极速直通复用模式 (零转码开销，秒级完成)
        arguments.addAll(['-c', 'copy']);
        if (outputPath.toLowerCase().endsWith('.mp4') || outputPath.toLowerCase().endsWith('.m4v')) {
          arguments.addAll(['-movflags', '+faststart']);
        }
      } else {
        // 转码模式
        final videoCodec = options?['videoCodec'] ?? 'libx264';
        final audioCodec = options?['audioCodec'] ?? 'aac';
        final videoBitrate = options?['videoBitrate'] ?? '1500k';
        final audioBitrate = options?['audioBitrate'] ?? '128k';
        final preset = options?['preset'] ?? 'faster'; // 默认从 medium 提升为 faster
        final width = options?['width'];
        final height = options?['height'];

        arguments.addAll(['-c:v', videoCodec]);

        // 仅在软解/特定编码器添加 preset
        if (videoCodec == 'libx264' || videoCodec == 'libx265') {
          arguments.addAll(['-preset', preset]);
        }

        arguments.addAll(['-b:v', videoBitrate]);

        if (width != null && height != null) {
          arguments.addAll([
            '-vf',
            'scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2',
          ]);
        }

        arguments.addAll(['-c:a', audioCodec, '-b:a', audioBitrate]);

        if (outputPath.toLowerCase().endsWith('.mp4') || outputPath.toLowerCase().endsWith('.m4v')) {
          arguments.addAll(['-movflags', '+faststart']);
        }
      }

      arguments.add(outputPath);

      Logger.d('FFmpeg convert command: $_ffmpegPath ${arguments.join(' ')}');

      final process = await Process.start(_ffmpegPath!, arguments);
      final progressRegExp = RegExp(r'time=(\d+:\d+:\d+\.\d+)');
      final StringBuffer errorBuffer = StringBuffer();

      process.stderr.transform(utf8.decoder).listen((data) {
        errorBuffer.write(data);
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
            onProgress?.call(VideoProcessingProgressType.convert, progress.clamp(0.0, 100.0));
          }
        }
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        Logger.d('FFmpeg convert success: $outputPath');
        onProgress?.call(VideoProcessingProgressType.convert, 100.0);
        return outputPath;
      } else {
        final lines = errorBuffer.toString().split('\n');
        final recentLog = lines.length > 5 ? lines.sublist(lines.length - 5).join(' ') : lines.join(' ');
        final failMessage = 'FFmpeg convert failed with code: $exitCode. Log: $recentLog';
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
    return await convertVideo(
      sourcePath,
      outputPath,
      options: {
        'videoCodec': 'mpeg4',
        'preset': 'faster',
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
      final installed = await promptInstallFFmpeg();
      if (!installed || _ffmpegPath == null) {
        Utils.showSnackbar('tips'.tr, 'ffmpeg_not_found'.tr);
        onFailure?.call(Exception('FFmpeg not installed'));
        return null;
      }
    }

    try {
      final mediaInfo = await getMediaInfo(sourcePath);
      final totalDuration = double.tryParse(mediaInfo?['duration']?.toString() ?? '0') ?? 0.0;
      final sourceAudioCodec = mediaInfo?['audioCodec']?.toString().toLowerCase();

      String audioCodec;
      String audioBitrate = '192k';
      bool canDirectCopy = false;

      switch (format.toLowerCase()) {
        case 'mp3':
          if (sourceAudioCodec == 'mp3') {
            canDirectCopy = true;
            audioCodec = 'copy';
          } else {
            audioCodec = 'libmp3lame';
          }
          break;
        case 'aac':
        case 'm4a':
          if (sourceAudioCodec == 'aac') {
            canDirectCopy = true;
            audioCodec = 'copy';
          } else {
            audioCodec = 'aac';
          }
          break;
        case 'flac':
          if (sourceAudioCodec == 'flac') {
            canDirectCopy = true;
            audioCodec = 'copy';
          } else {
            audioCodec = 'flac';
          }
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
        '-threads',
        '0',
        '-y',
        '-i',
        sourcePath,
        '-vn',
        '-c:a',
        audioCodec,
      ];

      if (!canDirectCopy && format.toLowerCase() != 'wav') {
        arguments.addAll(['-b:a', audioBitrate]);
      }

      arguments.add(outputPath);

      Logger.d('FFmpeg extract audio command: $_ffmpegPath ${arguments.join(' ')}');

      final process = await Process.start(_ffmpegPath!, arguments);
      final progressRegExp = RegExp(r'time=(\d+:\d+:\d+\.\d+)');

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
            onProgress?.call(VideoProcessingProgressType.extract, progress.clamp(0.0, 100.0));
          }
        }
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        Logger.d('FFmpeg extract audio success: $outputPath');
        onProgress?.call(VideoProcessingProgressType.extract, 100.0);
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
      final installed = await promptInstallFFmpeg();
      if (!installed || _ffmpegPath == null) {
        Utils.showSnackbar('tips'.tr, 'ffmpeg_not_found'.tr);
        onFailure?.call(Exception('FFmpeg not installed'));
        return null;
      }
    }

    try {
      final List<String> arguments = [
        '-hide_banner',
        '-y',
        '-i',
        videoUrl,
        '-c',
        'copy',
        '-bsf:a',
        'aac_adtstoasc',
        outputPath,
      ];

      Logger.d('FFmpeg download command: $_ffmpegPath ${arguments.join(' ')}');

      final process = await Process.start(_ffmpegPath!, arguments);

      process.stderr.transform(utf8.decoder).listen((data) {
        onProgress?.call(VideoProcessingProgressType.download, 50.0);
      });

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        Logger.d('FFmpeg download success: $outputPath');
        onProgress?.call(VideoProcessingProgressType.download, 100.0);
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
      Utils.showSnackbar('tips'.tr, 'ffmpeg_not_found'.tr);
      return null;
    }

    try {
      final timeStr = (timeMs / 1000).toStringAsFixed(3);
      final List<String> arguments = [
        '-hide_banner',
        '-y',
        '-ss',
        timeStr,
        '-i',
        sourcePath,
        '-vframes',
        '1',
        outputPath,
      ];

      Logger.d('FFmpeg thumbnail command: $_ffmpegPath ${arguments.join(' ')}');

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
