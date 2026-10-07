import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../controllers/workspace_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../tasks/controllers/tasks_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../video/convert/controllers/convert_controller.dart';
import '../../video/compress/controllers/compress_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MainController>(
      MainController(),
      permanent: true,
    );

    Get.put<WorkspaceController>(
      WorkspaceController(),
      permanent: true,
    );

    // 预先加载核心标签页与工具控制器
    Get.put<HomeController>(
      HomeController(),
      permanent: true,
    );

    Get.put<HistoryController>(
      HistoryController(),
      permanent: true,
    );

    Get.put<TasksController>(
      TasksController(),
      permanent: true,
    );

    Get.put<ProfileController>(
      ProfileController(),
      permanent: true,
    );

    Get.lazyPut<ConvertController>(
      () => ConvertController(),
      fenix: true,
    );

    Get.lazyPut<CompressController>(
      () => CompressController(),
      fenix: true,
    );
  }
}
