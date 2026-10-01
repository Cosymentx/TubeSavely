import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../data/providers/storage_provider.dart';
import '../utils/logger.dart';
import '../utils/utils.dart';
import 'video_processing/video_processing_service.dart';
import 'video_processing/video_processing_factory.dart';

/// 视频转换任务状态
enum ConversionStatus {
  pending, // 等待中
  converting, // 转换中
  completed, // 已完成
  failed, // 失败
  canceled // 已取消
}

/// 视频转换任务模型
class ConversionTask {
  final String id;
  final String sourceFilePath;
  final String targetFilePath;
  final String format;
  final String resolution;
  final int bitrate;
  final ConversionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final double progress;
  final String? errorMessage;
  final String? statusMessage;
  final int? speed; // 转换速度，单位kbps

  ConversionTask({
    required this.id,
    required this.sourceFilePath,
    required this.targetFilePath,
    required this.format,
    required this.resolution,
    required this.bitrate,
    this.status = ConversionStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.progress = 0.0,
    this.errorMessage,
    this.statusMessage,
    this.speed,
  });

  ConversionTask copyWith({
    String? id,
    String? sourceFilePath,
    String? targetFilePath,
    String? format,
    String? resolution,
    int? bitrate,
    ConversionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    double? progress,
    String? errorMessage,
    String? statusMessage,
    int? speed,
  }) {
    return ConversionTask(
      id: id ?? this.id,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      targetFilePath: targetFilePath ?? this.targetFilePath,
      format: format ?? this.format,
      resolution: resolution ?? this.resolution,
      bitrate: bitrate ?? this.bitrate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      statusMessage: statusMessage ?? this.statusMessage,
      speed: speed ?? this.speed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceFilePath': sourceFilePath,
      'targetFilePath': targetFilePath,
      'format': format,
      'resolution': resolution,
      'bitrate': bitrate,
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'progress': progress,
      'errorMessage': errorMessage,
      'statusMessage': statusMessage,
      'speed': speed,
    };
  }

  factory ConversionTask.fromJson(Map<String, dynamic> json) {
    return ConversionTask(
      id: json['id'],
      sourceFilePath: json['sourceFilePath'],
      targetFilePath: json['targetFilePath'],
      format: json['format'],
      resolution: json['resolution'],
      bitrate: json['bitrate'],
      status: ConversionStatus.values[json['status']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
      progress: json['progress'],
      errorMessage: json['errorMessage'],
      statusMessage: json['statusMessage'],
      speed: json['speed'],
    );
  }
}

/// 视频转换服务
///
/// 负责管理视频转换任务，包括创建、取消和删除任务
class VideoConverterService extends GetxService {
  final StorageProvider _storageProvider = Get.find<StorageProvider>();

  // 当前转换任务列表
  final RxList<ConversionTask> conversionTasks = <ConversionTask>[].obs;

  // 当前正在执行的任务
  final Rx<ConversionTask?> currentTask = Rx<ConversionTask?>(null);

  // 是否正在转换
  final RxBool isConverting = false.obs;

  // 视频处理服务
  late final VideoProcessingService _videoProcessingService;

  // 当前转换任务ID
  String? _currentTaskId;

  /// 初始化服务
  Future<VideoConverterService> init() async {
    Logger.d('VideoConverterService initialized');

    // 初始化视频处理服务
    _videoProcessingService = VideoProcessingFactory.getService();

    // 检查服务是否可用
    final isAvailable = await _videoProcessingService.isAvailable();
    Logger.d('Video processing service available: $isAvailable');

    if (!isAvailable) {
      Logger.w('Video processing service is not available on this platform');
      Utils.showSnackbar('提示', '视频处理服务在当前平台不可用，部分功能可能受限');
    }

    // 加载已有的转换任务
    _loadTasks();

    return this;
  }

