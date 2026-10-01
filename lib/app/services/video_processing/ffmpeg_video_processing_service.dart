import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
// 临时使用存根实现，避免编译错误
import 'ffmpeg_stub.dart';
import 'package:path/path.dart' as path;
import 'package:tubesavely/app/utils/logger.dart';
import 'video_processing_service.dart';

/// FFmpeg实现的视频处理服务
///
/// 使用FFmpeg库处理视频，适用于Android、iOS、macOS和Linux平台
class FFmpegVideoProcessingService implements VideoProcessingService {
  // 单例实现
  static final FFmpegVideoProcessingService _instance =
      FFmpegVideoProcessingService._internal();

  factory FFmpegVideoProcessingService() => _instance;

  FFmpegVideoProcessingService._internal();

  @override
  Future<Map<String, dynamic>?> getMediaInfo(String filePath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final information = session.getMediaInformation();

      if (information == null) {
        Logger.e('Failed to get media information for $filePath');
        return null;
      }

      final Map<String, dynamic> result = {
        'duration': information.getDuration(),
        'size': File(filePath).lengthSync(),
        'bitrate': information.getBitrate(),
        'format': information.getFormat(),
      };

      // 获取视频流信息
      StreamInformation? videoStream;
      try {
        videoStream = information.getStreams().firstWhere(
              (stream) => stream.getType() == 'video',
            );
      } catch (e) {
        // 没有找到视频流
        videoStream = null;
      }

      if (videoStream != null) {
        result['width'] = videoStream.getWidth();
        result['height'] = videoStream.getHeight();
        result['codec'] = videoStream.getCodec();
        result['frameRate'] = videoStream.getAverageFrameRate();
      }

      return result;
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
    try {
      // 检查源文件是否存在
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // 获取媒体信息
      final mediaInfo = await getMediaInfo(sourcePath);
      final totalDuration = double.tryParse(mediaInfo?['duration'] ?? '0') ?? 0;

      // 构建FFmpeg命令
      final videoCodec = options?['videoCodec'] ?? 'libx264';
      final audioCodec = options?['audioCodec'] ?? 'aac';
      final videoBitrate = options?['videoBitrate'] ?? '1500k';
      final audioBitrate = options?['audioBitrate'] ?? '128k';
      final preset = options?['preset'] ?? 'medium';
      final width = options?['width'];
      final height = options?['height'];

      String scaleFilter = '';
      if (width != null && height != null) {
        scaleFilter =
            '-vf "scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2" ';
      }

      final command =
          '-hide_banner -i "$sourcePath" -c:v $videoCodec -preset $preset '
          '-b:v $videoBitrate $scaleFilter-c:a $audioCodec -b:a $audioBitrate -y "$outputPath"';

      Logger.d('FFmpeg convert command: $command');

      // 创建Completer来控制异步完成
      final completer = Completer<String?>();

      // 执行FFmpeg命令
      FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            Logger.d('FFmpeg convert success: $outputPath');
            onProgress?.call(VideoProcessingProgressType.convert, 100);
            completer.complete(outputPath);
          } else {
            final failMessage =
                'FFmpeg convert failed with code: ${returnCode?.getValue()}';
            Logger.e(failMessage);
            onFailure?.call(Exception(failMessage));
            completer.complete(null);
          }
        },
        (log) {
          Logger.d('FFmpeg log: ${log.getMessage()}');
        },
        (statistics) {
          if (totalDuration > 0) {
            final timeInMs = statistics.getTime();
            final progress = (timeInMs / (totalDuration * 1000)) * 100;
            onProgress?.call(
                VideoProcessingProgressType.convert, progress.clamp(0, 100));
          }
        },
      );

      return await completer.future;
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
    try {
      // 使用MPEG-4编码器重编码视频，提高兼容性
      final command =
          '-hide_banner -i "$sourcePath" -err_detect ignore_err -c:v mpeg4 -y "$outputPath"';

      Logger.d('FFmpeg recode command: $command');

      // 获取媒体信息
      final mediaInfo = await getMediaInfo(sourcePath);
      final totalDuration = double.tryParse(mediaInfo?['duration'] ?? '0') ?? 0;

      // 创建Completer来控制异步完成
      final completer = Completer<String?>();

      // 执行FFmpeg命令
      FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            Logger.d('FFmpeg recode success: $outputPath');
            onProgress?.call(VideoProcessingProgressType.recode, 100);
            completer.complete(outputPath);
          } else {
            final failMessage =
                'FFmpeg recode failed with code: ${returnCode?.getValue()}';
            Logger.e(failMessage);
            onFailure?.call(Exception(failMessage));
            completer.complete(null);
          }
        },
        (log) {
          Logger.d('FFmpeg log: ${log.getMessage()}');
        },
        (statistics) {
          if (totalDuration > 0) {
            final timeInMs = statistics.getTime();
            final progress = (timeInMs / (totalDuration * 1000)) * 100;
            onProgress?.call(
                VideoProcessingProgressType.recode, progress.clamp(0, 100));
          }
        },
      );

      return await completer.future;
    } catch (e) {
      Logger.e('Error recoding video: $e');
      onFailure?.call(Exception('Error recoding video: $e'));
      return null;
    }
  }

  @override
  Future<String?> extractAudio(
    String sourcePath,
    String outputPath, {
    String format = 'mp3',
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  }) async {
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

      final command =
          '-hide_banner -i "$sourcePath" -vn -c:a $audioCodec -b:a $audioBitrate -y "$outputPath"';

      Logger.d('FFmpeg extract audio command: $command');

      // 获取媒体信息
      final mediaInfo = await getMediaInfo(sourcePath);
      final totalDuration = double.tryParse(mediaInfo?['duration'] ?? '0') ?? 0;

      // 创建Completer来控制异步完成
      final completer = Completer<String?>();

      // 执行FFmpeg命令
      FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            Logger.d('FFmpeg extract audio success: $outputPath');
            onProgress?.call(VideoProcessingProgressType.extract, 100);
            completer.complete(outputPath);
          } else {
            final failMessage =
                'FFmpeg extract audio failed with code: ${returnCode?.getValue()}';
            Logger.e(failMessage);
            onFailure?.call(Exception(failMessage));
            completer.complete(null);
          }
        },
        (log) {
          Logger.d('FFmpeg log: ${log.getMessage()}');
        },
        (statistics) {
          if (totalDuration > 0) {
            final timeInMs = statistics.getTime();
            final progress = (timeInMs / (totalDuration * 1000)) * 100;
            onProgress?.call(
                VideoProcessingProgressType.extract, progress.clamp(0, 100));
          }
        },
      );

      return await completer.future;
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
    try {
      final command =
          '-hide_banner -i "$videoUrl" -c copy -bsf:a aac_adtstoasc -y "$outputPath"';

      Logger.d('FFmpeg download command: $command');

      // 创建Completer来控制异步完成
      final completer = Completer<String?>();

      // 执行FFmpeg命令
      FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            Logger.d('FFmpeg download success: $outputPath');
            onProgress?.call(VideoProcessingProgressType.download, 100);
            completer.complete(outputPath);
          } else {
            final failMessage =
                'FFmpeg download failed with code: ${returnCode?.getValue()}';
            Logger.e(failMessage);
            onFailure?.call(Exception(failMessage));
            completer.complete(null);
          }
        },
        (log) {
          Logger.d('FFmpeg log: ${log.getMessage()}');
        },
        (statistics) {
          // 下载进度无法准确获取，只能显示处理进度
          onProgress?.call(VideoProcessingProgressType.download,
              statistics.getTime() / 1000);
        },
      );

      return await completer.future;
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
    try {
      final timeStr = (timeMs / 1000).toStringAsFixed(3);
      final command =
          '-hide_banner -i "$sourcePath" -ss $timeStr -vframes 1 -y "$outputPath"';

      Logger.d('FFmpeg thumbnail command: $command');

      // 创建Completer来控制异步完成
      final completer = Completer<String?>();

      // 执行FFmpeg命令
      FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            Logger.d('FFmpeg thumbnail success: $outputPath');
            completer.complete(outputPath);
          } else {
            final failMessage =
                'FFmpeg thumbnail failed with code: ${returnCode?.getValue()}';
            Logger.e(failMessage);
            completer.complete(null);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      Logger.e('Error getting video thumbnail: $e');
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // 检查FFmpeg是否可用
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      Logger.e('Error checking FFmpeg availability: $e');
      return false;
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
