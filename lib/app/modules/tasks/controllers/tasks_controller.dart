import 'package:get/get.dart';
import '../../../data/models/download_task_model.dart';
import '../../../data/repositories/download_repository.dart';
import '../../../services/download_service.dart';
import '../../../utils/utils.dart';
import '../../../utils/logger.dart';

class TasksController extends GetxController {
  final DownloadRepository _downloadRepository = Get.find<DownloadRepository>();
  final DownloadService _downloadService = Get.find<DownloadService>();

  // 直接从DownloadService获取响应式任务列表，并提供一个排序后的视图
  List<DownloadTaskModel> get downloadTasks {
    final tasks = _downloadService.tasks;
    tasks.sort((a, b) {
      final statusOrder = {
        DownloadStatus.downloading: 0,
        DownloadStatus.pending: 1,
        DownloadStatus.paused: 2,
        DownloadStatus.completed: 3,
        DownloadStatus.canceled: 4,
        DownloadStatus.failed: 5,
      };
      final statusCompare = statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
      if (statusCompare != 0) return statusCompare;
      return b.createdAt.compareTo(a.createdAt);
    });
    return tasks;
  }

  // 是否正在加载
  final RxBool isLoading = false.obs;

  // 是否正在编辑
  final RxBool isEditing = false.obs;

  // 选中的项目
  final RxList<String> selectedItems = <String>[].obs;
  
  // 暂停下载任务
  Future<void> pauseTask(String taskId) async {
    try {
      final result = await _downloadRepository.pauseDownloadTask(taskId);
      if (result) {
        Utils.showSnackbar('成功', '任务已暂停');
      } else {
        Utils.showSnackbar('错误', '暂停任务失败', isError: true);
      }
    } catch (e) {
      Logger.e('暂停任务时出错: $e');
      Utils.showSnackbar('错误', '暂停任务时出错: $e', isError: true);
    }
  }
  
  // 恢复下载任务
  Future<void> resumeTask(String taskId) async {
    try {
      final result = await _downloadRepository.resumeDownloadTask(taskId);
      if (result) {
        Utils.showSnackbar('成功', '任务已恢复');
      } else {
        Utils.showSnackbar('错误', '恢复任务失败', isError: true);
      }
    } catch (e) {
      Logger.e('恢复任务时出错: $e');
      Utils.showSnackbar('错误', '恢复任务时出错: $e', isError: true);
    }
  }
  
  // 取消下载任务
  Future<void> cancelTask(String taskId) async {
    try {
      final result = await _downloadRepository.cancelDownloadTask(taskId);
      if (result) {
        Utils.showSnackbar('成功', '任务已取消');
      } else {
        Utils.showSnackbar('错误', '取消任务失败', isError: true);
      }
    } catch (e) {
      Logger.e('取消任务时出错: $e');
      Utils.showSnackbar('错误', '取消任务时出错: $e', isError: true);
    }
  }
  
  // 删除下载任务
  Future<void> deleteTask(String taskId) async {
    try {
      final result = await _downloadRepository.deleteDownloadTask(taskId);
      if (result) {
        Utils.showSnackbar('成功', '任务已删除');
      } else {
        Utils.showSnackbar('错误', '删除任务失败', isError: true);
      }
    } catch (e) {
      Logger.e('删除任务时出错: $e');
      Utils.showSnackbar('错误', '删除任务时出错: $e', isError: true);
    }
  }
  
  // 切换编辑模式
  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      selectedItems.clear();
    }
  }
  
  // 切换选中状态
  void toggleSelectItem(DownloadTaskModel task) {
    if (selectedItems.contains(task.id)) {
      selectedItems.remove(task.id);
    } else {
      selectedItems.add(task.id);
    }
  }
  
  // 是否选中
  bool isSelected(DownloadTaskModel task) {
    return selectedItems.contains(task.id);
  }
  
  // 全选
  void selectAll() {
    if (selectedItems.length == downloadTasks.length) {
      // 如果已经全选，则取消全选
      selectedItems.clear();
    } else {
      // 否则全选
      selectedItems.clear();
      for (var task in downloadTasks) {
        selectedItems.add(task.id);
      }
    }
  }
  
  // 删除选中项
  Future<void> deleteSelected() async {
    if (selectedItems.isEmpty) return;
    
    try {
      for (var taskId in selectedItems) {
        await _downloadRepository.deleteDownloadTask(taskId);
      }
      
      // 清空选中项
      selectedItems.clear();
      
      Utils.showSnackbar('成功', '已删除选中的任务');
    } catch (e) {
      Logger.e('删除任务时出错: $e');
      Utils.showSnackbar('错误', '删除任务时出错: $e', isError: true);
    }
  }
  
  // 获取正在下载的任务数量
  int get downloadingTasksCount {
    return downloadTasks.where((task) => 
      task.status == DownloadStatus.downloading || 
      task.status == DownloadStatus.pending
    ).length;
  }
  
  // 获取已完成的任务数量
  int get completedTasksCount {
    return downloadTasks.where((task) => 
      task.status == DownloadStatus.completed
    ).length;
  }
  
  // 获取失败的任务数量
  int get failedTasksCount {
    return downloadTasks.where((task) => 
      task.status == DownloadStatus.failed || 
      task.status == DownloadStatus.canceled
    ).length;
  }
}
