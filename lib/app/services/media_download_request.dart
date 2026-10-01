import '../data/models/video_model.dart';
import '../utils/constants.dart';

class MediaDownloadRequest {
  final String url;
  final Map<String, String> headers;
  final Map<String, String>? body;
  String get method => body == null ? 'GET' : 'POST';

  const MediaDownloadRequest(this.url, this.headers, this.body);

  factory MediaDownloadRequest.forVideo(VideoModel video, String? token,
      {String? quality, String? format}) {
    final candidates = video.formats
        .where((entry) =>
            entry.url.isNotEmpty && (format == null || entry.label == format))
        .toList();
    VideoFormat? selected;
    if (candidates.isNotEmpty) {
      selected = candidates.first;
      for (final candidate in candidates) {
        final height = candidate.height ?? 0;
        final width = candidate.width ?? 0;
        final size = width > 0 && height > width ? width : height;
        if (quality == '${size}p') {
          selected = candidate;
          break;
        }
      }
    }
    if (token != null && token.isNotEmpty && selected?.formatId != null) {
      return MediaDownloadRequest(
        '${Constants.API_BASE_URL}/api/v1/videos/download',
        {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        {'url': video.url, 'format_id': selected!.formatId!},
      );
    }
    final direct = selected?.url ??
        (video.qualities.isNotEmpty ? video.qualities.first.url : video.url);
    final source = Uri.tryParse(video.url);
    return MediaDownloadRequest(
        direct,
        {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
          if (source != null && source.host.isNotEmpty)
            'Referer': '${source.scheme}://${source.host}/',
        },
        null);
  }
}
