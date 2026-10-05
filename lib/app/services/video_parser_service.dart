import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/video_model.dart';
import '../data/providers/api_provider.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

int? _number(dynamic value) => value is num
    ? value.toInt()
    : num.tryParse(value?.toString() ?? '')?.toInt();

/// 视频解析服务
///
/// 负责解析不同平台的视频链接，提取视频信息
class VideoParserService extends GetxService {
  /// 初始化服务
  Future<VideoParserService> init() async {
    Logger.d('VideoParserService initialized');
    return this;
  }

  /// 解析视频链接
  ///
  /// [url] 视频链接
  /// 返回解析后的视频模型，解析失败返回null
  Future<VideoModel?> parseVideo(String url) async {
    try {
      // 判断URL属于哪个平台
      final platform = _detectPlatform(url);
      switch (platform) {
        case 'YouTube':
          return await _parseYouTube(url);
        case 'Bilibili':
          return await _parseBilibili(url);
        case 'TikTok':
          return await _parseTikTok(url);
        case 'Instagram':
          return await _parseInstagram(url);
        default:
          // 使用通用API或网页标签解析其他平台及直接链接
          return await _parseGeneric(url);
      }
    } catch (e) {
      Logger.e('Error parsing video: $e');
      return null;
    }
  }

  /// 检测URL属于哪个平台
  ///
  /// [url] 视频链接
  /// 返回平台名称，未识别返回null
  String? _detectPlatform(String url) {
    for (final platform in Constants.SUPPORTED_PLATFORMS) {
      final regex = RegExp(platform['regex']);
      if (regex.hasMatch(url)) {
        return platform['name'];
      }
    }
    return null;
  }

  /// 解析YouTube视频
  ///
  /// [url] YouTube视频链接
  /// 返回解析后的视频模型
  /// 解析YouTube视频
  ///
  /// [url] YouTube视频链接
  /// 返回解析后的视频模型
  Future<VideoModel?> _parseYouTube(String url) async {
    try {
      // 提取视频ID
      String? videoId = _extractYouTubeVideoId(url);

      if (videoId == null) {
        Logger.w('Invalid YouTube URL: $url');
        return await _parseGeneric(url);
      }

      Logger.d('Extracted YouTube video ID: $videoId');

      // 1. 如果配置了 YouTube API 密钥，先走官方 Data API
      if (Constants.YOUTUBE_API_KEY.isNotEmpty) {
        try {
          final apiUrl =
              'https://www.googleapis.com/youtube/v3/videos?id=$videoId&part=snippet,contentDetails&key=${Constants.YOUTUBE_API_KEY}';
          final response = await http.get(
            Uri.parse(apiUrl),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(milliseconds: Constants.API_TIMEOUT));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['items'] != null && (data['items'] as List).isNotEmpty) {
              final item = data['items'][0];
              final snippet = item['snippet'];
              final contentDetails = item['contentDetails'];
              int? duration;
              if (contentDetails != null && contentDetails['duration'] != null) {
                duration = _parseDuration(contentDetails['duration']);
              }
              return VideoModel(
                id: videoId,
                title: snippet['title'] ?? 'YouTube Video',
                url: url,
                thumbnail: snippet['thumbnails']?['high']?['url'] ??
                    snippet['thumbnails']?['default']?['url'] ??
                    'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
                platform: 'YouTube',
                author: snippet['channelTitle'],
                authorUrl: 'https://www.youtube.com/channel/${snippet['channelId']}',
                duration: duration,
                qualities: _generateYouTubeQualities(videoId),
                formats: _generateYouTubeFormats(videoId),
                createdAt: DateTime.now(),
              );
            }
          }
        } catch (e) {
          Logger.w('YouTube Data API error: $e');
        }
      }

