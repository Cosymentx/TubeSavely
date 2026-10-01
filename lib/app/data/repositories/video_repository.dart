import 'package:get/get.dart';
import '../models/video_model.dart';
import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';
import '../../services/video_parser_service.dart';
import '../../utils/logger.dart';
import '../../utils/constants.dart';

class VideoRepository {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageProvider _storageProvider = Get.find<StorageProvider>();
  final VideoParserService _videoParserService = Get.find<VideoParserService>();

  // 解析视频链接
  Future<VideoModel?> parseVideo(String url) async {
    try {
      final token = _storageProvider.getUserToken();
      final hasToken = token != null && token.isNotEmpty;

      // 如果用户已登录，优先调用后台解析接口获取完整画质与直链
      if (hasToken) {
        Logger.d('User logged in, trying backend API first for parsing: $url');
        final response = await _apiProvider.parseVideo(url);
        if (response.status.isOk && response.body != null) {
          final body = response.body;
          if (body is Map<String, dynamic>) {
            if (body['code'] == 200 && body['data'] is Map<String, dynamic>) {
              return VideoModel.fromJson(body['data'] as Map<String, dynamic>);
            }
            if (body.containsKey('title') || body.containsKey('qualities')) {
              return VideoModel.fromJson(body);
            }
          }
        }
        Logger.d('Backend API parse failed or returned empty, falling back to VideoParserService');
      }

      // 使用本地视频解析服务解析
      final videoModel = await _videoParserService.parseVideo(url);
      if (videoModel != null) {
        Logger.d('Video parsed successfully using VideoParserService');
        return videoModel;
      }

      // 如果未登录或本地解析服务未成功，尝试调用API解析
      if (!hasToken) {
        Logger.d('Falling back to API for video parsing');
        final response = await _apiProvider.parseVideo(url);
        if (response.status.isOk && response.body != null) {
          final body = response.body;
          if (body is Map<String, dynamic>) {
            if (body['code'] == 200 && body['data'] is Map<String, dynamic>) {
              return VideoModel.fromJson(body['data'] as Map<String, dynamic>);
            }
            return VideoModel.fromJson(body);
          }
        }
      }

      Logger.w('Failed to parse video: $url');
      return null;
    } catch (e) {
      Logger.e('Error parsing video: $e');
      return null;
    }
  }

  // 获取下载历史
  List<VideoModel> getDownloadHistory() {
    return _storageProvider.getDownloadHistory();
  }

  // 添加到下载历史
  Future<void> addToDownloadHistory(VideoModel video) async {
    await _storageProvider.addToDownloadHistory(video);
  }

  // 清除下载历史
  Future<void> clearDownloadHistory() async {
    await _storageProvider.clearDownloadHistory();
  }

  // 获取视频历史（从服务器）
  Future<List<VideoModel>> getVideoHistory({
    int offset = 1,
    int limit = 20,
  }) async {
    try {
      Logger.d('Getting video history from server');

      final response = await _apiProvider.getVideoHistory(
        offset: offset,
        limit: limit,
      );

      if (response.status.isOk) {
        final List<dynamic> data = response.body['data'] ?? [];
        return data.map((item) => VideoModel.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      Logger.e('Error getting video history from server: $e');
      return [];
    }
  }

  // 创建视频
  Future<bool> createVideo(VideoModel video) async {
    try {
      Logger.d('Creating video: ${video.title}');

      final response = await _apiProvider.createVideo(video.toJson());

      return response.status.isOk;
    } catch (e) {
      Logger.e('Error creating video: $e');
      return false;
    }
  }

  // 删除视频
  Future<bool> deleteVideo(String id) async {
    try {
      Logger.d('Deleting video: $id');

      final response = await _apiProvider.deleteVideo(int.parse(id));

      return response.status.isOk;
    } catch (e) {
      Logger.e('Error deleting video: $e');
      return false;
    }
  }

  // 获取支持的平台
  Future<List<Map<String, dynamic>>> getSupportedPlatforms() async {
    try {
      final response = await _apiProvider.getSupportedPlatforms();
      if (response.status.isOk) {
        return List<Map<String, dynamic>>.from(response.body);
      }
      return Constants.SUPPORTED_PLATFORMS;
    } catch (e) {
      return Constants.SUPPORTED_PLATFORMS;
    }
  }

  // 获取热门视频
  Future<List<VideoModel>> getTrendingVideos() async {
    try {
      final response = await _apiProvider.getTrendingVideos();
      if (response.status.isOk) {
        return (response.body as List)
            .map((item) => VideoModel.fromJson(item))
            .toList();
      }

      // 如果API调用失败，返回模拟数据
      return _getMockTrendingVideos();
    } catch (e) {
      Logger.e('Error getting trending videos: $e');
      // 返回模拟数据
      return _getMockTrendingVideos();
    }
  }

  // 获取模拟热门视频数据
  List<VideoModel> _getMockTrendingVideos() {
    return [
      VideoModel(
        id: '1',
        title: '如何使用Flutter构建跨平台应用',
        url: 'https://www.youtube.com/watch?v=example1',
        platform: 'YouTube',
        thumbnail: 'https://i.ytimg.com/vi/example1/maxresdefault.jpg',
        author: 'Flutter官方',
        duration: 1245, // 20:45
        qualities: [],
        formats: [],
      ),
      VideoModel(
        id: '2',
        title: '2023年最受欢迎的10款手机评测',
        url: 'https://www.youtube.com/watch?v=example2',
        platform: 'YouTube',
        thumbnail: 'https://i.ytimg.com/vi/example2/maxresdefault.jpg',
        author: '数码评测',
        duration: 1532, // 25:32
        qualities: [],
        formats: [],
      ),
      VideoModel(
        id: '3',
        title: '学习Dart语言的完整指南 - 从入门到精通',
        url: 'https://www.bilibili.com/video/example3',
        platform: 'Bilibili',
        thumbnail: 'https://i0.hdslb.com/bfs/archive/example3.jpg',
        author: '编程学习',
        duration: 3600, // 60:00
        qualities: [],
        formats: [],
      ),
      VideoModel(
        id: '4',
        title: '如何提高工作效率 - 时间管理技巧分享',
        url: 'https://www.youtube.com/watch?v=example4',
        platform: 'YouTube',
        thumbnail: 'https://i.ytimg.com/vi/example4/maxresdefault.jpg',
        author: '个人成长',
        duration: 845, // 14:05
        qualities: [],
        formats: [],
      ),
      VideoModel(
        id: '5',
        title: '2023年最佳旅游目的地推荐',
        url: 'https://www.bilibili.com/video/example5',
        platform: 'Bilibili',
        thumbnail: 'https://i0.hdslb.com/bfs/archive/example5.jpg',
        author: '旅行日记',
        duration: 1120, // 18:40
        qualities: [],
        formats: [],
      ),
    ];
  }
}
