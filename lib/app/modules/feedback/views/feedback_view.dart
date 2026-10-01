import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tubesavely/app/theme/app_colors.dart';
import 'package:tubesavely/app/theme/app_text_styles.dart';
import '../controllers/feedback_controller.dart';

class FeedbackView extends GetView<FeedbackController> {
  const FeedbackView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('意见反馈'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 反馈类型
              Text(
                '反馈类型',
                style: AppTextStyles.titleMedium,
              ),
              SizedBox(height: 8.h),
              Obx(() => _buildFeedbackTypeSelector()),
              SizedBox(height: 16.h),

              // 反馈内容
              Text(
                '反馈内容',
                style: AppTextStyles.titleMedium,
              ),
              SizedBox(height: 8.h),
              _buildFeedbackContentField(),
              SizedBox(height: 16.h),

              // 姓名
              Text(
                '姓名（选填）',
                style: AppTextStyles.titleMedium,
              ),
              SizedBox(height: 8.h),
              _buildNameField(),
              SizedBox(height: 16.h),

              // 邮箱
              Text(
                '邮箱（选填）',
                style: AppTextStyles.titleMedium,
              ),
              SizedBox(height: 8.h),
              _buildEmailField(),
              SizedBox(height: 24.h),

              // 提交按钮
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 反馈类型选择器
  Widget _buildFeedbackTypeSelector() {
    return Wrap(
      spacing: 8.w,
      children: controller.feedbackTypes.map((type) {
        final bool isSelected = controller.selectedType.value == type['value'];
        return ChoiceChip(
          label: Text(type['label']),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              controller.selectedType.value = type['value'];
            }
          },
          backgroundColor: AppColors.background,
          selectedColor: Colors.blue.shade100,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  // 反馈内容输入框
  Widget _buildFeedbackContentField() {
    return TextField(
      controller: controller.contentController,
      maxLines: 5,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: '请描述您的问题或建议...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  // 姓名输入框
  Widget _buildNameField() {
    return TextField(
      controller: controller.nameController,
      decoration: InputDecoration(
        hintText: '请输入您的姓名',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  // 邮箱输入框
  Widget _buildEmailField() {
    return TextField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: '请输入您的邮箱',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  // 提交按钮
  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : controller.submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: controller.isSubmitting.value
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    '提交反馈',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ));
  }
}