      // 2. 免费免鉴权方案：通过 YouTube oEmbed 接口解析标题、作者、高清封面
      try {
        final oembedUrl =
            'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
        final oembedResponse =
            await http.get(Uri.parse(oembedUrl)).timeout(const Duration(seconds: 6));
        if (oembedResponse.statusCode == 200) {
          final data = jsonDecode(oembedResponse.body);
          final title = data['title'] as String?;
          final authorName = data['author_name'] as String?;
          final authorUrl = data['author_url'] as String?;
          final thumb = (data['thumbnail_url'] as String?) ??
              'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

          return VideoModel(
            id: videoId,
            title: (title != null && title.isNotEmpty) ? title : 'YouTube Video ($videoId)',
            url: url,
            thumbnail: thumb,
            platform: 'YouTube',
            author: authorName,
            authorUrl: authorUrl,
            qualities: _generateYouTubeQualities(videoId),
            formats: _generateYouTubeFormats(videoId),
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        Logger.w('YouTube oEmbed parse error: $e');
      }

      // 3. 本地保底：根据 videoId 自动拼装高质量封面与清晰度选项
      return VideoModel(
        id: videoId,
        title: 'YouTube Video ($videoId)',
        url: url,
        thumbnail: 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
        platform: 'YouTube',
        qualities: _generateYouTubeQualities(videoId),
        formats: _generateYouTubeFormats(videoId),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      Logger.e('Error parsing YouTube video: $e');
      return await _parseGeneric(url);
    }
  }

  /// 提取YouTube视频ID
  ///
  /// [url] YouTube视频链接
  /// 返回视频ID，如果无法提取则返回null
  String? _extractYouTubeVideoId(String url) {
    // 标准 watch 格式: watch?v=ID
    final m1 = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (m1 != null) return m1.group(1);

    // 短链格式 youtu.be/ID
    final m2 = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (m2 != null) return m2.group(1);

    // shorts / embed / live 格式
    final m3 = RegExp(r'youtube\.com/(?:embed|shorts|live|v)/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (m3 != null) return m3.group(1);

    return null;
  }

  /// 解析ISO 8601时长格式
  ///
  /// [isoDuration] ISO 8601格式的时长字符串，例如 "PT1H30M15S"
  /// 返回总秒数
  int _parseDuration(String isoDuration) {
    // 匹配小时、分钟和秒
    RegExp hourRegExp = RegExp(r'(\d+)H');
    RegExp minuteRegExp = RegExp(r'(\d+)M');
    RegExp secondRegExp = RegExp(r'(\d+)S');

    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    // 提取小时
    Match? hourMatch = hourRegExp.firstMatch(isoDuration);
    if (hourMatch != null && hourMatch.groupCount >= 1) {
      hours = int.parse(hourMatch.group(1)!);
    }

    // 提取分钟
    Match? minuteMatch = minuteRegExp.firstMatch(isoDuration);
    if (minuteMatch != null && minuteMatch.groupCount >= 1) {
      minutes = int.parse(minuteMatch.group(1)!);
    }

    // 提取秒
    Match? secondMatch = secondRegExp.firstMatch(isoDuration);
    if (secondMatch != null && secondMatch.groupCount >= 1) {
      seconds = int.parse(secondMatch.group(1)!);
    }

    // 计算总秒数
    return hours * 3600 + minutes * 60 + seconds;
  }

  /// 生成YouTube视频质量选项
  ///
  /// [videoId] YouTube视频ID
  /// 返回质量选项列表
  List<VideoQuality> _generateYouTubeQualities(String videoId) {
    // 这里我们生成常见的YouTube质量选项
    // 实际应用中，可能需要通过其他API或库获取真实的质量选项
    return [
      VideoQuality(
        label: '1080P',
        height: 1080,
        width: 1920,
        bitrate: 8000000,
        url: 'https://www.youtube.com/watch?v=$videoId&quality=hd1080',
      ),
      VideoQuality(
        label: '720P',
        height: 720,
        width: 1280,
        bitrate: 5000000,
        url: 'https://www.youtube.com/watch?v=$videoId&quality=hd720',
      ),
      VideoQuality(
        label: '480P',
        height: 480,
        width: 854,
        bitrate: 2500000,
        url: 'https://www.youtube.com/watch?v=$videoId&quality=large',
      ),
      VideoQuality(
        label: '360P',
        height: 360,
        width: 640,
        bitrate: 1000000,
        url: 'https://www.youtube.com/watch?v=$videoId&quality=medium',
      ),
    ];
  }

  /// 生成YouTube视频格式选项
  ///
  /// [videoId] YouTube视频ID
  /// 返回格式选项列表
  List<VideoFormat> _generateYouTubeFormats(String videoId) {
    // 这里我们生成常见的YouTube格式选项
    // 实际应用中，可能需要通过其他API或库获取真实的格式选项
    return [
      VideoFormat(
        label: 'MP4',
        mimeType: 'video/mp4',
        url: 'https://www.youtube.com/watch?v=$videoId&fmt=18',
      ),
      VideoFormat(
        label: 'WebM',
        mimeType: 'video/webm',
        url: 'https://www.youtube.com/watch?v=$videoId&fmt=43',
      ),
      VideoFormat(
        label: 'MP3',
        mimeType: 'audio/mp3',
        url: 'https://www.youtube.com/watch?v=$videoId&fmt=140',
      ),
    ];
  }

  /// 解析Bilibili视频
  ///
  /// [url] Bilibili视频链接
  /// 返回解析后的视频模型
  Future<VideoModel?> _parseBilibili(String url) async {
    try {
      final bvMatch = RegExp(r'(BV[a-zA-Z0-9]+)').firstMatch(url);
      final bvid = bvMatch?.group(1);
      final avMatch = RegExp(r'av(\d+)').firstMatch(url);
      final aid = avMatch?.group(1);

      if (bvid != null || aid != null) {
        final queryParam = bvid != null ? 'bvid=$bvid' : 'aid=$aid';
        final apiUrl = 'https://api.bilibili.com/x/web-interface/view?$queryParam';
        try {
          final response = await http.get(Uri.parse(apiUrl), headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          }).timeout(const Duration(seconds: 6));

          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            if (json['code'] == 0 && json['data'] != null) {
              final data = json['data'];
              final idStr = (bvid ?? aid)!;
              return VideoModel(
                id: idStr,
                title: data['title'] ?? 'Bilibili Video',
                url: url,
                thumbnail: data['pic'],
                platform: 'Bilibili',
                author: data['owner']?['name'],
                authorUrl: data['owner']?['mid'] != null
                    ? 'https://space.bilibili.com/${data['owner']['mid']}'
                    : null,
                duration: _number(data['duration']),
                createdAt: DateTime.now(),
              );
            }
          }
        } catch (e) {
          Logger.w('Bilibili public api error: $e');
        }
      }

      return await _parseGeneric(url);
    } catch (e) {
      Logger.e('Error parsing Bilibili video: $e');
      return await _parseGeneric(url);
    }
  }

