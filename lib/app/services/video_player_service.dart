import 'dart:io';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../data/models/video_model.dart';
import '../utils/logger.dart';

/// 播放器状态
enum PlayerStatus {
  idle, // 空闲
  loading, // 加载中
  playing, // 播放中
  paused, // 暂停
  completed, // 播放完成
  error // 错误
}

/// 视频播放服务
///
/// 负责管理视频播放，包括播放、暂停、停止等操作
class VideoPlayerService extends GetxService {
  // 播放器实例
  Player? _player;
  VideoController? _videoController;

  // 当前播放状态
  final Rx<PlayerStatus> status = PlayerStatus.idle.obs;

  // 当前播放视频
  final Rx<VideoModel?> currentVideo = Rx<VideoModel?>(null);

  // 当前播放URL
  final RxString currentUrl = ''.obs;

  // 当前播放进度
  final RxDouble position = 0.0.obs;

  // 视频总时长
  final RxDouble duration = 0.0.obs;

  // 音量
  final RxDouble volume = 1.0.obs;

  // 是否静音
  final RxBool isMuted = false.obs;

  // 是否全屏
  final RxBool isFullscreen = false.obs;

  /// 初始化服务
  Future<VideoPlayerService> init() async {
    Logger.d('VideoPlayerService initializing...');

    try {
      // 创建播放器实例
      _player = Player();
      Logger.d('Player instance created');

      // 监听播放状态
      _player?.stream.playing.listen((playing) {
        Logger.d('Player playing state changed: $playing');
        if (playing) {
          status.value = PlayerStatus.playing;
          Logger.d('Status set to playing');
        } else {
          if (status.value != PlayerStatus.error &&
              status.value != PlayerStatus.completed) {
            status.value = PlayerStatus.paused;
            Logger.d('Status set to paused');
          }
        }
      });

      // 监听播放位置
      _player?.stream.position.listen((pos) {
        position.value = pos.inMilliseconds / 1000;
      });

      // 监听视频总时长
      _player?.stream.duration.listen((dur) {
        duration.value = dur.inMilliseconds / 1000;
        Logger.d('Video duration updated: ${duration.value} seconds');
      });

      // 监听播放完成
      _player?.stream.completed.listen((completed) {
        Logger.d('Player completed: $completed');
        if (completed) {
          status.value = PlayerStatus.completed;
          Logger.d('Status set to completed');
        }
      });

      // 监听音量变化
      _player?.stream.volume.listen((vol) {
        volume.value = vol;
        isMuted.value = vol == 0;
      });

      // 监听播放器错误
      _player?.stream.error.listen((error) {
        Logger.e('Player error: $error');
        status.value = PlayerStatus.error;
      });

      Logger.d('VideoPlayerService initialized successfully');
      return this;
    } catch (e) {
      Logger.e('Error initializing VideoPlayerService: $e');
      rethrow;
    }
  }

  /// 创建视频控制器
  ///
  /// 用于在UI中显示视频
  VideoController createVideoController() {
    if (_player == null) {
      throw Exception('Player not initialized');
    }

    _videoController = VideoController(_player!);
    return _videoController!;
  }

  /// 播放视频
  ///
  /// [url] 视频URL
  /// [video] 视频模型（可选）
  Future<void> play({required String url, VideoModel? video}) async {
    try {
      Logger.d('VideoPlayerService.play called with URL: $url');

      if (_player == null) {
        Logger.e('Player not initialized');
        throw Exception('Player not initialized');
      }

      // 检查URL是否是YouTube链接
      bool isYouTubeUrl =
          url.contains('youtube.com') || url.contains('youtu.be');

      // 如果是同一个URL，但是是YouTube链接，我们需要重新加载
      // 因为YouTube链接需要通过播放器解析为实际的视频流URL
      if (url == currentUrl.value && !isYouTubeUrl) {
        Logger.d(
            'Same URL detected, but not a YouTube link, continuing playback');
        _player!.play();
        return;
      } else if (url == currentUrl.value && isYouTubeUrl) {
        Logger.d(
            'Same YouTube URL detected, but we need to reload it to get the actual stream');
      }

      // 更新当前视频和URL
      currentVideo.value = video;
      currentUrl.value = url;
      Logger.d('Updated current video and URL');

      // 设置状态为加载中
      status.value = PlayerStatus.loading;
      Logger.d('Set status to loading');

      // 停止任何当前播放
      _player!.stop();
      Logger.d('Stopped any current playback');

      // 打开媒体
      Logger.d('Opening media: $url');

      // 对于YouTube链接，我们需要使用特殊的处理
      if (isYouTubeUrl) {
        Logger.d('Detected YouTube URL, using special handling');
        // 对于YouTube链接，我们需要确保每次都重新加载
        // 使用普通的Media构造函数，但确保每次都是新的实例
        await _player!.open(Media(url));
      } else {
        // 对于其他链接，使用普通的Media构造函数
        await _player!.open(Media(url));
      }

      Logger.d('Media opened successfully');

      // 开始播放
      Logger.d('Starting playback');
      await _player!.play();
      Logger.d('Playback started');

      // 确保状态更新为播放中
      if (status.value == PlayerStatus.loading) {
        Logger.d('Manually updating status to playing');
        status.value = PlayerStatus.playing;
      }
    } catch (e) {
      Logger.e('Error playing video: $e');
      status.value = PlayerStatus.error;
      rethrow;
    }
  }

