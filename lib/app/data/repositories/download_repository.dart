import 'package:get/get.dart';
import 'package:background_downloader/background_downloader.dart';
import '../models/download_task_model.dart';
import '../models/video_model.dart';
import '../providers/storage_provider.dart';
import '../../services/download_service.dart';
import '../../utils/logger.dart';
import '../../utils/utils.dart';

class DownloadRepository {
  final DownloadService _downloadService = Get.find<DownloadService>();
  final StorageProvider _storageProvider = Get.find<StorageProvider>();
  final FileDownloader _downloader = FileDownloader();

  // 获取下载任务列表
  List<DownloadTaskModel> getDownloadTasks() {
    return _storageProvider.getDownloadTasks();
  }

  // 添加下载任务
  Future<DownloadTaskModel?> addDownloadTask(
    VideoModel video, {
    required String quality,
    required String format,
    String? savePath,
  }) async {
    return await _downloadService.enqueueNewTask(
      video,
      quality: quality,
      format: format,
      savePath: savePath,
    );
  }

  // 暂停下载任务
  Future<bool> pauseDownloadTask(String taskId) async {
    try {
      return await _downloadService.pauseTask(taskId);
    } catch (e) {
      Utils.showSnackbar('暂停失败', '暂停下载任务时出错: $e', isError: true);
      return false;
    }
  }

  // 恢复下载任务
  Future<bool> resumeDownloadTask(String taskId) async {
    try {
      return await _downloadService.resumeTask(taskId);
    } catch (e) {
      Utils.showSnackbar('恢复失败', '恢复下载任务时出错: $e', isError: true);
      return false;
    }
  }

  // 取消下载任务
  Future<bool> cancelDownloadTask(String taskId) async {
    try {
      return await _downloadService.cancelTask(taskId);
    } catch (e) {
      Utils.showSnackbar('取消失败', '取消下载任务时出错: $e', isError: true);
      return false;
    }
  }

  // 删除下载任务
  Future<bool> deleteDownloadTask(String taskId) async {
    try {
      return await _downloadService.deleteTask(taskId);
    } catch (e) {
      Utils.showSnackbar('删除失败', '删除下载任务时出错: $e', isError: true);
      return false;
    }
  }
}
