import 'dart:io';
import 'package:flutter/foundation.dart';
import 'video_processing_service.dart';
import 'ffmpeg_video_processing_service.dart';
import 'windows_video_processing_service.dart';

/// 视频处理服务工厂实现
///
/// 根据当前平台返回适合的视频处理服务实例
class VideoProcessingFactory {
  /// 获取适合当前平台的视频处理服务实例
  static VideoProcessingService getService() {
    if (kIsWeb) {
      throw UnsupportedError('Web平台暂不支持视频处理');
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      // 使用FFmpeg实现
      return FFmpegVideoProcessingService();
    } else if (Platform.isWindows) {
      // 使用Windows实现
      return WindowsVideoProcessingService();
    } else {
      throw UnsupportedError('不支持的平台');
    }
  }
}
