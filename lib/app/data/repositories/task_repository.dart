import 'package:get/get.dart';
import '../models/task_model.dart';
import '../providers/api_provider.dart';
import '../../utils/logger.dart';

/// 任务仓库
///
/// 负责处理任务相关的业务逻辑
class TaskRepository {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  /// 获取任务列表
  ///
  /// [skip] 跳过数量，默认为0
  /// [limit] 每页数量，默认为10
  /// [taskType] 任务类型，可选值：convert, generate
  Future<List<TaskModel>> getTaskList({
    int skip = 0,
    int limit = 10,
    TaskType? taskType,
  }) async {
    try {
      Logger.d('Getting task list');
      
      final response = await _apiProvider.getTaskList(
        skip: skip,
        limit: limit,
        taskType: taskType?.toString().split('.').last,
      );
      
      if (response.status.isOk) {
        final List<dynamic> data = response.body['data'] ?? [];
        return data.map((item) => TaskModel.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      Logger.e('Error getting task list: $e');
      return [];
    }
  }

  /// 获取任务详情
  ///
  /// [taskId] 任务ID
  Future<TaskModel?> getTaskDetail(int taskId) async {
    try {
      Logger.d('Getting task detail: $taskId');
      
      final response = await _apiProvider.getTaskDetail(taskId);
      
      if (response.status.isOk) {
        final Map<String, dynamic> data = response.body['data'] ?? {};
        return TaskModel.fromJson(data);
      }
      
      return null;
    } catch (e) {
      Logger.e('Error getting task detail: $e');
      return null;
    }
  }

  /// 创建转换任务
  ///
  /// [title] 任务标题
  /// [creditsCost] 积分消耗
  /// [description] 任务描述
  /// [inputUrl] 输入视频URL
  /// [inputParams] 输入参数
  /// [outputFormat] 输出格式
  Future<TaskModel?> createConvertTask(
    String title,
    int creditsCost, {
    String? description,
    String? inputUrl,
    Map<String, dynamic>? inputParams,
    String? outputFormat,
  }) async {
    try {
      Logger.d('Creating convert task: $title');
      
      final response = await _apiProvider.createConvertTask(
        title,
        creditsCost,
        description: description,
        inputUrl: inputUrl,
        inputParams: inputParams,
        outputFormat: outputFormat,
      );
      
      if (response.status.isOk) {
        final Map<String, dynamic> data = response.body['data'] ?? {};
        return TaskModel.fromJson(data);
      }
      
      return null;
    } catch (e) {
      Logger.e('Error creating convert task: $e');
      return null;
    }
  }

  /// 创建生成任务
  ///
  /// [title] 任务标题
  /// [creditsCost] 积分消耗
  /// [description] 任务描述
  /// [inputUrl] 输入视频URL
  /// [inputParams] 输入参数
  /// [outputFormat] 输出格式
  Future<TaskModel?> createGenerateTask(
    String title,
    int creditsCost, {
    String? description,
    String? inputUrl,
    Map<String, dynamic>? inputParams,
    String? outputFormat,
  }) async {
    try {
      Logger.d('Creating generate task: $title');
      
      final response = await _apiProvider.createGenerateTask(
        title,
        creditsCost,
        description: description,
        inputUrl: inputUrl,
        inputParams: inputParams,
        outputFormat: outputFormat,
      );
      
      if (response.status.isOk) {
        final Map<String, dynamic> data = response.body['data'] ?? {};
        return TaskModel.fromJson(data);
      }
      
      return null;
    } catch (e) {
      Logger.e('Error creating generate task: $e');
      return null;
    }
  }

  /// 取消任务
  ///
  /// [taskId] 任务ID
  Future<bool> cancelTask(int taskId) async {
    try {
      Logger.d('Canceling task: $taskId');
      
      final response = await _apiProvider.cancelTask(taskId);
      
      return response.status.isOk;
    } catch (e) {
      Logger.e('Error canceling task: $e');
      return false;
    }
  }
}
