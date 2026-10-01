import 'dart:io';
import 'package:flutter/foundation.dart';
import 'video_processing_service.dart';
import 'desktop_video_processing_service.dart';
import 'ffmpeg_video_processing_service.dart';

/// 视频处理服务工厂实现
///
/// 根据当前运行平台返回高效、适配的视频处理服务实例
class VideoProcessingFactory {
  /// 获取适合当前平台的视频处理服务实例
  static VideoProcessingService getService() {
    if (kIsWeb) {
      throw UnsupportedError('Web平台暂不支持视频处理');
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // 桌面端统一使用基于本地 CLI 进程与沙盒免安装包的 DesktopVideoProcessingService
      return DesktopVideoProcessingService();
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 移动端实现
      return FFmpegVideoProcessingService();
    } else {
      throw UnsupportedError('不支持的平台');
    }
  }
}
