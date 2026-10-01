import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import '../../../../data/models/video_compress_model.dart';
import '../../../../services/video_compress_service.dart';
import '../../../../utils/logger.dart';
import '../../../../utils/utils.dart';

class CompressController extends GetxController {
  final VideoCompressService _compressService = Get.find<VideoCompressService>();

  /// 当前全局压缩配置
  final Rx<CompressConfig> config = const CompressConfig().obs;

  /// 压缩任务队列
  final RxList<CompressTask> tasks = <CompressTask>[].obs;

  /// 是否正在执行批量压缩
  final RxBool isProcessing = false.obs;

  /// 输出目录
  final RxString outputDir = ''.obs;

  /// 目标大小输入控制器
  final TextEditingController targetSizeController = TextEditingController(text: '25');

  @override
  void onInit() {
    super.onInit();
    _initOutputDir();
  }

  @override
  void onClose() {
    // 退出页面时，取消所有正在进行中的任务以防止孤儿进程
    for (final task in tasks) {
      if (task.status == CompressTaskStatus.compressing) {
        _compressService.cancelTask(task.id);
      }
    }
    targetSizeController.dispose();
    super.onClose();
  }

  Future<void> _initOutputDir() async {
    outputDir.value = await _compressService.getDefaultOutputDir();
  }

