import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/api_test_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';

import 'package:flutter/cupertino.dart';

/// API测试页面
class ApiTestView extends GetView<ApiTestController> {
  const ApiTestView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(
          'API测试',
          style: AppTextStyles.titleLarge,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      cupertinoNavBar: const CupertinoNavigationBar(
        middle: Text('API测试'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApiTestSection(),
            SizedBox(height: 16.h),
            _buildApiResponseSection(),
          ],
        ),
      ),
    );
  }

  /// 构建API测试区域
  Widget _buildApiTestSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API测试',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildApiSelector(),
            SizedBox(height: 16.h),
            _buildApiParamsSection(),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.sendApiRequest,
                    child: controller.isLoading.value
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('发送请求'),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建API选择器
  Widget _buildApiSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择API',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedApi.value,
              decoration: InputDecoration(
                labelText: 'API接口',
                border: OutlineInputBorder(),
              ),
              items: controller.apiList
                  .map((api) => DropdownMenuItem(
                        value: api,
                        child: Text(api),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedApi.value = value;
                  controller.updateParamsForSelectedApi();
                }
              },
            )),
      ],
    );
  }

  /// 构建API参数区域
  Widget _buildApiParamsSection() {
    return Obx(() {
      final params = controller.apiParams;
      
      if (params.isEmpty) {
        return Text(
          '该API不需要参数',
          style: AppTextStyles.bodyMedium,
        );
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '参数',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          ...params.entries.map((entry) => _buildParamField(entry.key, entry.value)),
        ],
      );
    });
  }
  
  /// 构建参数输入字段
  Widget _buildParamField(String key, dynamic defaultValue) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: TextField(
        controller: controller.getControllerForParam(key),
        decoration: InputDecoration(
          labelText: key,
          hintText: defaultValue?.toString() ?? '',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  /// 构建API响应区域
  Widget _buildApiResponseSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '响应结果',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Obx(() => Text(
                    controller.apiResponse.value.isEmpty
                        ? '请发送请求...'
                        : controller.apiResponse.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: 'monospace',
                    ),
                  )),
              constraints: BoxConstraints(
                minHeight: 200.h,
                maxHeight: 400.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
