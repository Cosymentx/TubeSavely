import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/download_task_model.dart';
import '../../../data/models/video_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/repositories/video_repository.dart';
import '../../../services/download_service.dart';
import '../../../services/media_download_request.dart';
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
  final VideoRepository _videoRepository = Get.find<VideoRepository>();

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

      String url = text;
      final urlReg = RegExp(r'https?://[^\s\u4e00-\u9fa5]+');
      final match = urlReg.firstMatch(text);
      if (match != null) {
        url = match.group(0)!;
      } else if (!text.startsWith('http://') && !text.startsWith('https://')) {
        Utils.showSnackbar('tips'.tr, 'toast_link_invalid'.tr);
        return;
      }

      if (_items.any((item) => item.video.url == url)) {
        Utils.showSnackbar('tips'.tr, 'toast_link_exists'.tr);
        return;
      }

      setState(() {
        _isParsing = true;
      });

      // 优先调用 VideoRepository 进行解析（本地解析器优先，后端 API 回退）
      final video = await _videoRepository.parseVideo(url).timeout(
            const Duration(seconds: 12),
            onTimeout: () => null,
          );

      if (video != null) {
        setState(() {
          _items.add(DesktopDownloadItem(
            video: video,
            statusText: 'status_download_progress'.tr,
          ));
        });
      } else {
        // 本地降级：直接以 URL 作为单任务加入列表
        final rawTitle = url.split('?').first.split('/').last.trim();
        final fallbackTitle = rawTitle.isNotEmpty
            ? rawTitle
            : 'Video_${DateTime.now().millisecondsSinceEpoch}';
        setState(() {
          _items.add(DesktopDownloadItem(
            video: VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: fallbackTitle,
              url: url,
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

  String _sanitizeFileName(String name) {
    String clean = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]+'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length > 80) {
      clean = clean.substring(0, 80).trim();
    }
    return clean.isEmpty
        ? 'Video_${DateTime.now().millisecondsSinceEpoch}'
        : clean;
  }

  Future<String?> _getYtDlpPath() async {
    const candidatePaths = [
      '/usr/local/bin/yt-dlp',
      '/opt/homebrew/bin/yt-dlp',
      '/usr/bin/yt-dlp',
    ];
    for (final p in candidatePaths) {
      if (await File(p).exists()) return p;
    }
    try {
      final res = await Process.run('which', ['yt-dlp']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        final p = res.stdout.toString().trim();
        if (await File(p).exists()) return p;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _downloadViaHttp(
      String downloadUrl, String targetPath, DesktopDownloadItem item,
      {MediaDownloadRequest? mediaRequest}) async {
    final client = http.Client();
    try {
      final request = http.Request(mediaRequest?.method ?? 'GET',
          Uri.parse(mediaRequest?.url ?? downloadUrl));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      if (mediaRequest != null) {
        request.headers.addAll(mediaRequest.headers);
        if (mediaRequest.body != null)
          request.body = jsonEncode(mediaRequest.body);
      }
      final response = await client.send(request);

      if (response.statusCode >= 400) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/') || contentType.contains('json')) {
        throw Exception('URL returned HTML webpage, not a direct media file');
      }

      final total = response.contentLength ?? 0;
      int received = 0;
      final file = File(targetPath);
      final sink = file.openWrite();
      DateTime lastUpdate = DateTime.now();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        final now = DateTime.now();
        if (total > 0 && now.difference(lastUpdate).inMilliseconds >= 250) {
          lastUpdate = now;
          if (mounted) {
            setState(() {
              item.progress = (received / total).clamp(0.0, 1.0);
              item.statusText = '${(item.progress * 100).toStringAsFixed(1)}%';
            });
          }
        }
      }

      await sink.flush();
      await sink.close();
      if (received == 0) throw StateError('The downloaded media file is empty');

      if (mounted) {
        setState(() {
          item.isDownloading = false;
          item.progress = 1.0;
          item.statusText = 'status_complete'.tr;
          item.localPath = targetPath;
        });
      }
    } catch (e) {
      // 如果下载失败或下载了无效文件，删除半成品/无效文件
      try {
        final f = File(targetPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> _startDownload(DesktopDownloadItem item) async {
    if (item.isDownloading) return;

    final saveDir = _storage.getDownloadPath();
    final dir = Directory(saveDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final cleanTitle = _sanitizeFileName(item.video.title);
    final targetPath = '$saveDir/$cleanTitle.mp4';

    setState(() {
      item.isDownloading = true;
      item.progress = 0.0;
      item.statusText = 'downloading'.tr;
      item.localPath = targetPath;
    });

    final mediaRequest = MediaDownloadRequest.forVideo(
        item.video, _storage.getUserToken(),
        format: 'mp4');
    if (mediaRequest.method == 'POST') {
      try {
        await _downloadViaHttp(mediaRequest.url, targetPath, item,
            mediaRequest: mediaRequest);
      } catch (error) {
        if (mounted)
          setState(() {
            item.isDownloading = false;
            item.statusText = 'status_failed'.tr;
          });
        Utils.showSnackbar('error'.tr, '视频下载失败，请重新解析后重试。');
      }
      return;
    }
    final ytDlpPath = await _getYtDlpPath();
    final isDirectMedia = item.video.url.toLowerCase().endsWith('.mp4') ||
        item.video.url.toLowerCase().endsWith('.mov') ||
        item.video.url.toLowerCase().endsWith('.m4v') ||
        item.video.url.toLowerCase().endsWith('.webm');

    if (ytDlpPath != null && !isDirectMedia) {
      // 检查 Chrome Cookie 是否存在，如果存在则传递 --cookies-from-browser chrome 免登录解析与下载
      final chromeCookieFile = File(
          '${Platform.environment['HOME']}/Library/Application Support/Google/Chrome/Default/Cookies');
      final hasChromeCookies = await chromeCookieFile.exists();

      final attemptArgsList = <List<String>>[];
      if (hasChromeCookies) {
        attemptArgsList.add([
          '--newline',
          '--no-part',
          '--cookies-from-browser',
          'chrome',
          '-f',
          'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
          '--merge-output-format',
          'mp4',
          '-o',
          targetPath,
          item.video.url,
        ]);
      }
      attemptArgsList.add([
        '--newline',
        '--no-part',
        '-f',
        'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
        '--merge-output-format',
        'mp4',
        '-o',
        targetPath,
        item.video.url,
      ]);

      for (final args in attemptArgsList) {
        try {
          Logger.d('Starting yt-dlp download: $ytDlpPath ${args.join(' ')}');
          final process = await Process.start(ytDlpPath, args);
          DateTime lastSetState = DateTime.now();

          process.stdout.transform(utf8.decoder).listen((line) {
            final pctMatch =
                RegExp(r'\[download\]\s+([\d\.]+)%').firstMatch(line);
            final speedMatch =
                RegExp(r'at\s+([^\s]+(?:KiB|MiB|GiB|B)/s)').firstMatch(line);
            final etaMatch = RegExp(r'ETA\s+([\d:]+)').firstMatch(line);

            if (pctMatch != null) {
              final pct = double.tryParse(pctMatch.group(1) ?? '0') ?? 0.0;
              final now = DateTime.now();
              if (now.difference(lastSetState).inMilliseconds >= 250 ||
                  pct >= 100.0) {
                lastSetState = now;
                if (mounted) {
                  setState(() {
                    item.progress = (pct / 100.0).clamp(0.0, 1.0);
                    String info = '${pct.toStringAsFixed(1)}%';
                    if (speedMatch != null) info += ' | ${speedMatch.group(1)}';
                    if (etaMatch != null)
                      info += ' | ETA: ${etaMatch.group(1)}';
                    item.statusText = info;
                  });
                }
              }
            }
          });

          final exitCode = await process.exitCode;
          if (exitCode == 0 && await File(targetPath).exists()) {
            if (mounted) {
              setState(() {
                item.isDownloading = false;
                item.progress = 1.0;
                item.statusText = 'status_complete'.tr;
              });
            }
            return;
          } else {
            Logger.w('yt-dlp exited with $exitCode');
          }
        } catch (e) {
          Logger.e('Error with yt-dlp attempt: $e');
        }
      }
    }

    // 回退到流式 HTTP 直链下载（仅针对包含真实视频直链的地址）
    try {
      String downloadUrl = item.video.url;
      if (item.video.qualities.isNotEmpty &&
          item.video.qualities.first.url.startsWith('http') &&
          !item.video.qualities.first.url.contains('youtube.com/watch')) {
        downloadUrl = item.video.qualities.first.url;
      }
      await _downloadViaHttp(downloadUrl, targetPath, item);
    } catch (e) {
      Logger.e('Error downloading video: $e');
      if (mounted) {
        setState(() {
          item.isDownloading = false;
          item.statusText = 'status_failed'.tr;
        });
      }
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
    if (filePath != null && await File(filePath).exists()) {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
        return;
      }
    }
    final dir = filePath != null
        ? File(filePath).parent.path
        : _storage.getDownloadPath();
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                onPressed: _isParsing ? null : _pasteAndParseLink,
                child: _isParsing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryColor),
                      )
                    : Text(
                        'parse_link'.tr,
                        style: TextStyle(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor, width: 0.8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                onPressed: _downloadAll,
                child: Text(
                  'download_now'.tr,
                  style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
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
                border: Border.all(
                    color: theme.dividerColor.withOpacity(0.4), width: 0.8),
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
                        final item = _items[index];
                        return _buildDownloadItemCard(item,
                            key:
                                ValueKey('${item.video.url}_${item.video.id}'));
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItemCard(DesktopDownloadItem item, {Key? key}) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      key: key,
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
              child: item.video.thumbnail != null &&
                      item.video.thumbnail!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.video.thumbnail!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.dividerColor.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: primaryColor),
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
                    item.video.title.isNotEmpty
                        ? item.video.title
                        : 'video.mp4',
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryColor),
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
                iconSize: 24,
                splashRadius: 22,
                tooltip: item.isDownloading ? 'downloading'.tr : 'download'.tr,
                icon: Icon(
                  item.isDownloading
                      ? Icons.hourglass_top
                      : Icons.file_download_outlined,
                  color: primaryColor,
                ),
                onPressed: () => _startDownload(item),
              ),
              IconButton(
                iconSize: 24,
                splashRadius: 22,
                tooltip: '打开所在目录',
                icon: Icon(
                  Icons.folder_open,
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
                onPressed: () => _openFileDirectory(item.localPath),
              ),
              IconButton(
                iconSize: 24,
                splashRadius: 22,
                tooltip: 'delete',
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
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
