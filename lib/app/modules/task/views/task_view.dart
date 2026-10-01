import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/task_controller.dart';
import '../../../data/models/task_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 任务视图
class TaskView extends GetView<TaskController> {
  const TaskView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '我的任务',
          style: AppTextStyles.titleLarge,
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// 构建主体
  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value && controller.tasks.isEmpty) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.tasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64.w,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16.h),
              Text(
                '暂无任务',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '您还没有创建任何任务',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshTasks,
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount:
              controller.tasks.length + (controller.hasMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.tasks.length) {
              return _buildLoadMoreItem();
            }
            return _buildTaskItem(controller.tasks[index]);
          },
        ),
      );
    });
  }

  /// 构建任务项
  Widget _buildTaskItem(TaskModel task) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      task.statusText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(task.type),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      task.typeText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${task.creditsCost} 积分',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                task.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  task.description!,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 8.h),
              if (task.status == TaskStatus.processing) ...[
                LinearProgressIndicator(
                  value: task.progress,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  task.progressText,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ],
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '创建时间: ${_formatDateTime(task.createdAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (task.canCancel)
                    TextButton(
                      onPressed: () => _cancelTask(task),
                      child: Text('取消任务'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建加载更多项
  Widget _buildLoadMoreItem() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        );
      }

      return Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        alignment: Alignment.center,
        child: TextButton(
          onPressed: controller.loadMoreTasks,
          child: Text('加载更多'),
        ),
      );
    });
  }

  /// 显示任务详情
  void _showTaskDetail(TaskModel task) {
    Get.dialog(
      AlertDialog(
        title: Text('任务详情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('标题: ${task.title}'),
              if (task.description != null) Text('描述: ${task.description}'),
              Text('类型: ${task.typeText}'),
              Text('状态: ${task.statusText}'),
              Text('积分消耗: ${task.creditsCost}'),
              Text('创建时间: ${_formatDateTime(task.createdAt)}'),
              if (task.updatedAt != null)
                Text('更新时间: ${_formatDateTime(task.updatedAt!)}'),
              if (task.completedAt != null)
                Text('完成时间: ${_formatDateTime(task.completedAt!)}'),
              if (task.status == TaskStatus.failed && task.errorMessage != null)
                Text('错误信息: ${task.errorMessage}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('关闭'),
          ),
          if (task.canCancel)
            TextButton(
              onPressed: () {
                Get.back();
                _cancelTask(task);
              },
              child: Text('取消任务'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  /// 取消任务
  void _cancelTask(TaskModel task) {
    Get.dialog(
      AlertDialog(
        title: Text('取消任务'),
        content: Text('确定要取消该任务吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await controller.cancelTask(task.id!);
              if (success) {
                Get.snackbar(
                  '成功',
                  '任务已取消',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  '失败',
                  '取消任务失败，请稍后重试',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text('确定'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('筛选任务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('全部任务'),
              onTap: () {
                controller.filterByTaskType(null);
                Get.back();
              },
            ),
            ListTile(
              title: Text('转换任务'),
              onTap: () {
                controller.filterByTaskType(TaskType.convert);
                Get.back();
              },
            ),
            ListTile(
              title: Text('生成任务'),
              onTap: () {
                controller.filterByTaskType(TaskType.generate);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.info;
      case TaskStatus.processing:
        return AppColors.warning;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.failed:
        return AppColors.error;
      case TaskStatus.canceled:
        return AppColors.textSecondary;
    }
  }

  /// 获取类型颜色
  Color _getTypeColor(TaskType type) {
    switch (type) {
      case TaskType.convert:
        return AppColors.accent;
      case TaskType.generate:
        return AppColors.primary;
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
