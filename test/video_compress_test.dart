import 'package:flutter_test/flutter_test.dart';
import 'package:tubesavely/app/data/models/video_compress_model.dart';
import 'package:tubesavely/app/services/video_processing/ffmpeg_command_builder.dart';

void main() {
  group('Video Compress Model Tests', () {
    test('CompressConfig default values', () {
      const config = CompressConfig();
      expect(config.preset, CompressPreset.balanced);
      expect(config.codec, VideoCodecType.h264);
      expect(config.crf, 24);
      expect(config.enableHardwareAcceleration, true);
    });

    test('CompressConfig default CRF and resolution mapping', () {
      expect(CompressConfig.defaultCrfFor(CompressPreset.small), 28);
      expect(CompressConfig.defaultCrfFor(CompressPreset.balanced), 24);
      expect(CompressConfig.defaultCrfFor(CompressPreset.quality), 20);

      expect(CompressConfig.defaultResolutionFor(CompressPreset.small), CompressResolution.r720p);
      expect(CompressConfig.defaultResolutionFor(CompressPreset.balanced), CompressResolution.original);
    });

    test('CompressTask savings calculation', () {
      final task = CompressTask(
        id: '1',
        sourcePath: '/test/source.mp4',
        targetPath: '/test/out.mp4',
        fileName: 'source.mp4',
        sourceSizeBytes: 100 * 1024 * 1024, // 100MB
        targetSizeBytes: 30 * 1024 * 1024,  // 30MB
        durationSeconds: 60.0,
        width: 1920,
        height: 1080,
        config: const CompressConfig(),
        createdAt: DateTime.now(),
      );

      expect(task.savedBytes, 70 * 1024 * 1024);
      expect(task.savedRatio, closeTo(70.0, 0.1));
    });
  });

  group('FFmpegCommandBuilder Tests', () {
    test('builds CRF compression arguments correctly', () {
      const config = CompressConfig(
        preset: CompressPreset.balanced,
        crf: 24,
        resolution: CompressResolution.r720p,
        enableHardwareAcceleration: false,
      );

      final args = FFmpegCommandBuilder.build(
        sourcePath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        config: config,
        durationSeconds: 120.0,
        originalWidth: 1920,
        originalHeight: 1080,
      );

      expect(args.contains('-i'), true);
      expect(args.contains('/path/input.mp4'), true);
      expect(args.contains('/path/output.mp4'), true);
      expect(args.contains('-vf'), true);
      expect(args.contains('scale=-2:720'), true);
      expect(args.contains('-crf'), true);
      expect(args.contains('24'), true);
      expect(args.contains('+faststart'), true);
    });

    test('builds target size bitrate arguments correctly', () {
      const config = CompressConfig(
        preset: CompressPreset.targetSize,
        targetSizeMB: 25.0,
        audioBitrateKbps: 128,
        enableHardwareAcceleration: false,
      );

      final args = FFmpegCommandBuilder.build(
        sourcePath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        config: config,
        durationSeconds: 60.0,
        originalWidth: 1920,
        originalHeight: 1080,
      );

      expect(args.contains('-b:v'), true);
      expect(args.contains('-c:a'), true);
      expect(args.contains('128k'), true);
    });
  });
}
