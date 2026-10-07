import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../../../data/models/download_task_model.dart';
import '../../../data/repositories/download_repository.dart';
import '../../../services/download_service.dart';
import '../../../utils/logger.dart';
import '../../../utils/utils.dart';
import '../../home/controllers/home_controller.dart';
import '../../video/compress/controllers/compress_controller.dart';
import '../../video/convert/controllers/convert_controller.dart';

/// 桌面工作台分类栏目标识
enum WorkspaceSection {
  all, // 全部传输
  downloading, // 正在下载
  completed, // 已完成传输 / 历史
  convert, // 视频转换
  compress, // 智能压缩
  trending, // 热门发现
  profile, // 个人与设置
}

/// 现代一体化工作台主控制器 (Downie + Motrix 风格)
class WorkspaceController extends GetxController {
  final DownloadService _downloadService = Get.find<DownloadService>();
  final DownloadRepository _downloadRepository = Get.find<DownloadRepository>();

  // 当前选中的工作台分区
  final Rx<WorkspaceSection> currentSection = WorkspaceSection.all.obs;

  // 当前在右侧检视器聚焦的任务 (Active Task)
  final Rx<DownloadTaskModel?> activeTask = Rx<DownloadTaskModel?>(null);

  // 检视器展开/收起状态
  final RxBool isInspectorOpen = true.obs;

  // 视图模式：卡片视图 (false) vs 紧凑表格视图 (true)
  final RxBool isCompactTableView = false.obs;

  // 任务关键字过滤搜索
  final RxString searchKeyword = ''.obs;

  // 全局常驻快速解析输入框控制器
  final TextEditingController globalUrlController = TextEditingController();

  // 全局常驻解析加载状态
  final RxBool isGlobalParsing = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 监听任务列表变动，若无聚焦任务则自动选中第一个
    ever(_downloadService.tasks, (List<DownloadTaskModel> tasks) {
      if (tasks.isNotEmpty) {
        if (activeTask.value == null) {
          activeTask.value = tasks.first;
        } else {
          // 实时更新当前聚焦任务的状态数据
          final updated = tasks.firstWhereOrNull((t) => t.id == activeTask.value!.id);
          if (updated != null) {
            activeTask.value = updated;
          }
        }
      } else {
        activeTask.value = null;
      }
    });

