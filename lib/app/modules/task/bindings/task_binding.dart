import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../../../data/repositories/task_repository.dart';

/// 任务绑定
class TaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskRepository>(
      () => TaskRepository(),
    );
    
    Get.lazyPut<TaskController>(
      () => TaskController(),
    );
  }
}
