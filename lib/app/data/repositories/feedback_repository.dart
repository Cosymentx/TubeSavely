import 'package:get/get.dart';
import 'package:tubesavely/app/data/models/feedback_model.dart';
import 'package:tubesavely/app/data/providers/api_provider.dart';
import 'package:tubesavely/app/utils/logger.dart';

/// 反馈仓库
///
/// 负责处理用户反馈相关的数据操作
class FeedbackRepository {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  /// 提交反馈
  ///
  /// [content] 反馈内容
  /// [email] 联系邮箱
  /// [name] 姓名
  /// [type] 反馈类型
  Future<bool> submitFeedback(String content,
      {String? email, String? name, String type = 'bug'}) async {
    try {
      Logger.d('Submitting feedback: $content');

      // 调用API提交反馈
      final response = await _apiProvider.submitFeedback(
        content,
        email: email,
        name: name,
        type: type,
      );

      // 检查响应状态
      return response.status.isOk;
    } catch (e) {
      Logger.e('Error submitting feedback: $e');
      return false;
    }
  }
}