    // 默认如果已有任务，选中第一个
    if (_downloadService.tasks.isNotEmpty) {
      activeTask.value = _downloadService.tasks.first;
    }
  }

  @override
  void onClose() {
    globalUrlController.dispose();
    super.onClose();
  }

  // ==================== 任务过滤与统计计算 ====================

  /// 获取当前分区过滤后的任务列表
  List<DownloadTaskModel> get filteredTasks {
    var list = List<DownloadTaskModel>.from(_downloadService.tasks);

    // 分区过滤
    switch (currentSection.value) {
      case WorkspaceSection.downloading:
        list = list.where((t) =>
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.pending ||
            t.status == DownloadStatus.paused).toList();
        break;
      case WorkspaceSection.completed:
        list = list.where((t) => t.status == DownloadStatus.completed).toList();
        break;
      default:
        break;
    }

    // 关键字搜索过滤
    final kw = searchKeyword.value.trim().toLowerCase();
    if (kw.isNotEmpty) {
      list = list.where((t) =>
          t.title.toLowerCase().contains(kw) ||
          (t.platform?.toLowerCase().contains(kw) ?? false) ||
          (t.format?.toLowerCase().contains(kw) ?? false)).toList();
    }

    // 排序：下载中排在最前，其次按创建时间降序
    list.sort((a, b) {
      final aActive = a.status == DownloadStatus.downloading ? 0 : 1;
      final bActive = b.status == DownloadStatus.downloading ? 0 : 1;
      final activeCompare = aActive.compareTo(bActive);
      if (activeCompare != 0) return activeCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return list;
  }

  int get totalCount => _downloadService.tasks.length;

  int get downloadingCount => _downloadService.tasks.where((t) =>
      t.status == DownloadStatus.downloading ||
      t.status == DownloadStatus.pending).length;

  int get completedCount => _downloadService.tasks.where((t) =>
      t.status == DownloadStatus.completed).length;

  /// 全局瞬时总下载速度估算 (MB/s)
  double get globalSpeedMBs {
    final activeCount = downloadingCount;
    if (activeCount == 0) return 0.0;
    // 聚合当前下载中的并发估算
    return activeCount * 4.8;
  }

  // ==================== 交互与视图动作 ====================

  void setSection(WorkspaceSection section) {
    currentSection.value = section;
  }

  void selectTask(DownloadTaskModel task) {
    activeTask.value = task;
  }

  void toggleInspector() {
    isInspectorOpen.value = !isInspectorOpen.value;
  }

  void toggleTableView() {
    isCompactTableView.value = !isCompactTableView.value;
  }

  // ==================== 顶部常驻全局快速解析 ====================

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      globalUrlController.text = data.text!.trim();
      await triggerGlobalParse();
    } else {
      Utils.showSnackbar('提示', '剪贴板中未发现有效内容');
    }
  }

  Future<void> triggerGlobalParse() async {
    final url = globalUrlController.text.trim();
    if (url.isEmpty) {
      Utils.showSnackbar('提示', '请输入或粘贴视频分享链接');
      return;
    }

    try {
      isGlobalParsing.value = true;

      // 同步给 HomeController 进行深度解析并拉起规格弹窗/界面
      final homeController = Get.find<HomeController>();
      homeController.urlController.text = url;
      await homeController.parseVideo();

      globalUrlController.clear();
      // 如果解析成功产生视频，自动切回下载/首页查看
      if (homeController.currentVideo.value != null) {
        currentSection.value = WorkspaceSection.all;
      }
    } catch (e) {
      Logger.e('全局解析失败: $e');
    } finally {
      isGlobalParsing.value = false;
    }
  }

  // ==================== 任务控制操作 ====================

  Future<void> togglePauseResume(DownloadTaskModel task) async {
    if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.pending) {
      await _downloadRepository.pauseDownloadTask(task.id);
    } else if (task.status == DownloadStatus.paused) {
      await _downloadRepository.resumeDownloadTask(task.id);
    }
  }

  Future<void> pauseAll() async {
    for (var task in _downloadService.tasks) {
      if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.pending) {
        await _downloadRepository.pauseDownloadTask(task.id);
      }
    }
    Utils.showSnackbar('提示', '已暂停所有下载任务');
  }

  Future<void> resumeAll() async {
    for (var task in _downloadService.tasks) {
      if (task.status == DownloadStatus.paused) {
        await _downloadRepository.resumeDownloadTask(task.id);
      }
    }
    Utils.showSnackbar('提示', '已恢复所有下载任务');
  }

  Future<void> clearCompleted() async {
    final toRemove = _downloadService.tasks
        .where((t) => t.status == DownloadStatus.completed)
        .map((t) => t.id)
        .toList();
    for (var id in toRemove) {
      await _downloadRepository.deleteDownloadTask(id);
    }
    Utils.showSnackbar('成功', '已清空已完成记录');
  }

  Future<void> deleteTask(String taskId) async {
    await _downloadRepository.deleteDownloadTask(taskId);
    if (activeTask.value?.id == taskId) {
      activeTask.value = filteredTasks.isNotEmpty ? filteredTasks.first : null;
    }
  }

  // ==================== 检视器连带协同动作 ====================

  /// 打开已下载本地文件
  Future<void> openTaskFile(DownloadTaskModel task) async {
    if (task.savePath == null || task.savePath!.isEmpty) {
      Utils.showSnackbar('提示', '该任务尚未生成本地文件');
      return;
    }
    final file = File(task.savePath!);
    if (await file.exists()) {
      await OpenFile.open(task.savePath!);
    } else {
      Utils.showSnackbar('错误', '本地文件不存在或已被移动');
    }
  }

  /// 在系统文件管理器中定位该文件
  Future<void> openTaskFolder(DownloadTaskModel task) async {
    if (task.savePath == null || task.savePath!.isEmpty) {
      Utils.showSnackbar('提示', '未找到本地路径');
      return;
    }

    final folder = p.dirname(task.savePath!);
    if (Platform.isWindows) {
      Process.run('explorer.exe', ['/select,', task.savePath!]);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', task.savePath!]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [folder]);
    }
  }

  /// 快捷协同：发送该视频至【视频格式转换】
  Future<void> sendToConvert(DownloadTaskModel task) async {
    if (task.savePath == null || !(await File(task.savePath!).exists())) {
      Utils.showSnackbar('提示', '本地视频文件不存在，无法进行转换');
      return;
    }

    try {
      ConvertController convertController;
      if (Get.isRegistered<ConvertController>()) {
        convertController = Get.find<ConvertController>();
      } else {
        convertController = Get.put(ConvertController());
      }

      final file = File(task.savePath!);
      if (!convertController.selectedFiles.any((f) => f.path == file.path)) {
        convertController.selectedFiles.add(file);
      }

      currentSection.value = WorkspaceSection.convert;
      Utils.showSnackbar('已导入', '视频已载入格式转换工作台');
    } catch (e) {
      Logger.e('导入转换失败: $e');
    }
  }

  /// 快捷协同：发送该视频至【智能视频压缩】
  Future<void> sendToCompress(DownloadTaskModel task) async {
    if (task.savePath == null || !(await File(task.savePath!).exists())) {
      Utils.showSnackbar('提示', '本地视频文件不存在，无法进行压缩');
      return;
    }

    try {
      CompressController compressController;
      if (Get.isRegistered<CompressController>()) {
        compressController = Get.find<CompressController>();
      } else {
        compressController = Get.put(CompressController());
      }

      await compressController.addVideoFiles([task.savePath!]);
      currentSection.value = WorkspaceSection.compress;
      Utils.showSnackbar('已导入', '视频已载入智能压缩工作台');
    } catch (e) {
      Logger.e('导入压缩失败: $e');
    }
  }
}