  /// 创建视频转换任务
  ///
  /// [sourceFilePath] 源文件路径
  /// [format] 目标格式
  /// [resolution] 分辨率
  /// [bitrate] 比特率
  /// 返回创建的转换任务
  Future<ConversionTask?> createTask({
    required String sourceFilePath,
    required String format,
    String resolution = '720p',
    int bitrate = 1500,
  }) async {
    try {
      // 检查源文件是否存在
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourceFilePath');
      }

      // 创建唯一ID
      final String taskId = DateTime.now().millisecondsSinceEpoch.toString();

      // 创建目标文件路径
      final targetFilePath = await _getTargetFilePath(sourceFilePath, format);

      // 创建转换任务
      final ConversionTask task = ConversionTask(
        id: taskId,
        sourceFilePath: sourceFilePath,
        targetFilePath: targetFilePath,
        format: format,
        resolution: resolution,
        bitrate: bitrate,
        status: ConversionStatus.pending,
        createdAt: DateTime.now(),
      );

      // 保存任务
      await _addTask(task);

      // 如果当前没有正在执行的任务，则开始执行
      if (!isConverting.value) {
        _processNextTask();
      }

      return task;
    } catch (e) {
      Logger.e('Error creating conversion task: $e');
      Utils.showSnackbar('转换失败', '创建转换任务时出错: $e', isError: true);
      return null;
    }
  }

  /// 取消转换任务
  ///
  /// [taskId] 任务ID
  /// 返回是否成功
  Future<bool> cancelTask(String taskId) async {
    try {
      final taskIndex = conversionTasks.indexWhere((task) => task.id == taskId);

      if (taskIndex != -1) {
        final task = conversionTasks[taskIndex];

        // 只有等待中或转换中的任务才能取消
        if (task.status != ConversionStatus.pending &&
            task.status != ConversionStatus.converting) {
          return false;
        }

        // 如果是正在转换的任务，取消转换
        if (task.status == ConversionStatus.converting &&
            _currentTaskId == taskId) {
          // 当前没有提供直接取消的方法，但我们可以标记任务为取消状态
          _currentTaskId = null;

          // 重置状态
          isConverting.value = false;
          currentTask.value = null;

          // 处理下一个任务
          _processNextTask();
        }

        // 更新任务状态
        final updatedTask = task.copyWith(
          status: ConversionStatus.canceled,
          updatedAt: DateTime.now(),
        );

        await _updateTask(updatedTask);

        return true;
      }

      return false;
    } catch (e) {
      Logger.e('Error canceling conversion task: $e');
      return false;
    }
  }

  /// 删除转换任务
  ///
  /// [taskId] 任务ID
  /// [deleteFile] 是否同时删除文件
  /// 返回是否成功
  Future<bool> deleteTask(String taskId, {bool deleteFile = false}) async {
    try {
      final taskIndex = conversionTasks.indexWhere((task) => task.id == taskId);

      if (taskIndex != -1) {
        final task = conversionTasks[taskIndex];

        // 如果是当前正在执行的任务，则先取消
        if (currentTask.value?.id == taskId) {
          await cancelTask(taskId);
        }

        // 如果需要删除文件
        if (deleteFile && task.targetFilePath.isNotEmpty) {
          final file = File(task.targetFilePath);
          if (await file.exists()) {
            await file.delete();
          }
        }

        // 从存储中删除任务
        await _removeTask(taskId);

        return true;
      }

      return false;
    } catch (e) {
      Logger.e('Error deleting conversion task: $e');
      return false;
    }
  }

  /// 获取转换任务列表
  List<ConversionTask> getTasks() {
    return conversionTasks;
  }

