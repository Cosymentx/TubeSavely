import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tubesavely/app/services/video_processing/desktop_video_processing_service.dart';
import 'package:tubesavely/app/services/video_processing/ffmpeg_installer_service.dart';
import 'package:tubesavely/app/services/video_processing/video_processing_factory.dart';
import 'package:tubesavely/app/translations/app_translations.dart';

void main() {
  group('Video Processing & Converter Tests', () {
    test('DesktopVideoProcessingService supports standard media formats', () {
      final service = DesktopVideoProcessingService();
      final videoFormats = service.getSupportedVideoFormats();
      final audioFormats = service.getSupportedAudioFormats();

      expect(videoFormats.contains('mp4'), isTrue);
      expect(videoFormats.contains('mkv'), isTrue);
      expect(videoFormats.contains('mov'), isTrue);
      expect(videoFormats.contains('webm'), isTrue);

      expect(audioFormats.contains('mp3'), isTrue);
      expect(audioFormats.contains('aac'), isTrue);
      expect(audioFormats.contains('flac'), isTrue);
      expect(audioFormats.contains('wav'), isTrue);
    });

    test('VideoProcessingFactory returns DesktopVideoProcessingService on desktop platforms', () {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final service = VideoProcessingFactory.getService();
        expect(service, isA<DesktopVideoProcessingService>());
      }
    });

    test('FFmpegInstallerService is a singleton', () {
      final s1 = FFmpegInstallerService();
      final s2 = FFmpegInstallerService();
      expect(identical(s1, s2), isTrue);
    });

    test('AppTranslations covers all 4 languages with conversion keys', () {
      final translations = AppTranslations();
      final keys = translations.keys;

      expect(keys.containsKey('zh_CN'), isTrue);
      expect(keys.containsKey('en_US'), isTrue);
      expect(keys.containsKey('ja_JP'), isTrue);
      expect(keys.containsKey('ko_KR'), isTrue);

      for (final lang in ['zh_CN', 'en_US', 'ja_JP', 'ko_KR']) {
        final map = keys[lang]!;
        expect(map.containsKey('ffmpeg_install_title'), isTrue);
        expect(map.containsKey('ffmpeg_auto_install'), isTrue);
        expect(map.containsKey('convert_start'), isTrue);
        expect(map.containsKey('convert_success'), isTrue);
        expect(map.containsKey('convert_stream_copy_hint'), isTrue);
        expect(map.containsKey('convert_source_not_found'), isTrue);
      }
    });
  });
}
