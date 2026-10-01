import 'dart:io';
import 'package:flutter/foundation.dart';

/// 视频处理进度类型
enum VideoProcessingProgressType {
  idle,
  download,
  convert,
  recode,
  extract,
}

/// 视频处理进度回调
typedef VideoProcessingProgressCallback = void Function(VideoProcessingProgressType type, num progress);

/// 视频处理成功回调
typedef VideoProcessingSuccessCallback = void Function(String path);

/// 视频处理失败回调
typedef VideoProcessingFailureCallback = void Function(Exception error);

/// 视频处理服务抽象类
///
/// 定义了视频处理的通用接口，不同平台可以有不同的实现
abstract class VideoProcessingService {
  /// 获取视频信息
  ///
  /// [filePath] 视频文件路径
  /// 返回视频信息，包括时长、分辨率、比特率等
  Future<Map<String, dynamic>?> getMediaInfo(String filePath);

  /// 转换视频格式
  ///
  /// [sourcePath] 源视频路径
  /// [outputPath] 输出视频路径
  /// [options] 转换选项，如编码器、比特率、分辨率等
  /// [onProgress] 进度回调
  /// [onFailure] 失败回调
  /// 返回转换后的视频路径
  Future<String?> convertVideo(
    String sourcePath,
    String outputPath, {
    Map<String, dynamic>? options,
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  });

  /// 重编码视频
  ///
  /// [sourcePath] 源视频路径
  /// [outputPath] 输出视频路径
  /// [onProgress] 进度回调
  /// [onFailure] 失败回调
  /// 返回重编码后的视频路径
  Future<String?> recodeVideo(
    String sourcePath,
    String outputPath, {
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  });

  /// 提取音频
  ///
  /// [sourcePath] 源视频路径
  /// [outputPath] 输出音频路径
  /// [format] 音频格式，如mp3、aac等
  /// [onProgress] 进度回调
  /// [onFailure] 失败回调
  /// 返回提取后的音频路径
  Future<String?> extractAudio(
    String sourcePath,
    String outputPath, {
    String format = 'mp3',
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  });

  /// 下载视频
  ///
  /// [videoUrl] 视频URL
  /// [outputPath] 输出视频路径
  /// [onProgress] 进度回调
  /// [onFailure] 失败回调
  /// 返回下载后的视频路径
  Future<String?> downloadVideo(
    String videoUrl,
    String outputPath, {
    VideoProcessingProgressCallback? onProgress,
    VideoProcessingFailureCallback? onFailure,
  });

  /// 获取视频缩略图
  ///
  /// [sourcePath] 源视频路径
  /// [outputPath] 输出缩略图路径
  /// [timeMs] 缩略图时间点（毫秒）
  /// 返回缩略图路径
  Future<String?> getVideoThumbnail(
    String sourcePath,
    String outputPath, {
    int timeMs = 0,
  });

  /// 检查服务是否可用
  ///
  /// 返回服务是否可用
  Future<bool> isAvailable();

  /// 获取支持的视频格式
  ///
  /// 返回支持的视频格式列表
  List<String> getSupportedVideoFormats();

  /// 获取支持的音频格式
  ///
  /// 返回支持的音频格式列表
  List<String> getSupportedAudioFormats();
}

/// 视频处理服务工厂
///
/// 用于创建适合当前平台的视频处理服务实例
class VideoProcessingServiceFactory {
  /// 获取适合当前平台的视频处理服务实例
  static VideoProcessingService getService() {
    // 根据平台返回不同的实现
    // 具体实现类将在各自的文件中定义
    if (kIsWeb) {
      throw UnsupportedError('Web平台暂不支持视频处理');
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      // 使用FFmpeg实现
      // 这里会在FFmpeg实现类中导入
      throw UnimplementedError('请导入FFmpeg实现类');
    } else if (Platform.isWindows) {
      // 使用Windows实现
      // 这里会在Windows实现类中导入
      throw UnimplementedError('请导入Windows实现类');
    } else {
      throw UnsupportedError('不支持的平台');
    }
  }
}
