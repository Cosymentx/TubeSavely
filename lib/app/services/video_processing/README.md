# 视频处理服务

这个目录包含了视频处理服务的实现，用于处理视频转换、下载和提取音频等功能。

## 架构设计

为了解决FFmpeg在Windows平台不支持的问题，我们采用了抽象工厂模式，创建了一个平台无关的视频处理服务接口，并为不同平台提供了具体实现：

1. `VideoProcessingService` - 抽象接口，定义了视频处理的通用方法
2. `FFmpegVideoProcessingService` - 使用FFmpeg实现，适用于Android、iOS、macOS和Linux平台
3. `WindowsVideoProcessingService` - Windows平台实现，使用系统命令行调用FFmpeg

## 使用方法

```dart
// 获取适合当前平台的视频处理服务实例
final videoProcessingService = VideoProcessingFactory.getService();

// 检查服务是否可用
final isAvailable = await videoProcessingService.isAvailable();
if (!isAvailable) {
  print('视频处理服务在当前平台不可用');
}

// 转换视频
final outputPath = await videoProcessingService.convertVideo(
  sourcePath,
  outputPath,
  options: {
    'videoCodec': 'libx264',
    'audioBitrate': '128k',
    'width': 1280,
    'height': 720,
  },
  onProgress: (type, progress) {
    print('转换进度: $progress%');
  },
  onFailure: (error) {
    print('转换失败: $error');
  },
);

// 提取音频
final audioPath = await videoProcessingService.extractAudio(
  sourcePath,
  outputPath,
  format: 'mp3',
);

// 获取视频信息
final mediaInfo = await videoProcessingService.getMediaInfo(filePath);
final duration = mediaInfo?['duration'];
final width = mediaInfo?['width'];
final height = mediaInfo?['height'];
```

## Windows平台注意事项

在Windows平台上，需要安装FFmpeg命令行工具才能使用视频处理功能。如果未安装FFmpeg，服务将提示用户安装。

### 安装FFmpeg（Windows）

1. 下载FFmpeg：https://ffmpeg.org/download.html
2. 解压到任意目录，如 `C:\ffmpeg`
3. 将FFmpeg的bin目录添加到系统PATH环境变量，如 `C:\ffmpeg\bin`
4. 重启应用程序

## 支持的格式

- 视频格式：mp4, mkv, avi, mov, webm, flv, 3gp, wmv
- 音频格式：mp3, aac, flac, wav, ogg, m4a

## 实现细节

- 使用`ffmpeg_kit_flutter_new`库在Android和iOS上执行FFmpeg命令
- 在Windows上使用`Process.run`调用系统命令行中的FFmpeg
- 提供进度回调，实时更新转换进度
- 错误处理和用户友好的错误消息
