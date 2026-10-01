import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/video_compress_model.dart';
import '../../../utils/logger.dart';
import '../../../utils/utils.dart';
import '../../video/compress/controllers/compress_controller.dart';

/// 桌面端专属视频压缩主页面（完全契合桌面端布局规范与风格）
class DesktopCompressView extends StatefulWidget {
  const DesktopCompressView({super.key});

  @override
  State<DesktopCompressView> createState() => _DesktopCompressViewState();
}

class _DesktopCompressViewState extends State<DesktopCompressView>
    with AutomaticKeepAliveClientMixin {
  late final CompressController _compressController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _compressController = Get.isRegistered<CompressController>()
        ? Get.find<CompressController>()
        : Get.put(CompressController());
  }

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
        final paths = result.files
            .map((f) => f.path)
            .whereType<String>()
            .where((p) => p.isNotEmpty)
            .toList();

        if (paths.isNotEmpty) {
          await _compressController.addAndStart(paths);
        }
      }
    } catch (e) {
      Logger.e('Error picking video file for compression: $e');
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

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
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
          // 顶部操作栏（添加视频、开始压缩 / 预设模式下拉）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(() {
                    final hasPending = _compressController.tasks.any(
                      (t) => t.status == CompressTaskStatus.pending,
                    );
                    final isProcessing = _compressController.isProcessing.value;

                    if (!hasPending && !isProcessing) {
                      return const SizedBox.shrink();
                    }

                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryColor.withOpacity(0.65),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () => _compressController.startBatchCompress(),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_arrow, size: 16),
                      label: Text(
                        isProcessing ? 'compressing'.tr : 'start_compress'.tr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    );
                  }),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    final completed = _compressController.tasks.where(
                      (t) =>
                          t.status == CompressTaskStatus.completed ||
                          t.status == CompressTaskStatus.failed ||
                          t.status == CompressTaskStatus.canceled,
                    );
                    if (completed.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: TextButton.icon(
                        onPressed: _compressController.clearCompleted,
                        icon: Icon(
                          Icons.clear_all,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                        label: Text(
                          'clear_completed'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ),
                    );
                  }),
                  Text(
                    'compress_preset'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildPresetDropdown(),
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
                final tasks = _compressController.tasks;
                if (tasks.isEmpty) {
                  // 空状态：居中大红胶囊按钮【选择视频】
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

                // 任务列表
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

  Widget _buildPresetDropdown() {
    return Obx(() {
      final currentPreset = _compressController.config.value.preset;

      return DropdownButtonHideUnderline(
        child: DropdownButton2<CompressPreset>(
          value: currentPreset,
          items: [
            DropdownMenuItem(
              value: CompressPreset.balanced,
              child: Text(
                'preset_quick'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            DropdownMenuItem(
              value: CompressPreset.quality,
              child: Text(
                'preset_normal'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            DropdownMenuItem(
              value: CompressPreset.small,
              child: Text(
                'preset_extreme'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            DropdownMenuItem(
              value: CompressPreset.targetSize,
              child: Text(
                'preset_custom'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              if (val == CompressPreset.targetSize) {
                _showCustomSizeDialog();
              } else {
                _compressController.setPreset(val);
              }
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
    });
  }

  void _showCustomSizeDialog() {
    final currentTarget = _compressController.config.value.targetSizeMB;
    final controller = TextEditingController(
      text: currentTarget != null ? currentTarget.toStringAsFixed(0) : '25',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('target_size_prompt'.tr, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            suffixText: 'MB',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final size = double.tryParse(controller.text.trim());
              if (size != null && size > 0) {
                _compressController.setPreset(CompressPreset.targetSize);
                _compressController.setTargetSizeMB(size);
              }
              Navigator.of(ctx).pop();
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(CompressTask task, {Key? key}) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isCompressing = task.status == CompressTaskStatus.compressing;
    final isCompleted = task.status == CompressTaskStatus.completed;
    final isFailed = task.status == CompressTaskStatus.failed;

    String statusText;
    Color statusColor;

    if (isCompleted) {
      final savedPercent = (task.savedRatio != null && task.savedRatio! > 0)
          ? task.savedRatio!.toStringAsFixed(1)
          : '0';
      statusText = '${_formatFileSize(task.sourceSizeBytes)} → ${_formatFileSize(task.targetSizeBytes ?? 0)} (${'saved_size'.tr} $savedPercent%)';
      statusColor = Colors.green.shade600;
    } else if (isFailed) {
      statusText = '${'compress_failed'.tr}: ${task.errorMessage ?? ""}';
      statusColor = Colors.red.shade600;
    } else if (isCompressing) {
      final speedInfo = task.speed != null ? ' | ${task.speed}' : '';
      final etaInfo = task.eta != null ? ' | ETA: ${task.eta}' : '';
      statusText = '${'compressing'.tr}$speedInfo$etaInfo';
      statusColor = primaryColor;
    } else {
      statusText = '${'original_size'.tr}: ${_formatFileSize(task.sourceSizeBytes)}';
      statusColor = theme.colorScheme.onSurface.withOpacity(0.55);
    }

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
                    task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                      color: statusColor,
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

          // 右侧操作按钮组（开始/重新压缩 / 打开文件夹 / 删除）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 24,
                splashRadius: 22,
                tooltip: isCompressing
                    ? 'cancel'.tr
                    : (isFailed ? 'retry'.tr : (isCompleted ? 'completed'.tr : 'start_compress'.tr)),
                icon: isCompressing
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
                onPressed: isCompressing
                    ? () => _compressController.cancelTask(task.id)
                    : () => _compressController.retryTask(task.id),
              ),
              IconButton(
                iconSize: 24,
                splashRadius: 22,
                tooltip: '打开所在目录',
                icon: Icon(
                  Icons.folder_open,
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
                onPressed: () => _openFileDirectory(task.targetPath),
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
                  _compressController.removeTask(task.id);
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
