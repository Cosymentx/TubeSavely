import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/models/video_compress_model.dart';
import '../utils/logger.dart';
import '../widgets/ffmpeg_install_dialog.dart';
import 'video_processing/ffmpeg_command_builder.dart';
import 'video_processing/ffmpeg_installer_service.dart';

/// 视频压缩核心服务
class VideoCompressService extends GetxService {
  String? _ffmpegPath;
  String? _ffprobePath;
  bool _isInitialized = false;

  /// 正在运行的进程字典 (taskId -> Process)
  final Map<String, Process> _runningProcesses = {};

  bool get isAvailable => _ffmpegPath != null;

  @override
  void onInit() {
    super.onInit();
    initEnvironment();
  }

  /// 初始化并检测系统中的 FFmpeg / FFprobe
  Future<bool> initEnvironment() async {
    try {
      final installer = FFmpegInstallerService();
      _ffmpegPath = await installer.getFFmpegPath();
      _ffprobePath = await installer.getFFprobePath();
      _isInitialized = true;
      Logger.d('VideoCompressService initialized: ffmpeg=$_ffmpegPath, ffprobe=$_ffprobePath');
      return _ffmpegPath != null;
    } catch (e) {
      Logger.e('Failed to detect FFmpeg/FFprobe: $e');
      _isInitialized = true;
      return false;
    }
  }

  /// 弹出友好的安装指引对话框（跨平台适用）
  Future<bool> promptInstallFFmpeg() async {
    final installer = FFmpegInstallerService();
    if (await installer.isFFmpegInstalled()) {
      await initEnvironment();
      return true;
    }

    final result = await Get.dialog<bool>(
      const FFmpegInstallDialog(),
      barrierDismissible: false,
    );

    if (result == true) {
      _isInitialized = false;
      await initEnvironment();
      return _ffmpegPath != null;
    }
    return false;
  }

  /// 获取默认压缩输出目录
  Future<String> getDefaultOutputDir() async {
    try {
      Directory? dir;
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      final outputDir = Directory(p.join(dir.path, 'TubeSavely_Compressed'));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      return outputDir.path;
    } catch (e) {
      Logger.e('Error getting default output dir: $e');
      return Directory.current.path;
    }
  }

  /// 解析输入视频信息 (宽高、时长、体积)
  Future<Map<String, dynamic>> probeVideoInfo(String filePath) async {
    final file = File(filePath);
    final size = await file.length();
    int width = 1920;
    int height = 1080;
    double duration = 0.0;

    if (_ffprobePath == null) {
      await initEnvironment();
    }

    if (_ffprobePath != null) {
      try {
        final result = await Process.run(_ffprobePath!, [
          '-v',
          'quiet',
          '-print_format',
          'json',
          '-show_format',
          '-show_streams',
          filePath,
        ]);

        if (result.exitCode == 0) {
          final data = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
          if (data.containsKey('format')) {
            final format = data['format'] as Map<String, dynamic>;
            duration = double.tryParse(format['duration']?.toString() ?? '0') ?? 0.0;
          }
          if (data.containsKey('streams')) {
            final streams = data['streams'] as List<dynamic>;
            for (final s in streams) {
              if (s['codec_type'] == 'video') {
                width = int.tryParse(s['width']?.toString() ?? '1920') ?? 1920;
                height = int.tryParse(s['height']?.toString() ?? '1080') ?? 1080;
                break;
              }
            }
          }
        }
      } catch (e) {
        Logger.w('Failed to probe video via ffprobe: $e');
      }
    }

    return {
      'size': size,
      'width': width,
      'height': height,
      'duration': duration,
    };
  }

  /// 执行压缩任务
  Future<int?> compressVideo({
    required CompressTask task,
    required void Function(double progress, String? speed, String? eta) onProgress,
  }) async {
    if (_ffmpegPath == null) {
      final ready = await initEnvironment();
      if (!ready || _ffmpegPath == null) {
        final installed = await promptInstallFFmpeg();
        if (!installed || _ffmpegPath == null) {
          throw Exception('系统未检测到 FFmpeg 工具，需要安装后才能进行视频压缩。');
        }
      }
    }

    final sourceFile = File(task.sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('源视频文件不存在: ${task.sourcePath}');
    }

    // 确保输出目录存在
    final targetFile = File(task.targetPath);
    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }

    // 构建命令行参数
    final args = FFmpegCommandBuilder.build(
      sourcePath: task.sourcePath,
      outputPath: task.targetPath,
      config: task.config,
      durationSeconds: task.durationSeconds,
      originalWidth: task.width,
      originalHeight: task.height,
    );

    Logger.d('Starting compression: $_ffmpegPath ${args.join(" ")}');

    final process = await Process.start(_ffmpegPath!, args);
    _runningProcesses[task.id] = process;

    final progressTimeRegex = RegExp(r'time=(\d+):(\d+):(\d+\.?\d*)');
    final speedRegex = RegExp(r'speed=\s*([\d\.]+)x');

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      // 提取已处理的时间
      final timeMatch = progressTimeRegex.firstMatch(line);
      if (timeMatch != null && task.durationSeconds > 0) {
        final hours = double.tryParse(timeMatch.group(1) ?? '0') ?? 0;
        final minutes = double.tryParse(timeMatch.group(2) ?? '0') ?? 0;
        final seconds = double.tryParse(timeMatch.group(3) ?? '0') ?? 0;
        final currentSeconds = hours * 3600 + minutes * 60 + seconds;

        final progress = (currentSeconds / task.durationSeconds).clamp(0.0, 0.99);

        // 提取速度
        String? speedStr;
        final speedMatch = speedRegex.firstMatch(line);
        double speedVal = 1.0;
        if (speedMatch != null) {
          speedStr = '${speedMatch.group(1)}x';
          speedVal = double.tryParse(speedMatch.group(1) ?? '1') ?? 1.0;
        }

        // 计算剩余时间
        String? etaStr;
        if (speedVal > 0) {
          final remainingSeconds = (task.durationSeconds - currentSeconds) / speedVal;
          if (remainingSeconds > 0) {
            final remMin = (remainingSeconds / 60).floor();
            final remSec = (remainingSeconds % 60).round();
            etaStr = remMin > 0 ? '$remMin分$remSec秒' : '$remSec秒';
          }
        }

        onProgress(progress, speedStr, etaStr);
      }
    });

    final exitCode = await process.exitCode;
    _runningProcesses.remove(task.id);

    if (exitCode != 0) {
      throw Exception('FFmpeg 压缩异常终止 (退出码: $exitCode)');
    }

    if (await targetFile.exists()) {
      return await targetFile.length();
    }
    return null;
  }

  /// 取消压缩任务
  void cancelTask(String taskId) {
    final process = _runningProcesses.remove(taskId);
    if (process != null) {
      process.kill();
      Logger.d('Process for task $taskId killed');
    }
  }
}
