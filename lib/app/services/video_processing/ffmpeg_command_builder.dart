import 'dart:io';
import '../../data/models/video_compress_model.dart';

/// FFmpeg 命令行压缩参数构建器
class FFmpegCommandBuilder {
  /// 构建完整的 FFmpeg 压缩执行参数
  static List<String> build({
    required String sourcePath,
    required String outputPath,
    required CompressConfig config,
    required double durationSeconds,
    required int originalWidth,
    required int originalHeight,
  }) {
    final List<String> args = [
      '-hide_banner',
      '-y', // 覆盖输出文件
      '-i',
      sourcePath,
    ];

    // 1. 分辨率缩放滤镜 (保持比例，且宽和高必须为偶数，避免 yuv420p 编码器报错)
    final scaleFilter = _buildScaleFilter(config.resolution, originalWidth, originalHeight);
    if (scaleFilter != null) {
      args.addAll(['-vf', scaleFilter]);
    }

    // 2. 视频编码器与码率/质量控制
    _appendVideoCodecAndRate(
      args: args,
      config: config,
      durationSeconds: durationSeconds,
    );

    // 3. 音频编码
    args.addAll([
      '-c:a',
      'aac',
      '-b:a',
      '${config.audioBitrateKbps}k',
    ]);

    // 4. 优化 MP4 头部，支持快速开始播放
    args.addAll(['-movflags', '+faststart']);

    // 5. 输出目标路径
    args.add(outputPath);

    return args;
  }

  /// 构建缩放滤镜
  static String? _buildScaleFilter(
    CompressResolution resolution,
    int originalWidth,
    int originalHeight,
  ) {
    int? targetHeight;
    switch (resolution) {
      case CompressResolution.r1080p:
        targetHeight = 1080;
        break;
      case CompressResolution.r720p:
        targetHeight = 720;
        break;
      case CompressResolution.r480p:
        targetHeight = 480;
        break;
      case CompressResolution.original:
        targetHeight = null;
        break;
    }

    if (targetHeight == null || (originalHeight > 0 && originalHeight <= targetHeight)) {
      // 保持原始分辨率时，确保宽和高是偶数 (截取/填充偶数像素)
      return 'scale=trunc(iw/2)*2:trunc(ih/2)*2';
    }

    // 等比缩放，高度为 targetHeight，宽度自动计算且为偶数
    return 'scale=-2:$targetHeight';
  }

  /// 添加视频编码器及码率/CRF 参数
  static void _appendVideoCodecAndRate({
    required List<String> args,
    required CompressConfig config,
    required double durationSeconds,
  }) {
    final isMac = Platform.isMacOS;
    final useHw = config.enableHardwareAcceleration;

    // 目标体积模式：动态反算码率 (2-pass 码率控制或直接指定比特率)
    if (config.preset == CompressPreset.targetSize &&
        config.targetSizeMB != null &&
        config.targetSizeMB! > 0 &&
        durationSeconds > 0) {
      final totalBits = config.targetSizeMB! * 8 * 1024 * 1024;
      final audioBits = config.audioBitrateKbps * 1024 * durationSeconds;
      final videoBits = totalBits - audioBits;
      int videoBitrateKbps = (videoBits / durationSeconds / 1024).round();
      if (videoBitrateKbps < 150) videoBitrateKbps = 150; // 最低保底 150kbps

      if (isMac && useHw) {
        // macOS VideoToolbox 硬件加速
        final codec = config.codec == VideoCodecType.h265
            ? 'hevc_videotoolbox'
            : 'h264_videotoolbox';
        args.addAll([
          '-c:v',
          codec,
          '-b:v',
          '${videoBitrateKbps}k',
          '-pix_fmt',
          'yuv420p',
        ]);
      } else {
        // 标准 CPU 软解压 libx264 / libx265
        final codec = config.codec == VideoCodecType.h265 ? 'libx265' : 'libx264';
        args.addAll([
          '-c:v',
          codec,
          '-b:v',
          '${videoBitrateKbps}k',
          '-maxrate',
          '${(videoBitrateKbps * 1.5).round()}k',
          '-bufsize',
          '${videoBitrateKbps * 2}k',
          '-preset',
          'medium',
          '-pix_fmt',
          'yuv420p',
        ]);
      }
      return;
    }

    // CRF 质量模式
    final crf = config.crf;

    if (isMac && useHw) {
      // macOS VideoToolbox 硬件编码器使用 -q:v (1-100，越小画质越高)
      // CRF 18~35 映射至 VideoToolbox 的 q:v (40~85)
      final qv = (crf * 2.2).clamp(30, 85).round();
      final codec = config.codec == VideoCodecType.h265
          ? 'hevc_videotoolbox'
          : 'h264_videotoolbox';
      args.addAll([
        '-c:v',
        codec,
        '-q:v',
        '$qv',
        '-pix_fmt',
        'yuv420p',
      ]);
    } else {
      // 跨平台 CPU 软解压（通用性与压缩比最高）
      final codec = config.codec == VideoCodecType.h265 ? 'libx265' : 'libx264';
      final presetSpeed = config.preset == CompressPreset.small ? 'faster' : 'medium';
      args.addAll([
        '-c:v',
        codec,
        '-crf',
        '$crf',
        '-preset',
        presetSpeed,
        '-pix_fmt',
        'yuv420p',
      ]);
    }
  }
}