  /// 播放本地视频
  ///
  /// [filePath] 本地视频文件路径
  Future<void> playLocalFile(String filePath) async {
    try {
      if (_player == null) {
        throw Exception('Player not initialized');
      }

      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // 更新当前URL
      currentUrl.value = filePath;
      currentVideo.value = null;

      // 设置状态为加载中
      status.value = PlayerStatus.loading;

      // 打开媒体
      await _player!.open(Media(filePath));

      // 开始播放
      _player!.play();
    } catch (e) {
      Logger.e('Error playing local file: $e');
      status.value = PlayerStatus.error;
      rethrow;
    }
  }

  /// 暂停播放
  void pause() {
    if (_player != null && status.value == PlayerStatus.playing) {
      _player!.pause();
    }
  }

  /// 继续播放
  void resume() {
    if (_player != null && status.value == PlayerStatus.paused) {
      _player!.play();
    }
  }

  /// 停止播放
  Future<void> stop() async {
    if (_player != null) {
      Logger.d('Stopping playback');
      try {
        // 先暂停播放
        _player!.pause();
        Logger.d('Playback paused');

        // 然后停止播放
        await _player!.stop();
        Logger.d('Playback stopped');

        // 重置状态
        status.value = PlayerStatus.idle;
        position.value = 0;
        duration.value = 0;
        currentUrl.value = '';
        currentVideo.value = null;
        Logger.d('Player state reset');
      } catch (e) {
        Logger.e('Error stopping playback: $e');
      }
    }
  }

  /// 跳转到指定位置
  ///
  /// [seconds] 秒数
  Future<void> seekTo(double seconds) async {
    if (_player != null) {
      await _player!.seek(Duration(milliseconds: (seconds * 1000).toInt()));
    }
  }

  /// 设置音量
  ///
  /// [value] 音量值，范围 0.0 - 1.0
  Future<void> setVolume(double value) async {
    if (_player != null) {
      await _player!.setVolume(value);
    }
  }

  /// 静音/取消静音
  Future<void> toggleMute() async {
    if (_player != null) {
      if (isMuted.value) {
        // 取消静音，恢复之前的音量
        await _player!.setVolume(volume.value > 0 ? volume.value : 1.0);
      } else {
        // 静音
        await _player!.setVolume(0);
      }
    }
  }

  /// 切换全屏状态
  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
  }

  /// 设置播放速度
  ///
  /// [speed] 播放速度，例如 0.5, 1.0, 1.5, 2.0
  Future<void> setPlaybackSpeed(double speed) async {
    if (_player != null) {
      await _player!.setRate(speed);
    }
  }

  /// 禁用字幕
  Future<void> disableSubtitles() async {
    // 由于媒体套件的限制，这里只是一个占位方法
    // 实际实现需要根据具体的播放器库来处理
    Logger.d('Disabling subtitles (placeholder)');
  }

  /// 设置字幕
  ///
  /// [subtitleId] 字幕ID
  Future<void> setSubtitle(String subtitleId) async {
    // 由于媒体套件的限制，这里只是一个占位方法
    // 实际实现需要根据具体的播放器库来处理
    Logger.d('Setting subtitle: $subtitleId (placeholder)');
  }

  /// 释放资源
  @override
  void onClose() {
    _player?.dispose();
    _player = null;
    _videoController = null;
    super.onClose();
  }
}