  /// 获取转换任务
  ///
  /// [taskId] 任务ID
  /// 返回转换任务，未找到返回null
  ConversionTask? getTask(String taskId) {
    final index = conversionTasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      return conversionTasks[index];
    }
    return null;
  }

  /// 加载任务列表
  void _loadTasks() {
    try {
      final tasks = _storageProvider.getConversionTasks();
      conversionTasks.assignAll(tasks);

      // 检查是否有未完成的任务
      final pendingTasks = tasks
          .where((task) =>
              task.status == ConversionStatus.pending ||
              task.status == ConversionStatus.converting)
          .toList();

      if (pendingTasks.isNotEmpty) {
        // 将所有未完成任务重置为等待状态
        for (final task in pendingTasks) {
          final updatedTask = task.copyWith(
            status: ConversionStatus.pending,
            updatedAt: DateTime.now(),
          );
          _updateTask(updatedTask);
        }

        // 开始处理下一个任务
        _processNextTask();
      }
    } catch (e) {
      Logger.e('Error loading conversion tasks: $e');
    }
  }

  /// 添加任务到列表和存储
  Future<void> _addTask(ConversionTask task) async {
    conversionTasks.add(task);
    await _storageProvider.addConversionTask(task);
  }

  /// 更新任务
  Future<void> _updateTask(ConversionTask task) async {
    final index = conversionTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      conversionTasks[index] = task;
      await _storageProvider.updateConversionTask(task);
    }
  }

  /// 从列表和存储中移除任务
  Future<void> _removeTask(String taskId) async {
    conversionTasks.removeWhere((task) => task.id == taskId);
    await _storageProvider.removeConversionTask(taskId);
  }

  /// 获取目标文件路径
  Future<String> _getTargetFilePath(
      String sourceFilePath, String format) async {
    final sourceFile = File(sourceFilePath);
    final sourceFileName = sourceFile.path.split('/').last;
    final sourceFileNameWithoutExt = sourceFileName.split('.').first;

    // 获取应用文档目录
    final appDir = await getApplicationDocumentsDirectory();
    final convertDir = Directory('${appDir.path}/converted');

    // 确保目录存在
    if (!await convertDir.exists()) {
      await convertDir.create(recursive: true);
    }

    return '${convertDir.path}/${sourceFileNameWithoutExt}_converted.$format';
  }

  /// 处理下一个任务
  Future<void> _processNextTask() async {
    try {
      // 检查是否有等待中的任务
      final pendingTasks = conversionTasks
          .where((task) => task.status == ConversionStatus.pending)
          .toList();

      if (pendingTasks.isEmpty) {
        isConverting.value = false;
        currentTask.value = null;
        return;
      }

      // 获取第一个等待中的任务
      final task = pendingTasks.first;

      // 更新任务状态
      final updatedTask = task.copyWith(
        status: ConversionStatus.converting,
        updatedAt: DateTime.now(),
      );

      await _updateTask(updatedTask);

      // 设置当前任务
      currentTask.value = updatedTask;
      isConverting.value = true;

      // 开始转换
      await _convertVideo(updatedTask);
    } catch (e) {
      Logger.e('Error processing next task: $e');
      isConverting.value = false;
      currentTask.value = null;
    }
  }

  /// 转换视频
  Future<void> _convertVideo(ConversionTask task) async {
    try {
      // 检查源文件是否存在
      final sourceFile = File(task.sourceFilePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: ${task.sourceFilePath}');
      }

      // 检查源文件大小
      final fileSize = await sourceFile.length();
      if (fileSize <= 0) {
        throw Exception('Source file is empty: ${task.sourceFilePath}');
      }

      // 检查源文件是否可读
      try {
        final randomAccessFile = await sourceFile.open(mode: FileMode.read);
        await randomAccessFile.close();
      } catch (e) {
        throw Exception(
            'Source file is not readable: ${task.sourceFilePath}, Error: $e');
      }

      // 获取视频信息
      final mediaInfo =
          await _videoProcessingService.getMediaInfo(task.sourceFilePath);
      final duration = mediaInfo != null && mediaInfo.containsKey('duration')
          ? double.tryParse(mediaInfo['duration'].toString()) ?? 0.0
          : 0.0;

      if (duration <= 0) {
        Logger.w('Invalid video duration: $duration, using default value');
      }

      // 创建目标文件目录
      final targetFile = File(task.targetFilePath);
      final targetDir = targetFile.parent;
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 检查目标路径是否可写
      try {
        final testFile = File('${targetDir.path}/test_write.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        throw Exception(
            'Target directory is not writable: ${targetDir.path}, Error: $e');
      }

      // 更新任务状态为转换中
      var updatedTask = task.copyWith(
        status: ConversionStatus.converting,
        progress: 0.0,
        updatedAt: DateTime.now(),
      );
      await _updateTask(updatedTask);

      // 通知用户转换开始
      Utils.showSnackbar('转换开始', '开始转换 ${sourceFile.path.split('/').last}');

      // 设置当前任务ID
      _currentTaskId = task.id;

      // 准备转换选项
      final Map<String, dynamic> options = _buildConversionOptions(task);

      // 执行视频转换
      final outputPath = await _videoProcessingService.convertVideo(
        task.sourceFilePath,
        task.targetFilePath,
        options: options,
        onProgress: (type, progress) async {
          // 进度回调
          if (duration > 0) {
            final clampedProgress = progress.clamp(0.0, 100.0) / 100.0;

            // 更新任务进度
            final progressTask = updatedTask.copyWith(
              progress: clampedProgress,
              statusMessage:
                  '正在转换: ${(clampedProgress * 100).toStringAsFixed(1)}%',
              updatedAt: DateTime.now(),
            );

            // 更新任务状态
            updatedTask = progressTask;
            await _updateTask(progressTask);

            // 打印转换进度
            Logger.d(
                'Conversion progress: ${(clampedProgress * 100).toStringAsFixed(1)}% for task ${task.id}');
          }
        },
        onFailure: (error) async {
          // 如果当前任务已被取消，则不更新状态
          if (_currentTaskId != task.id) {
            return;
          }

          // 转换失败
          final failedTask = updatedTask.copyWith(
            status: ConversionStatus.failed,
            errorMessage: 'Error: ${error.toString()}',
            updatedAt: DateTime.now(),
          );

          await _updateTask(failedTask);

          Logger.e('Video conversion error: ${error.toString()}');
          Utils.showSnackbar('转换失败', '视频转换出错: ${error.toString()}',
              isError: true);

          // 处理下一个任务
          isConverting.value = false;
          currentTask.value = null;
          _currentTaskId = null;
          _processNextTask();
        },
      );

      // 如果当前任务已被取消，则不更新状态
      if (_currentTaskId != task.id) {
        // 任务已被取消
        final canceledTask = updatedTask.copyWith(
          status: ConversionStatus.canceled,
          updatedAt: DateTime.now(),
        );

        await _updateTask(canceledTask);

        // 删除已生成的文件
        final outputFile = File(task.targetFilePath);
        if (await outputFile.exists()) {
          await outputFile.delete();
        }

        return;
      }

      if (outputPath != null) {
        // 检查输出文件是否存在且大小大于0
        final outputFile = File(outputPath);
        if (await outputFile.exists() && await outputFile.length() > 0) {
          // 更新任务状态为已完成
          final completedTask = updatedTask.copyWith(
            status: ConversionStatus.completed,
            progress: 1.0,
            completedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _updateTask(completedTask);

          // 通知用户转换完成
          Utils.showSnackbar(
              '转换完成', '视频已转换完成: ${outputFile.path.split('/').last}');
        } else {
          // 输出文件不存在或为空
          final failedTask = updatedTask.copyWith(
            status: ConversionStatus.failed,
            errorMessage: 'Output file does not exist or is empty: $outputPath',
            updatedAt: DateTime.now(),
          );

          await _updateTask(failedTask);

          Logger.e('Output file does not exist or is empty: $outputPath');
          Utils.showSnackbar('转换失败', '输出文件不存在或为空，请检查存储空间', isError: true);
        }
      } else {
        // 转换失败
        final failedTask = updatedTask.copyWith(
          status: ConversionStatus.failed,
          errorMessage: 'Conversion failed with null output path',
          updatedAt: DateTime.now(),
        );

        await _updateTask(failedTask);

        Logger.e('Conversion failed with null output path');
        Utils.showSnackbar('转换失败', '视频转换失败', isError: true);
      }

      // 处理下一个任务
      isConverting.value = false;
      currentTask.value = null;
      _currentTaskId = null;
      _processNextTask();
    } catch (e) {
      Logger.e('Error converting video: $e');

      // 提供更友好的错误信息
      String userFriendlyError = '视频转换失败';
      if (e.toString().contains('Source file does not exist')) {
        userFriendlyError = '源文件不存在';
      } else if (e.toString().contains('Source file is empty')) {
        userFriendlyError = '源文件为空';
      } else if (e.toString().contains('Source file is not readable')) {
        userFriendlyError = '无法读取源文件，请检查权限';
      } else if (e.toString().contains('Target directory is not writable')) {
        userFriendlyError = '无法写入目标目录，请检查权限';
      }

      // 更新任务状态为失败
      final failedTask = task.copyWith(
        status: ConversionStatus.failed,
        errorMessage: 'Error: $e',
        updatedAt: DateTime.now(),
      );

      await _updateTask(failedTask);

      // 通知用户转换失败
      Utils.showSnackbar('转换失败', userFriendlyError, isError: true);

      // 处理下一个任务
      isConverting.value = false;
      currentTask.value = null;
      _currentTaskId = null;
      _processNextTask();
    }
  }

  /// 构建转换选项
  Map<String, dynamic> _buildConversionOptions(ConversionTask task) {
    // 解析分辨率
    int width, height;
    switch (task.resolution) {
      case '480p':
        width = 854;
        height = 480;
        break;
      case '720p':
        width = 1280;
        height = 720;
        break;
      case '1080p':
        width = 1920;
        height = 1080;
        break;
      case '2K':
        width = 2560;
        height = 1440;
        break;
      case '4K':
        width = 3840;
        height = 2160;
        break;
      default:
        width = 1280;
        height = 720;
        break;
    }

    // 创建选项映射
    final Map<String, dynamic> options = {
      'width': width,
      'height': height,
      'videoBitrate': '${task.bitrate}k',
      'audioBitrate': '128k',
      'preset': 'medium',
    };

    // 根据格式设置不同的编码器
    switch (task.format.toLowerCase()) {
      case 'mp4':
        options['videoCodec'] = 'libx264';
        options['audioCodec'] = 'aac';
        options['profile'] = 'high';
        options['level'] = '4.0';
        options['movflags'] = '+faststart';
        options['metadata'] = {'title': 'Converted with TubeSavely'};
        break;
      case 'webm':
        options['videoCodec'] = 'libvpx-vp9';
        options['audioCodec'] = 'libopus';
        options['deadline'] = 'good';
        options['cpuUsed'] = 2;
        options['audioSampleRate'] = 48000;
        break;
      case 'gif':
        options['fps'] = 10;
        options['loop'] = 0;
        options['extractAudio'] = false;
        break;
      case 'mkv':
        options['videoCodec'] = 'libx265';
        options['audioCodec'] = 'aac';
        options['crf'] = 23;
        break;
      case 'avi':
        options['videoCodec'] = 'mpeg4';
        options['audioCodec'] = 'libmp3lame';
        options['quality'] = 5;
        break;
      case 'mov':
        options['videoCodec'] = 'libx264';
        options['audioCodec'] = 'aac';
        options['profile'] = 'high';
        break;
      case 'ogg':
        options['videoCodec'] = 'libtheora';
        options['audioCodec'] = 'libvorbis';
        options['videoQuality'] = 7;
        options['audioQuality'] = 5;
        break;
      case 'mp3':
        options['extractAudio'] = true;
        options['audioCodec'] = 'libmp3lame';
        options['audioQuality'] = 2;
        options['audioSampleRate'] = 44100;
        break;
      case 'wav':
        options['extractAudio'] = true;
        options['audioCodec'] = 'pcm_s16le';
        options['audioSampleRate'] = 44100;
        break;
      case 'aac':
        options['extractAudio'] = true;
        options['audioCodec'] = 'aac';
        options['audioBitrate'] = '192k';
        options['audioSampleRate'] = 44100;
        break;
      case 'flac':
        options['extractAudio'] = true;
        options['audioCodec'] = 'flac';
        options['audioSampleRate'] = 44100;
        break;
      default:
        options['videoCodec'] = 'libx264';
        options['audioCodec'] = 'aac';
        options['preset'] = 'medium';
        break;
    }

    return options;
  }

  /// 获取视频时长（秒）
  Future<double> _getVideoDuration(String filePath) async {
    try {
      // 使用视频处理服务获取媒体信息
      final mediaInfo = await _videoProcessingService.getMediaInfo(filePath);

      if (mediaInfo != null && mediaInfo.containsKey('duration')) {
        final durationStr = mediaInfo['duration'].toString();
        if (durationStr.isNotEmpty) {
          try {
            return double.parse(durationStr);
          } catch (e) {
            Logger.e('Error parsing duration string: $durationStr, $e');
          }
        }
      }

      // 如果无法获取时长，返回默认值
      Logger.w('Could not determine media duration, using default value');
      return 60.0;
    } catch (e) {
      Logger.e('Error getting video duration: $e');
      return 60.0;
    }
  }
}