  /// 更改输出目录
  Future<void> chooseOutputDir() async {
    final selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir != null && selectedDir.isNotEmpty) {
      outputDir.value = selectedDir;
      config.value = config.value.copyWith(customOutputDir: selectedDir);
    }
  }

  /// 打开输出文件夹
  Future<void> openOutputFolder() async {
    if (outputDir.value.isNotEmpty) {
      final dir = Directory(outputDir.value);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await OpenFile.open(outputDir.value);
    }
  }

  /// 更新预设
  void setPreset(CompressPreset preset) {
    config.value = config.value.copyWith(
      preset: preset,
      crf: CompressConfig.defaultCrfFor(preset),
      resolution: CompressConfig.defaultResolutionFor(preset),
    );
  }

  /// 更新分辨率
  void setResolution(CompressResolution resolution) {
    config.value = config.value.copyWith(resolution: resolution);
  }

  /// 更新编码格式
  void setCodec(VideoCodecType codec) {
    config.value = config.value.copyWith(codec: codec);
  }

  /// 更新 CRF
  void setCrf(int crf) {
    config.value = config.value.copyWith(crf: crf);
  }

  /// 更新目标大小 (MB)
  void setTargetSizeMB(double mb) {
    config.value = config.value.copyWith(targetSizeMB: mb);
  }

  /// 切换硬件加速
  void setHardwareAcceleration(bool enable) {
    config.value = config.value.copyWith(enableHardwareAcceleration: enable);
  }

  /// 从文件管理器选择一个或多个视频
  Future<void> pickVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null && result.paths.isNotEmpty) {
        final validPaths = result.paths.whereType<String>().toList();
        await addVideoFiles(validPaths);
      }
    } catch (e) {
      Logger.e('Error picking videos: $e');
      Utils.showSnackbar('错误', '选择视频文件失败: $e');
    }
  }

  /// 添加视频文件至任务列表
  Future<void> addVideoFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      // 避免重复添加同一个正在处理的文件
      if (tasks.any((t) => t.sourcePath == path && t.status != CompressTaskStatus.completed)) {
        continue;
      }

      final file = File(path);
      if (!await file.exists()) continue;

      final fileName = p.basename(path);
      final ext = p.extension(path);
      final nameWithoutExt = p.basenameWithoutExtension(path);

      // 探测视频基础元数据
      final info = await _compressService.probeVideoInfo(path);
      final outDir = outputDir.value.isNotEmpty
          ? outputDir.value
          : await _compressService.getDefaultOutputDir();
      final targetPath = p.join(outDir, '${nameWithoutExt}_compressed$ext');

      final task = CompressTask(
        id: DateTime.now().microsecondsSinceEpoch.toString() + '_' + (tasks.length + 1).toString(),
        sourcePath: path,
        targetPath: targetPath,
        fileName: fileName,
        sourceSizeBytes: info['size'] as int,
        durationSeconds: (info['duration'] as num).toDouble(),
        width: info['width'] as int,
        height: info['height'] as int,
        config: config.value,
        createdAt: DateTime.now(),
      );

      tasks.add(task);
    }
  }

  /// 开始处理队列中所有待处理任务
  Future<void> startBatchCompress() async {
    if (isProcessing.value) return;

    final pendingTasks = tasks.where((t) => t.status == CompressTaskStatus.pending).toList();
    if (pendingTasks.isEmpty) {
      Utils.showSnackbar('提示', '当前没有待处理的压缩任务');
      return;
    }

    isProcessing.value = true;

    try {
      for (int i = 0; i < tasks.length; i++) {
        if (tasks[i].status != CompressTaskStatus.pending) continue;

        final currentTask = tasks[i];
        tasks[i] = currentTask.copyWith(
          status: CompressTaskStatus.compressing,
          config: config.value, // 使用最新配置
        );

        try {
          final targetBytes = await _compressService.compressVideo(
            task: tasks[i],
            onProgress: (progress, speed, eta) {
              final idx = tasks.indexWhere((t) => t.id == currentTask.id);
              if (idx != -1 && tasks[idx].status == CompressTaskStatus.compressing) {
                tasks[idx] = tasks[idx].copyWith(
                  progress: progress,
                  speed: speed,
                  eta: eta,
                );
              }
            },
          );

          final idx = tasks.indexWhere((t) => t.id == currentTask.id);
          if (idx != -1) {
            tasks[idx] = tasks[idx].copyWith(
              status: CompressTaskStatus.completed,
              progress: 1.0,
              targetSizeBytes: targetBytes,
              completedAt: DateTime.now(),
            );
          }
        } catch (e) {
          Logger.e('Compression error for ${currentTask.fileName}: $e');
          final idx = tasks.indexWhere((t) => t.id == currentTask.id);
          if (idx != -1) {
            tasks[idx] = tasks[idx].copyWith(
              status: CompressTaskStatus.failed,
              errorMessage: e.toString(),
            );
          }
        }
      }
    } finally {
      isProcessing.value = false;
    }
  }

  /// 取消单个任务
  void cancelTask(String taskId) {
    _compressService.cancelTask(taskId);
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      tasks[idx] = tasks[idx].copyWith(
        status: CompressTaskStatus.canceled,
        errorMessage: '已取消',
      );
    }
  }

  /// 重新开始单个任务
  Future<void> retryTask(String taskId) async {
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      tasks[idx] = tasks[idx].copyWith(
        status: CompressTaskStatus.pending,
        progress: 0.0,
        errorMessage: null,
      );
      await startBatchCompress();
    }
  }

  /// 添加并立即开始压缩
  Future<void> addAndStart(List<String> filePaths) async {
    await addVideoFiles(filePaths);
    await startBatchCompress();
  }

  /// 移除单个任务
  void removeTask(String taskId) {
    cancelTask(taskId);
    tasks.removeWhere((t) => t.id == taskId);
  }

  /// 清空已完成或失败任务
  void clearCompleted() {
    tasks.removeWhere((t) =>
        t.status == CompressTaskStatus.completed ||
        t.status == CompressTaskStatus.failed ||
        t.status == CompressTaskStatus.canceled);
  }

  /// 打开生成后的文件位置
  Future<void> openFile(String targetPath) async {
    if (await File(targetPath).exists()) {
      await OpenFile.open(targetPath);
    } else {
      Utils.showSnackbar('提示', '文件不存在');
    }
  }

  /// 统计累计节省的体积 (MB)
  double get totalSavedMB {
    final bytes = tasks.fold<int>(0, (sum, t) => sum + t.savedBytes);
    return bytes / (1024 * 1024);
  }

  int get completedCount => tasks.where((t) => t.status == CompressTaskStatus.completed).length;
}
