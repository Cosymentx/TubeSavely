import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/video_converter_service.dart';
import '../../../services/video_processing/video_processing_factory.dart';
import '../../../utils/logger.dart';
import '../../../utils/utils.dart';

/// 桌面端专属转换主页面（完全兼容原生桌面端布局，对应截图 2 与截图 5）
class DesktopConvertView extends StatefulWidget {
  const DesktopConvertView({super.key});

  @override
  State<DesktopConvertView> createState() => _DesktopConvertViewState();
}

class _DesktopConvertViewState extends State<DesktopConvertView>
    with AutomaticKeepAliveClientMixin {
  final VideoConverterService _converterService = Get.find<VideoConverterService>();

  String _targetFormat = 'AVI';
  final List<String> _formats = [
    'AVI',
    'MP4',
    'MKV',
    'MOV',
    'WEBM',
    'MP3',
    'AAC',
    'FLAC',
    'WAV',
  ];

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickVideoFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'pick_video'.tr,
        type: FileType.custom,
        allowedExtensions: [
          'mp4', 'mkv', 'mov', 'avi', 'flv', 'webm', 'ts', 'wmv', 'm4v', '3gp', 'rmvb'
        ],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null && file.path!.isNotEmpty) {
            await _converterService.createTask(
              sourceFilePath: file.path!,
              format: _targetFormat.toLowerCase(),
              resolution: '720p',
            );
          }
        }
      }
    } catch (e) {
      Logger.e('Error picking video file: $e');
      Utils.showSnackbar('error'.tr, e.toString());
    }
  }

  void _openFileDirectory(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    final dir = file.parent.path;

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
          // 顶部操作栏（添加视频 / 转换成：AVI ▾）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                onPressed: _pickVideoFiles,
                child: Text(
                  'add_video'.tr,
                  style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'convert_to'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildFormatDropdown(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 主内容大卡片容器（细边框，圆角 8）
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor.withOpacity(0.4), width: 0.8),
              ),
              child: Obx(() {
                final tasks = _converterService.conversionTasks;
                if (tasks.isEmpty) {
                  // 空状态：居中大红胶囊按钮【选择视频】（截图 2）
                  return Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                      ),
                      onPressed: _pickVideoFiles,
                      child: Text(
                        'pick_video'.tr,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                }

                // 任务列表（截图 5）
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(task, key: ValueKey(task.id));
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        value: _targetFormat,
        items: _formats
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _targetFormat = val;
            });
          }
        },
        buttonStyleData: const ButtonStyleData(
          height: 30,
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(ConversionTask task, {Key? key}) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final fileName = task.sourceFilePath.split(Platform.pathSeparator).last;
    final isConverting = task.status == ConversionStatus.converting;
    final isCompleted = task.status == ConversionStatus.completed;
    final isFailed = task.status == ConversionStatus.failed;

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
          // 左侧 130x94 缩略图（截图 5）
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: Container(
              width: 130,
              height: 94,
              color: primaryColor.withOpacity(0.08),
              child: Center(
                child: Image.asset(
                  'assets/images/ic_logo.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 中间文件信息与进度条
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    isFailed
                        ? '${'convert_failed'.tr}: ${task.errorMessage ?? ""}'
                        : (isCompleted
                            ? 'convert_success'.tr
                            : (isConverting
                                ? ((task.statusMessage?.isNotEmpty ?? false)
                                    ? task.statusMessage!
                                    : 'converting'.tr)
                                : (task.sourceFilePath ?? ''))),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isFailed
                          ? Colors.red.shade600
                          : (isCompleted
                              ? Colors.green.shade600
                              : theme.colorScheme.onSurface.withOpacity(0.45)),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: isCompleted ? 1.0 : task.progress,
                            minHeight: 2.5,
                            backgroundColor: primaryColor.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFailed ? Colors.red : (isCompleted ? Colors.green : primaryColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isCompleted
                            ? '100%'
                            : '${(task.progress * 100).toStringAsFixed(0)}%',
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

          // 右侧操作按钮组（重新转换 / 打开文件夹 / 删除）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 24,
                splashRadius: 22,
                tooltip: isConverting
                    ? 'cancel'.tr
                    : (isFailed ? 'retry'.tr : (isCompleted ? 'completed'.tr : 'convert_now'.tr)),
                icon: isConverting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: primaryColor),
                      )
                    : Icon(
                        isCompleted
                            ? Icons.check_circle_outline
                            : (isFailed ? Icons.replay : Icons.play_arrow_rounded),
                        color: isCompleted
                            ? Colors.green.shade600
                            : (isFailed ? Colors.red.shade600 : primaryColor),
                      ),
                onPressed: isConverting
                    ? () => _converterService.cancelTask(task.id)
                    : () {
                        _converterService.createTask(
                          sourceFilePath: task.sourceFilePath,
                          format: task.format,
                          resolution: task.resolution,
                          bitrate: task.bitrate,
                        );
                      },
              ),
              IconButton(
                iconSize: 24,
                splashRadius: 22,
                tooltip: '打开所在目录',
                icon: Icon(
                  Icons.folder_open,
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
                onPressed: () => _openFileDirectory(task.targetFilePath),
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
                  _converterService.deleteTask(task.id, deleteFile: false);
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
