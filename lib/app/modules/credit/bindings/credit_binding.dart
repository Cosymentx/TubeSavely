import 'package:get/get.dart';
import '../controllers/credit_controller.dart';
import '../../../data/repositories/credit_repository.dart';

/// 积分绑定
class CreditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreditRepository>(
      () => CreditRepository(),
    );
    
    Get.lazyPut<CreditController>(
      () => CreditController(),
    );
  }
}