  /// 解析TikTok视频
  ///
  /// [url] TikTok视频链接
  /// 返回解析后的视频模型
  Future<VideoModel?> _parseTikTok(String url) async {
    try {
      final oembedUrl =
          'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}';
      try {
        final response =
            await http.get(Uri.parse(oembedUrl)).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return VideoModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: data['title'] ?? 'TikTok Video',
            url: url,
            thumbnail: data['thumbnail_url'],
            platform: 'TikTok',
            author: data['author_name'],
            authorUrl: data['author_url'],
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        Logger.w('TikTok oEmbed error: $e');
      }

      return await _parseGeneric(url);
    } catch (e) {
      Logger.e('Error parsing TikTok video: $e');
      return await _parseGeneric(url);
    }
  }

  /// 解析Instagram视频
  ///
  /// [url] Instagram视频链接
  /// 返回解析后的视频模型
  Future<VideoModel?> _parseInstagram(String url) async {
    try {
      return await _parseGeneric(url);
    } catch (e) {
      Logger.e('Error parsing Instagram video: $e');
      return null;
    }
  }

  /// 通用视频解析方法
  ///
  /// [url] 视频链接
  /// 返回解析后的视频模型
  Future<VideoModel?> _parseGeneric(String url) async {
    try {
      final uri = Uri.tryParse(url);
      final path = uri?.path.toLowerCase() ?? '';

      // 1. 如果本身就是视频直链（如 .mp4, .mov, .m4v, .m3u8, .flv, .webm）
      if (path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.m4v') ||
          path.endsWith('.webm') ||
          path.endsWith('.m3u8')) {
        final name = uri != null && uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'Video_${DateTime.now().millisecondsSinceEpoch}';
        return VideoModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: name,
          url: url,
          platform: 'DirectLink',
          createdAt: DateTime.now(),
        );
      }

      // 2. 尝试调用后端 /api/v1/videos/parse 接口（若用户已登录或后端支持）
      try {
        if (Get.isRegistered<ApiProvider>()) {
          final apiProvider = Get.find<ApiProvider>();
          final res = await apiProvider.parseVideo(url).timeout(const Duration(seconds: 6));
          if (res.isOk && res.body != null) {
            final body = res.body;
            final videoData = (body is Map<String, dynamic> && body.containsKey('data'))
                ? body['data']
                : body;
            if (videoData is Map<String, dynamic> && videoData.isNotEmpty) {
              return VideoModel.fromJson(videoData);
            }
          }
        }
      } catch (e) {
        Logger.w('Backend parse api failed: $e');
      }

      // 3. 通用 HTML OpenGraph / Twitter meta 标签解析
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final html = response.body;

          // 提取标题：优先 og:title / twitter:title，其次 <title>
          String? title;
          final ogTitle = RegExp(
                  r'<meta\s+[^>]*property=["\x27]og:title["\x27][^>]*content=["\x27]([^"\x27]+)["\x27]',
                  caseSensitive: false)
              .firstMatch(html) ??
              RegExp(r'<meta\s+[^>]*content=["\x27]([^"\x27]+)["\x27][^>]*property=["\x27]og:title["\x27]',
                      caseSensitive: false)
                  .firstMatch(html) ??
              RegExp(r'<meta\s+[^>]*name=["\x27]twitter:title["\x27][^>]*content=["\x27]([^"\x27]+)["\x27]',
                      caseSensitive: false)
                  .firstMatch(html);
          if (ogTitle != null) {
            title = ogTitle.group(1);
          } else {
            final titleMatch =
                RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false)
                    .firstMatch(html);
            title = titleMatch?.group(1);
          }

