import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:tubesavely/app/data/models/video_model.dart';
import 'package:tubesavely/app/data/repositories/download_repository.dart';
import 'package:tubesavely/app/data/repositories/video_player_repository.dart';
import 'package:tubesavely/app/data/repositories/video_repository.dart';
import 'package:tubesavely/app/services/video_parser_service.dart';
import 'package:tubesavely/app/services/video_player_service.dart';
import 'package:tubesavely/app/utils/utils.dart';

import '../../../../utils/logger.dart';

class VideoDetailController extends GetxController {
  final VideoRepository _videoRepository = Get.find<VideoRepository>();
  final DownloadRepository _downloadRepository = Get.find<DownloadRepository>();
  final VideoPlayerRepository _videoPlayerRepository =
      Get.find<VideoPlayerRepository>();

  // 视频信息
  final Rx<VideoModel?> video = Rx<VideoModel?>(null);

  // 选中的清晰度和格式
  final RxString selectedQuality = '1080P'.obs;
  final RxString selectedFormat = 'MP4'.obs;

  // 下载状态
  final RxBool isDownloading = false.obs;

  // 视频播放状态
  final RxBool isPlaying = false.obs;

  // 视频控制器
  late final VideoController videoController;

  // 播放状态
  final Rx<PlayerStatus> playerStatus = PlayerStatus.idle.obs;

  // 是否显示控制器
  final RxBool showControls = true.obs;

  // 控制器隐藏计时器
  Timer? _hideControlsTimer;

  // 播放进度
  final RxDouble position = 0.0.obs;

  // 视频总时长
  final RxDouble duration = 0.0.obs;

  // 是否拖动进度条
  final RxBool isDraggingProgress = false.obs;

  // 拖动进度值
  final RxDouble dragProgress = 0.0.obs;

  // 音量
  final RxDouble volume = 1.0.obs;

  // 是否静音
  final RxBool isMuted = false.obs;

  // 是否全屏
  final RxBool isFullscreen = false.obs;

  @override
  void onInit() {
    super.onInit();
    Logger.d('VideoDetailController initialized');

    // 创建视频控制器
    videoController = _videoPlayerRepository.createVideoController();

    // 获取传递的参数
    if (Get.arguments != null && Get.arguments is VideoModel) {
      video.value = Get.arguments;

      // 设置默认清晰度和格式
      if (video.value!.qualities.isNotEmpty) {
        selectedQuality.value = video.value!.qualities.first.label;
      }

      if (video.value!.formats.isNotEmpty) {
        selectedFormat.value = video.value!.formats.first.label;
      }
    }

    // 定时更新播放状态和进度
    Timer.periodic(const Duration(milliseconds: 500), (_) {
      // 更新播放状态
      playerStatus.value = _videoPlayerRepository.status;
      isPlaying.value = _videoPlayerRepository.status == PlayerStatus.playing;

      // 更新播放进度
      position.value = _videoPlayerRepository.position;
      duration.value = _videoPlayerRepository.duration;

      // 更新音量
      volume.value = _videoPlayerRepository.volume;
      isMuted.value = _videoPlayerRepository.isMuted;
    });
  }

  @override
  void onClose() {
    // 停止播放
    if (isPlaying.value) {
      _videoPlayerRepository.stopVideo();
    }
    super.onClose();
  }

  // 初始化播放器
  // void initPlayer() {
  //   if (video.value != null && video.value!.qualities.isNotEmpty) {
  //     // 获取预览URL
  //     final previewUrl = video.value!.qualities.first.url;
  //
  //     // 创建播放器
  //     player.value = Player();
  //
  //     // 设置媒体
  //     player.value!.open(Media(previewUrl));
  //   }
  // }

  // 设置清晰度
  void setQuality(String quality) {
    selectedQuality.value = quality;
  }

  // 设置格式
  void setFormat(String format) {
    selectedFormat.value = format;
  }

  // 下载视频
  Future<void> downloadVideo() async {
    if (video.value == null) {
      Utils.showSnackbar('错误', '视频信息不完整', isError: true);
      return;
    }

    try {
      isDownloading.value = true;

      final task = await _downloadRepository.addDownloadTask(
        video.value!,
        quality: selectedQuality.value,
        format: selectedFormat.value,
      );

      if (task != null) {
        // 添加到下载历史
        await _videoRepository.addToDownloadHistory(video.value!);

        Utils.showSnackbar('成功', '已添加到下载队列');

        // 返回上一页
        Get.back();
      } else {
        Utils.showSnackbar('错误', '创建下载任务失败', isError: true);
      }
    } catch (e) {
      Logger.e('下载视频时出错: $e');
      Utils.showSnackbar('错误', '下载视频时出错: $e', isError: true);
    } finally {
      isDownloading.value = false;
    }
  }

