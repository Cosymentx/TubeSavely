# 集成指南

本文档提供了如何将视频处理服务集成到现有代码中的指南。

## 1. 更新依赖

确保在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  # 已有依赖
  ffmpeg_kit_flutter_new: ^1.2.1  # 用于Android/iOS/macOS/Linux
  
  # 新增依赖
  archive: ^3.4.10  # 用于解压FFmpeg
  path: ^1.8.3      # 用于路径处理
```

## 2. 初始化视频处理服务

在应用程序启动时初始化视频处理服务：

```dart
import 'package:tubesavely/app/services/video_processing/video_processing_factory.dart';
import 'package:tubesavely/app/services/video_processing/video_processing_service.dart';

class AppController extends GetxController {
  late VideoProcessingService _videoProcessingService;
  
  @override
  void onInit() {
    super.onInit();
    
    // 初始化视频处理服务
    _videoProcessingService = VideoProcessingFactory.getService();
    
    // 检查服务是否可用
    _checkVideoProcessingService();
  }
  
  Future<void> _checkVideoProcessingService() async {
    final isAvailable = await _videoProcessingService.isAvailable();
    if (!isAvailable) {
      Logger.w('Video processing service is not available on this platform');
    }
  }
}
```

## 3. 替换现有的FFmpeg调用

将现有的FFmpeg调用替换为视频处理服务：

### 原始代码：

```dart
// 使用FFmpeg转换视频
final command = '-hide_banner -i "$sourcePath" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k -y "$outputPath"';
final session = await FFmpegKit.executeAsync(command, ...);
```

### 替换为：

```dart
// 使用视频处理服务转换视频
final outputPath = await _videoProcessingService.convertVideo(
  sourcePath,
  outputPath,
  options: {
    'videoCodec': 'libx264',
    'preset': 'medium',
    'videoBitrate': '1500k',
    'audioBitrate': '128k',
    'width': 1280,
    'height': 720,
  },
  onProgress: (type, progress) {
    // 更新进度
  },
  onFailure: (error) {
    // 处理错误
  },
);
```

## 4. 处理Windows平台

在Windows平台上，如果用户没有安装FFmpeg，会自动显示安装对话框。您不需要额外的代码来处理这种情况，视频处理服务会自动处理。

如果您想在特定情况下手动检查FFmpeg是否已安装，可以使用以下代码：

```dart
if (Platform.isWindows) {
  final windowsService = _videoProcessingService as WindowsVideoProcessingService;
  final isInstalled = await windowsService.isFFmpegInstalled();
  
  if (!isInstalled) {
    final installed = await windowsService.promptInstallFFmpeg();
    if (!installed) {
      // 用户取消了安装，处理这种情况
    }
  }
}
```

## 5. 获取视频信息

使用视频处理服务获取视频信息：

```dart
final mediaInfo = await _videoProcessingService.getMediaInfo(filePath);
if (mediaInfo != null) {
  final duration = mediaInfo['duration'];
  final width = mediaInfo['width'];
  final height = mediaInfo['height'];
  final format = mediaInfo['format'];
  
  // 使用这些信息
}
```

## 6. 提取音频

使用视频处理服务提取音频：

```dart
final audioPath = await _videoProcessingService.extractAudio(
  videoPath,
  outputPath,
  format: 'mp3',
  onProgress: (type, progress) {
    // 更新进度
  },
  onFailure: (error) {
    // 处理错误
  },
);
```

## 7. 下载视频

使用视频处理服务下载视频：

```dart
final videoPath = await _videoProcessingService.downloadVideo(
  videoUrl,
  outputPath,
  onProgress: (type, progress) {
    // 更新进度
  },
  onFailure: (error) {
    // 处理错误
  },
);
```

## 8. 获取视频缩略图

使用视频处理服务获取视频缩略图：

```dart
final thumbnailPath = await _videoProcessingService.getVideoThumbnail(
  videoPath,
  outputPath,
  timeMs: 5000, // 5秒处的缩略图
);
```

## 注意事项

1. 视频处理服务会自动处理平台差异，您不需要编写平台特定的代码。
2. 在Windows平台上，如果用户没有安装FFmpeg，会自动显示安装对话框。
3. 所有方法都提供进度回调，您可以使用它来更新UI。
4. 所有方法都提供错误回调，您可以使用它来处理错误。
