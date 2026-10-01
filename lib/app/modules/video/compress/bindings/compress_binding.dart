import 'package:get/get.dart';
import '../controllers/compress_controller.dart';
import '../../../../services/video_compress_service.dart';

class CompressBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<VideoCompressService>()) {
      Get.put(VideoCompressService());
    }
    Get.lazyPut<CompressController>(() => CompressController());
  }
}
