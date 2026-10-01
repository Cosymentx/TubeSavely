import 'package:flutter_test/flutter_test.dart';
import 'package:tubesavely/app/data/models/video_model.dart';
import 'package:tubesavely/app/services/media_download_request.dart';

void main() {
  test(
      'Parsed formats use authenticated server streaming instead of page download',
      () {
    final video = VideoModel.fromJson({
      'video_id': '123',
      'title': 'Fixture',
      'url': 'https://www.tiktok.com/@example/video/123',
      'formats': [
        {
          'format_id': 'bitrate-1-2',
          'ext': 'mp4',
          'width': 1080,
          'height': 1920,
          'url': 'https://www.tiktok.com/play'
        }
      ]
    });
    final request = MediaDownloadRequest.forVideo(video, 'fixture-token',
        quality: '1080p', format: 'mp4');
    expect(request.method, 'POST');
    expect(request.url,
        'https://tubesavely-server.vercel.app/api/v1/videos/download');
    expect(request.body, {'url': video.url, 'format_id': 'bitrate-1-2'});
    expect(request.headers['Authorization'], 'Bearer fixture-token');
  });
  test('Local direct media remains a GET request with source headers', () {
    final video =
        VideoModel(title: 'Local', url: 'https://media.example/video.mp4');
    final request = MediaDownloadRequest.forVideo(video, null);
    expect(request.method, 'GET');
    expect(request.url, video.url);
    expect(request.headers.containsKey('Authorization'), isFalse);
    expect(request.headers['Referer'], 'https://media.example/');
  });
}
