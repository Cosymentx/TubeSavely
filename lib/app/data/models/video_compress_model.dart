import 'dart:io';

/// 压缩预设模式
enum CompressPreset {
  /// 极致压缩 (省空间，适合社交发送)
  small,
  /// 平衡模式 (推荐，画质与体积兼顾)
  balanced,
  /// 高画质低损 (适合珍贵视频归档)
  quality,
  /// 目标体积限制 (如限制 25MB、50MB、100MB)
  targetSize,
  /// 高级自定义
  custom,
}

/// 编码格式
enum VideoCodecType {
  h264,
  h265,
  av1,
}

/// 分辨率档位
enum CompressResolution {
  original,
  r1080p,
  r720p,
  r480p,
}

/// 任务状态
enum CompressTaskStatus {
  pending,
  analyzing,
  compressing,
  completed,
  failed,
  canceled,
}

/// 压缩配置
class CompressConfig {
  final CompressPreset preset;
  final VideoCodecType codec;
  final CompressResolution resolution;
  final int crf; // 恒定速率因子 (18-35)
  final double? targetSizeMB; // 目标体积限制 (MB)
  final int audioBitrateKbps; // 音频码率 (kbps)
  final bool enableHardwareAcceleration; // 是否启用 GPU 硬件加速
  final String? customOutputDir; // 自定义输出目录

  const CompressConfig({
    this.preset = CompressPreset.balanced,
    this.codec = VideoCodecType.h264,
    this.resolution = CompressResolution.original,
    this.crf = 24,
    this.targetSizeMB,
    this.audioBitrateKbps = 128,
    this.enableHardwareAcceleration = true,
    this.customOutputDir,
  });

  CompressConfig copyWith({
    CompressPreset? preset,
    VideoCodecType? codec,
    CompressResolution? resolution,
    int? crf,
    double? targetSizeMB,
    int? audioBitrateKbps,
    bool? enableHardwareAcceleration,
    String? customOutputDir,
  }) {
    return CompressConfig(
      preset: preset ?? this.preset,
      codec: codec ?? this.codec,
      resolution: resolution ?? this.resolution,
      crf: crf ?? this.crf,
      targetSizeMB: targetSizeMB ?? this.targetSizeMB,
      audioBitrateKbps: audioBitrateKbps ?? this.audioBitrateKbps,
      enableHardwareAcceleration:
          enableHardwareAcceleration ?? this.enableHardwareAcceleration,
      customOutputDir: customOutputDir ?? this.customOutputDir,
    );
  }

  /// 获取预设对应的默认 CRF
  static int defaultCrfFor(CompressPreset preset) {
    switch (preset) {
      case CompressPreset.small:
        return 28;
      case CompressPreset.balanced:
        return 24;
      case CompressPreset.quality:
        return 20;
      case CompressPreset.targetSize:
      case CompressPreset.custom:
        return 24;
    }
  }

  /// 获取预设对应的默认分辨率
  static CompressResolution defaultResolutionFor(CompressPreset preset) {
    switch (preset) {
      case CompressPreset.small:
        return CompressResolution.r720p;
      case CompressPreset.balanced:
      case CompressPreset.quality:
      case CompressPreset.targetSize:
      case CompressPreset.custom:
        return CompressResolution.original;
    }
  }
}

/// 视频压缩任务
class CompressTask {
  final String id;
  final String sourcePath;
  final String targetPath;
  final String fileName;
  final int sourceSizeBytes;
  final int? targetSizeBytes;
  final double durationSeconds;
  final int width;
  final int height;
  final CompressConfig config;
  final CompressTaskStatus status;
  final double progress; // 0.0 ~ 1.0
  final String? speed; // 如 1.8x
  final String? eta; // 预计剩余时间
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  CompressTask({
    required this.id,
    required this.sourcePath,
    required this.targetPath,
    required this.fileName,
    required this.sourceSizeBytes,
    this.targetSizeBytes,
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.config,
    this.status = CompressTaskStatus.pending,
    this.progress = 0.0,
    this.speed,
    this.eta,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  /// 压缩节省的体积比例 (例如: 65%)
  double? get savedRatio {
    if (targetSizeBytes == null || sourceSizeBytes <= 0) return null;
    final saved = sourceSizeBytes - targetSizeBytes!;
    if (saved <= 0) return 0.0;
    return (saved / sourceSizeBytes) * 100;
  }

  /// 节省的绝对字节数
  int get savedBytes {
    if (targetSizeBytes == null || sourceSizeBytes <= 0) return 0;
    final diff = sourceSizeBytes - targetSizeBytes!;
    return diff > 0 ? diff : 0;
  }

  CompressTask copyWith({
    String? id,
    String? sourcePath,
    String? targetPath,
    String? fileName,
    int? sourceSizeBytes,
    int? targetSizeBytes,
    double? durationSeconds,
    int? width,
    int? height,
    CompressConfig? config,
    CompressTaskStatus? status,
    double? progress,
    String? speed,
    String? eta,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return CompressTask(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      fileName: fileName ?? this.fileName,
      sourceSizeBytes: sourceSizeBytes ?? this.sourceSizeBytes,
      targetSizeBytes: targetSizeBytes ?? this.targetSizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      width: width ?? this.width,
      height: height ?? this.height,
      config: config ?? this.config,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
