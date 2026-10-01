import 'package:flutter_test/flutter_test.dart';
import 'package:tubesavely/app/services/video_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VideoParserService service;

  setUp(() async {
    service = await VideoParserService().init();
  });

  test('YouTube URL parsing extracts video details', () async {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    final video = await service.parseVideo(url);
    expect(video, isNotNull);
    expect(video!.id, 'dQw4w9WgXcQ');
    expect(video.platform, 'YouTube');
    expect(video.thumbnail, isNotEmpty);
    expect(video.title, isNotEmpty);
  });

  test('Direct link parsing works', () async {
    const url = 'https://example.com/sample_video.mp4';
    final video = await service.parseVideo(url);
    expect(video, isNotNull);
    expect(video!.platform, 'DirectLink');
    expect(video.title, 'sample_video.mp4');
  });
}
