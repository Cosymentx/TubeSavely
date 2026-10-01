import 'package:get/get.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../utils/logger.dart';

/// 任务控制器
class TaskController extends GetxController {
  final TaskRepository _taskRepository = Get.find<TaskRepository>();
  
  // 任务列表
  final RxList<TaskModel> tasks = <TaskModel>[].obs;
  
  // 加载状态
  final RxBool isLoading = false.obs;
  
  // 是否有更多数据
  final RxBool hasMore = true.obs;
  
  // 当前页码
  final RxInt currentPage = 0.obs;
  
  // 每页数量
  final int pageSize = 10;
  
  // 选中的任务类型
  final Rx<TaskType?> selectedTaskType = Rx<TaskType?>(null);
  
  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }
  
  /// 加载任务列表
  Future<void> loadTasks({bool refresh = false}) async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      
      if (refresh) {
        currentPage.value = 0;
        tasks.clear();
      }
      
      final newTasks = await _taskRepository.getTaskList(
        skip: currentPage.value * pageSize,
        limit: pageSize,
        taskType: selectedTaskType.value,
      );
      
      if (newTasks.isEmpty) {
        hasMore.value = false;
      } else {
        tasks.addAll(newTasks);
        currentPage.value++;
        hasMore.value = newTasks.length >= pageSize;
      }
    } catch (e) {
      Logger.e('Error loading tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 刷新任务列表
  Future<void> refreshTasks() async {
    await loadTasks(refresh: true);
  }
  
  /// 加载更多任务
  Future<void> loadMoreTasks() async {
    if (isLoading.value || !hasMore.value) return;
    await loadTasks();
  }
  
  /// 筛选任务类型
  Future<void> filterByTaskType(TaskType? taskType) async {
    if (selectedTaskType.value == taskType) return;
    
    selectedTaskType.value = taskType;
    await refreshTasks();
  }
  
  /// 获取任务详情
  Future<TaskModel?> getTaskDetail(int taskId) async {
    try {
      isLoading.value = true;
      return await _taskRepository.getTaskDetail(taskId);
    } catch (e) {
      Logger.e('Error getting task detail: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 创建转换任务
  Future<TaskModel?> createConvertTask(
    String title,
    int creditsCost, {
    String? description,
    String? inputUrl,
    Map<String, dynamic>? inputParams,
    String? outputFormat,
  }) async {
    try {
      isLoading.value = true;
      
      final task = await _taskRepository.createConvertTask(
        title,
        creditsCost,
        description: description,
        inputUrl: inputUrl,
        inputParams: inputParams,
        outputFormat: outputFormat,
      );
      
      if (task != null) {
        await refreshTasks();
      }
      
      return task;
    } catch (e) {
      Logger.e('Error creating convert task: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 创建生成任务
  Future<TaskModel?> createGenerateTask(
    String title,
    int creditsCost, {
    String? description,
    String? inputUrl,
    Map<String, dynamic>? inputParams,
    String? outputFormat,
  }) async {
    try {
      isLoading.value = true;
      
      final task = await _taskRepository.createGenerateTask(
        title,
        creditsCost,
        description: description,
        inputUrl: inputUrl,
        inputParams: inputParams,
        outputFormat: outputFormat,
      );
      
      if (task != null) {
        await refreshTasks();
      }
      
      return task;
    } catch (e) {
      Logger.e('Error creating generate task: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 取消任务
  Future<bool> cancelTask(int taskId) async {
    try {
      isLoading.value = true;
      
      final success = await _taskRepository.cancelTask(taskId);
      
      if (success) {
        // 更新本地任务状态
        final index = tasks.indexWhere((task) => task.id == taskId);
        if (index != -1) {
          final task = tasks[index];
          tasks[index] = task.copyWith(status: TaskStatus.canceled);
        }
      }
      
      return success;
    } catch (e) {
      Logger.e('Error canceling task: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
