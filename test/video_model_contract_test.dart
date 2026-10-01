import 'package:flutter_test/flutter_test.dart';
import 'package:tubesavely/app/data/models/video_model.dart';

void main() {
  test('Python parse envelope fields map to playable Flutter formats', () {
    final video = VideoModel.fromJson({
      'video_id': '7687995934931914004',
      'title': 'Fixture',
      'url': 'https://www.tiktok.com/@example/video/7687995934931914004',
      'duration': '94',
      'platform': 'tiktok',
      'formats': [
        {
          'format_id': 'bitrate-1-2',
          'ext': 'mp4',
          'height': 1920,
          'width': 1080,
          'filesize': 12345,
          'tbr': 4000.5,
          'url': 'https://www.tiktok.com/play'
        },
      ],
    });
    expect(video.id, '7687995934931914004');
    expect(video.duration, 94);
    expect(video.formattedDuration, '01:34');
    expect(video.qualities.single.label, '1080p');
    expect(video.qualities.single.url, 'https://www.tiktok.com/play');
    expect(video.formats.single.label, 'mp4');
    expect(video.formats.single.formatId, 'bitrate-1-2');
    expect(video.formats.single.fileSize, 12345);
    expect(VideoModel.fromJson(video.toJson()).formats.single.height, 1920);
  });

  test('History numeric IDs and nullable metadata remain compatible', () {
    final video = VideoModel.fromJson({
      'id': 42,
      'title': 'History',
      'original_url': 'https://example.com/video',
      'duration': null,
      'formats': []
    });
    expect(video.id, '42');
    expect(video.duration, isNull);
    expect(video.url, 'https://example.com/video');
  });
}
