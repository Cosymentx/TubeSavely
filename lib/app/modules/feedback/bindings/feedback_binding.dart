import 'package:get/get.dart';
import 'package:tubesavely/app/data/repositories/feedback_repository.dart';
import '../controllers/feedback_controller.dart';

class FeedbackBinding extends Bindings {
  @override
  void dependencies() {
    // 注册反馈仓库
    Get.lazyPut<FeedbackRepository>(
      () => FeedbackRepository(),
    );
    
    // 注册反馈控制器
    Get.lazyPut<FeedbackController>(
      () => FeedbackController(),
    );
  }
}