          // 提取封面：优先 og:image / twitter:image
          String? thumbnail;
          final ogImage = RegExp(
                  r'<meta\s+[^>]*property=["\x27]og:image["\x27][^>]*content=["\x27]([^"\x27]+)["\x27]',
                  caseSensitive: false)
              .firstMatch(html) ??
              RegExp(r'<meta\s+[^>]*content=["\x27]([^"\x27]+)["\x27][^>]*property=["\x27]og:image["\x27]',
                      caseSensitive: false)
                  .firstMatch(html) ??
              RegExp(r'<meta\s+[^>]*name=["\x27]twitter:image["\x27][^>]*content=["\x27]([^"\x27]+)["\x27]',
                      caseSensitive: false)
                  .firstMatch(html);
          if (ogImage != null) {
            thumbnail = ogImage.group(1);
          }

          if (title != null && title.trim().isNotEmpty) {
            final cleanTitle = title.replaceAll(RegExp(r'\s+'), ' ').trim();
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: cleanTitle,
              url: url,
              thumbnail: thumbnail,
              platform: _detectPlatform(url) ?? 'Web',
              createdAt: DateTime.now(),
            );
          }
        }
      } catch (e) {
        Logger.w('HTML open graph parse error: $e');
      }

      // 4. 终极兜底：根据 URL 路径生成条目
      final urlHost = uri?.host ?? 'Web';
      final pathLast = uri != null && uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'Video';
      return VideoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '$urlHost - $pathLast',
        url: url,
        platform: _detectPlatform(url) ?? 'Web',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      Logger.e('Error in generic parser: $e');
      return null;
    }
  }
}