  // 分享视频
  void shareVideo() {
    if (video.value == null) return;

    // 实现分享功能
    Utils.showSnackbar('提示', '分享功能尚未实现');
  }

  // 收藏视频
  void favoriteVideo() {
    if (video.value == null) return;

    // 实现收藏功能
    Utils.showSnackbar('提示', '收藏功能尚未实现');
  }

  // 播放视频
  Future<void> playVideo() async {
    if (video.value == null) {
      Logger.e('无法播放视频：视频信息为空');
      return;
    }

    try {
      Logger.d('开始播放视频: ${video.value!.title}');

      // 获取直接可播放的视频URL（不是YouTube页面URL）
      String videoUrl = '';

      // 检查是否有直接可播放的格式
      if (video.value!.formats.isNotEmpty) {
        // 查找直接可播放的格式（不是YouTube页面URL）
        for (var format in video.value!.formats) {
          if (format.url.contains('.mp4') ||
              format.url.contains('.m3u8') ||
              format.url.contains('.webm') ||
              !format.url.contains('youtube.com/watch')) {
            videoUrl = format.url;
            Logger.d('找到直接可播放的格式URL: $videoUrl');
            break;
          }
        }

        // 如果没有找到直接可播放的格式，使用第一个格式
        if (videoUrl.isEmpty && video.value!.formats.isNotEmpty) {
          videoUrl = video.value!.formats.first.url;
          Logger.d('使用格式列表中的第一个URL: $videoUrl');
        }
      }
      // 检查是否有直接可播放的质量
      else if (video.value!.qualities.isNotEmpty) {
        // 查找直接可播放的质量（不是YouTube页面URL）
        for (var quality in video.value!.qualities) {
          if (quality.url.contains('.mp4') ||
              quality.url.contains('.m3u8') ||
              quality.url.contains('.webm') ||
              !quality.url.contains('youtube.com/watch')) {
            videoUrl = quality.url;
            Logger.d('找到直接可播放的质量URL: $videoUrl');
            break;
          }
        }

        // 如果没有找到直接可播放的质量，使用第一个质量
        if (videoUrl.isEmpty && video.value!.qualities.isNotEmpty) {
          videoUrl = video.value!.qualities.first.url;
          Logger.d('使用质量列表中的第一个URL: $videoUrl');
        }
      }
      // 使用默认URL
      else {
        videoUrl = video.value!.url;
        Logger.d('使用视频默认URL: $videoUrl');
      }

      // 直接在当前页面播放视频
      if (videoUrl.isNotEmpty) {
        Logger.d('视频URL有效，准备播放');

        // 无论如何，先停止当前播放
        Logger.d('停止当前播放');
        await _videoPlayerRepository.stopVideo();

        // 等待一小段时间，确保播放器已经停止
        await Future.delayed(const Duration(milliseconds: 500));

        // 检查URL是否是YouTube页面URL
        if (videoUrl.contains('youtube.com/watch') ||
            videoUrl.contains('youtu.be')) {
          Logger.d('检测到YouTube URL，需要先解析实际的流URL');

          try {
            // 显示加载中提示
            Utils.showSnackbar('提示', '正在解析视频流，请稍候...');

            // 使用视频解析服务重新解析视频，获取实际的流URL
            final videoParserService = Get.find<VideoParserService>();
            final parsedVideo = await videoParserService.parseVideo(videoUrl);

            if (parsedVideo != null) {
              // 查找最佳的直接流URL
              String? directStreamUrl;

              // 首先检查是否有直接的流URL
              if (parsedVideo.formats.isNotEmpty) {
                // 查找MP4或M3U8格式的直接流URL
                for (var format in parsedVideo.formats) {
                  if ((format.url.contains('.mp4') ||
                          format.url.contains('.m3u8') ||
                          format.url.contains('.webm')) &&
                      !format.url.contains('youtube.com/watch')) {
                    directStreamUrl = format.url;
                    Logger.d('找到直接可播放的格式URL: $directStreamUrl');
                    break;
                  }
                }

                // 如果没有找到直接可播放的格式，但有格式列表，使用第一个
                if (directStreamUrl == null &&
                    parsedVideo.formats.isNotEmpty &&
                    !parsedVideo.formats.first.url
                        .contains('youtube.com/watch')) {
                  directStreamUrl = parsedVideo.formats.first.url;
                  Logger.d('使用格式列表中的第一个URL: $directStreamUrl');
                }
              }

              // 如果在格式中没有找到，检查质量列表
              if (directStreamUrl == null && parsedVideo.qualities.isNotEmpty) {
                // 查找MP4或M3U8格式的直接流URL
                for (var quality in parsedVideo.qualities) {
                  if ((quality.url.contains('.mp4') ||
                          quality.url.contains('.m3u8') ||
                          quality.url.contains('.webm')) &&
                      !quality.url.contains('youtube.com/watch')) {
                    directStreamUrl = quality.url;
                    Logger.d('找到直接可播放的质量URL: $directStreamUrl');
                    break;
                  }
                }

                // 如果没有找到直接可播放的质量，但有质量列表，使用第一个
                if (directStreamUrl == null &&
                    parsedVideo.qualities.isNotEmpty &&
                    !parsedVideo.qualities.first.url
                        .contains('youtube.com/watch')) {
                  directStreamUrl = parsedVideo.qualities.first.url;
                  Logger.d('使用质量列表中的第一个URL: $directStreamUrl');
                }
              }

              // 如果找到了直接流URL，使用它
              if (directStreamUrl != null) {
                videoUrl = directStreamUrl;
                Logger.d('成功解析到实际的流URL: $videoUrl');
              } else {
                Logger.e('无法解析YouTube视频的实际流URL');
                Utils.showSnackbar('错误', '无法解析YouTube视频的实际流URL', isError: true);
                return;
              }
            } else {
              Logger.e('解析视频失败，返回结果为空');
              Utils.showSnackbar('错误', '解析视频失败，返回结果为空', isError: true);
              return;
            }
          } catch (e) {
            Logger.e('解析YouTube视频流时出错: $e');
            Utils.showSnackbar('错误', '解析YouTube视频流时出错', isError: true);
            return;
          }
        }

        // 开始播放新视频
        Logger.d('开始播放新视频: $videoUrl');
        await _videoPlayerRepository.playVideo(
            url: videoUrl, video: video.value);

        Logger.d('视频播放请求已发送，设置播放状态为true');
        isPlaying.value = true;

        // 添加视频到下载历史（作为播放历史使用）
        try {
          await _videoRepository.addToDownloadHistory(video.value!);
          Logger.d('视频已添加到历史记录');
        } catch (historyError) {
          Logger.e('添加到历史记录时出错: $historyError');
        }
      } else {
        Logger.e('无法播放视频：未找到有效的视频链接');
        Utils.showSnackbar('错误', '无法播放视频，未找到有效的视频链接', isError: true);
      }
    } catch (e) {
      Logger.e('播放视频时出错: $e');
      Utils.showSnackbar('错误', '播放视频时出错: $e', isError: true);
      isPlaying.value = false;
    }
  }

