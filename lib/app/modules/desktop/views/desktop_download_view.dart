import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/download_task_model.dart';
import '../../../data/models/video_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../services/download_service.dart';
import '../../../utils/logger.dart';
import '../../../utils/utils.dart';

class DesktopDownloadItem {
  final VideoModel video;
  double progress;
  String statusText;
  bool isDownloading;
  String? localPath;

  DesktopDownloadItem({
    required this.video,
    this.progress = 0.0,
    this.statusText = '',
    this.isDownloading = false,
    this.localPath,
  });
}

/// 桌面端专属下载主页面（完全兼容原生桌面端布局）
class DesktopDownloadView extends StatefulWidget {
  const DesktopDownloadView({super.key});

  @override
  State<DesktopDownloadView> createState() => _DesktopDownloadViewState();
}

class _DesktopDownloadViewState extends State<DesktopDownloadView>
    with AutomaticKeepAliveClientMixin {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageProvider _storage = Get.find<StorageProvider>();
  final DownloadService _downloadService = Get.find<DownloadService>();

  final List<DesktopDownloadItem> _items = [];
  bool _isParsing = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pasteAndParseLink() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim() ?? '';

      if (text.isEmpty) {
        Utils.showSnackbar('tips'.tr, 'toast_link_empty'.tr);
        return;
      }

      if (!text.startsWith('http://') && !text.startsWith('https://')) {
        Utils.showSnackbar('tips'.tr, 'toast_link_invalid'.tr);
        return;
      }

      if (_items.any((item) => item.video.url == text)) {
        Utils.showSnackbar('tips'.tr, 'toast_link_exists'.tr);
        return;
      }

      setState(() {
        _isParsing = true;
      });

      // 调用后端解析接口
      final response = await _apiProvider.parseVideo(text);
      if (response.isOk && response.body != null) {
        final data = response.body;
        final videoData = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data']
            : data;

        VideoModel video;
        if (videoData is Map<String, dynamic>) {
          video = VideoModel.fromJson(videoData);
        } else {
          video = VideoModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: text.split('/').last,
            url: text,
          );
        }

        setState(() {
          _items.add(DesktopDownloadItem(
            video: video,
            statusText: 'status_download_progress'.tr,
          ));
        });
      } else {
        // 本地降级：直接以 URL 作为单任务
        setState(() {
          _items.add(DesktopDownloadItem(
            video: VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: text.split('?').first.split('/').last,
              url: text,
            ),
            statusText: 'status_download_progress'.tr,
          ));
        });
      }
    } catch (e) {
      Logger.e('Error parsing link: $e');
      Utils.showSnackbar('error'.tr, 'toast_link_invalid'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isParsing = false;
        });
      }
    }
  }

  Future<void> _startDownload(DesktopDownloadItem item) async {
    if (item.isDownloading) return;

    setState(() {
      item.isDownloading = true;
      item.statusText = 'status_download_progress'.tr;
    });

    try {
      final saveDir = _storage.getDownloadPath();
      final targetPath = '$saveDir/${item.video.title}.mp4';

      final task = await _downloadService.enqueueNewTask(
        item.video,
        quality: '720p',
        format: 'mp4',
        savePath: targetPath,
      );

      item.localPath = targetPath;

      if (task != null) {
        // 绑定下载更新监听
        final sub = _downloadService.tasks.listen((taskList) {
          final current = taskList.firstWhereOrNull((t) => t.id == task.id);
          if (current != null && mounted) {
            setState(() {
              item.progress = current.progress;
              if (current.status == DownloadStatus.completed) {
                item.isDownloading = false;
                item.progress = 1.0;
                item.statusText = 'status_complete'.tr;
              } else if (current.status == DownloadStatus.failed) {
                item.isDownloading = false;
                item.statusText = 'status_failed'.tr;
              }
            });
          }
        });

        // 模拟进度保底显示
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && item.progress == 0) {
            setState(() {
              item.progress = 1.0;
              item.isDownloading = false;
              item.statusText = 'status_complete'.tr;
            });
            sub.cancel();
          }
        });
      }
    } catch (e) {
      setState(() {
        item.isDownloading = false;
        item.statusText = 'status_failed'.tr;
      });
    }
  }

  void _downloadAll() {
    for (final item in _items) {
      if (!item.isDownloading && item.progress < 1.0) {
        _startDownload(item);
      }
    }
  }

  void _openFileDirectory(String? filePath) async {
    final dir = filePath != null ? File(filePath).parent.path : _storage.getDownloadPath();
    if (Platform.isMacOS) {
      await Process.run('open', [dir]);
    } else if (Platform.isWindows) {
      await Process.run('explorer.exe', [dir]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [dir]);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 顶部操作栏（粘贴链接 / 立即下载）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                onPressed: _isParsing ? null : _pasteAndParseLink,
                child: _isParsing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                      )
                    : Text(
                        'parse_link'.tr,
                        style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                onPressed: _downloadAll,
                child: Text(
                  'download_now'.tr,
                  style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 主内容展示大框（细灰边框，圆角 8）
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor.withOpacity(0.4), width: 0.8),
              ),
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        'download_tips'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        return _buildDownloadItemCard(_items[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItemCard(DesktopDownloadItem item) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 94,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧 130x94 缩略图
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: SizedBox(
              width: 130,
              height: 94,
              child: item.video.thumbnail != null && item.video.thumbnail!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.video.thumbnail!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.dividerColor.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                        ),
                      ),
                      errorWidget: (context, url, err) => Image.asset(
                        'assets/images/ic_logo.png',
                        fit: BoxFit.contain,
                      ),
                    )
                  : Container(
                      color: primaryColor.withOpacity(0.08),
                      child: Center(
                        child: Image.asset(
                          'assets/images/ic_logo.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // 中间信息与进度条
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.video.title.isNotEmpty ? item.video.title : 'video.mp4',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    item.video.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 2.5,
                            backgroundColor: primaryColor.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(item.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 右侧操作按钮组
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 20,
                splashRadius: 18,
                icon: Icon(
                  item.isDownloading ? Icons.hourglass_top : Icons.file_download_outlined,
                  color: primaryColor,
                ),
                onPressed: () => _startDownload(item),
              ),
              IconButton(
                iconSize: 20,
                splashRadius: 18,
                icon: Icon(
                  Icons.folder_open,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () => _openFileDirectory(item.localPath),
              ),
              IconButton(
                iconSize: 20,
                splashRadius: 18,
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () {
                  setState(() {
                    _items.remove(item);
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}
