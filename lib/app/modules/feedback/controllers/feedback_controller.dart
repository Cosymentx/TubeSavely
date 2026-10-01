import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tubesavely/app/data/repositories/feedback_repository.dart';
import 'package:tubesavely/app/utils/logger.dart';
import 'package:tubesavely/app/utils/utils.dart';

/// 反馈控制器
class FeedbackController extends GetxController {
  final FeedbackRepository _feedbackRepository = Get.find<FeedbackRepository>();

  // 反馈内容控制器
  final TextEditingController contentController = TextEditingController();

  // 邮箱控制器
  final TextEditingController emailController = TextEditingController();

  // 姓名控制器
  final TextEditingController nameController = TextEditingController();

  // 反馈类型
  final RxString selectedType = 'bug'.obs;

  // 反馈类型列表
  final List<Map<String, dynamic>> feedbackTypes = [
    {'value': 'bug', 'label': '问题报告'},
    {'value': 'feature', 'label': '功能建议'},
    {'value': 'general', 'label': '一般反馈'},
    {'value': 'other', 'label': '其他'},
  ];

  // 是否正在提交
  final RxBool isSubmitting = false.obs;

  @override
  void onClose() {
    contentController.dispose();
    emailController.dispose();
    nameController.dispose();
    super.onClose();
  }

  /// 提交反馈
  Future<void> submitFeedback() async {
    // 检查反馈内容是否为空
    if (contentController.text.trim().isEmpty) {
      Utils.showSnackbar('错误', '请输入反馈内容', isError: true);
      return;
    }

    try {
      isSubmitting.value = true;

      // 提交反馈
      final success = await _feedbackRepository.submitFeedback(
        contentController.text.trim(),
        email: emailController.text.trim().isNotEmpty
            ? emailController.text.trim()
            : null,
        name: nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : null,
        type: selectedType.value,
      );

      if (success) {
        Utils.showSnackbar('成功', '感谢您的反馈！');

        // 清空输入框
        contentController.clear();
        emailController.clear();
        nameController.clear();
        selectedType.value = 'bug';

        // 返回上一页
        Get.back();
      } else {
        Utils.showSnackbar('错误', '提交反馈失败，请稍后重试', isError: true);
      }
    } catch (e) {
      Logger.e('Error submitting feedback: $e');
      Utils.showSnackbar('错误', '提交反馈时出错: $e', isError: true);
    } finally {
      isSubmitting.value = false;
    }
  }
}