  // 暂停/继续播放
  void togglePlayPause() {
    if (isPlaying.value) {
      _videoPlayerRepository.pauseVideo();
    } else {
      _videoPlayerRepository.resumeVideo();
    }
    _resetControlsTimer();
  }

  // 显示/隐藏控制器
  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _resetControlsTimer();
    } else if (_hideControlsTimer != null) {
      _hideControlsTimer!.cancel();
      _hideControlsTimer = null;
    }
  }

  // 重置控制器隐藏计时器
  void _resetControlsTimer() {
    if (_hideControlsTimer != null) {
      _hideControlsTimer!.cancel();
    }

    showControls.value = true;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (isPlaying.value) {
        showControls.value = false;
      }
    });
  }

  // 跳转到指定位置
  Future<void> seekTo(double seconds) async {
    await _videoPlayerRepository.seekTo(seconds);
    _resetControlsTimer();
  }

  // 快退10秒
  Future<void> rewind10Seconds() async {
    final newPosition = (position.value - 10).clamp(0.0, duration.value);
    await seekTo(newPosition.toDouble());
  }

  // 快进10秒
  Future<void> forward10Seconds() async {
    final newPosition = (position.value + 10).clamp(0.0, duration.value);
    await seekTo(newPosition.toDouble());
  }

  // 开始拖动进度条
  void startDraggingProgress(double value) {
    isDraggingProgress.value = true;
    dragProgress.value = value;
  }

  // 更新拖动进度
  void updateDragProgress(double value) {
    dragProgress.value = value;
  }

  // 结束拖动进度条
  Future<void> endDraggingProgress() async {
    if (duration.value > 0) {
      final seconds = dragProgress.value * duration.value;
      await seekTo(seconds);
    }
    isDraggingProgress.value = false;
  }

  // 切换静音
  Future<void> toggleMute() async {
    await _videoPlayerRepository.toggleMute();
    _resetControlsTimer();
  }

  // 切换全屏
  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
    _videoPlayerRepository.toggleFullscreen();
    _resetControlsTimer();
  }

  // 获取格式化的当前播放时间
  String getFormattedPosition() {
    return _videoPlayerRepository.getFormattedPosition();
  }

  // 获取格式化的视频总时长
  String getFormattedDuration() {
    return _videoPlayerRepository.getFormattedDuration();
  }
}
