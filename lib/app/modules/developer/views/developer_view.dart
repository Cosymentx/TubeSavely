import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tubesavely/app/data/models/payment_model.dart';
import '../controllers/developer_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

import 'package:flutter/cupertino.dart';

/// 开发者测试页面
class DeveloperView extends GetView<DeveloperController> {
  const DeveloperView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(
          '开发者测试',
          style: AppTextStyles.titleLarge,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      cupertinoNavBar: const CupertinoNavigationBar(
        middle: Text('开发者测试'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 功能分组标题
            _buildSectionTitle('账户管理（登录/注册）'),
            _buildLoginTestSection(),
            SizedBox(height: 16.h),
            _buildMockLoginSection(),
            SizedBox(height: 24.h),

            // 用户信息区域
            _buildSectionTitle('用户信息'),
            _buildUserInfoSection(),
            SizedBox(height: 24.h),

            // 高级用户测试
            _buildSectionTitle('会员功能测试'),
            _buildPremiumTestSection(),
            SizedBox(height: 24.h),

            // 支付测试
            _buildSectionTitle('支付功能测试'),
            _buildPaymentTestSection(),
            SizedBox(height: 24.h),

            // API测试（放在最后，不常用）
            _buildSectionTitle('API测试工具'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(Routes.API_TEST),
                    icon: Icon(Icons.api),
                    label: Text('打开API接口测试工具'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _buildApiTestSection(),
          ],
        ),
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户信息区域
  Widget _buildUserInfoSection() {
    return Obx(() {
      final isLoggedIn = controller.isLoggedIn.value;
      final user = controller.currentUser.value;

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
              if (isLoggedIn && user != null) ...[
                // 用户基本信息头部
                Row(
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 30.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username ?? '未设置用户名',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            user.email ?? '未设置邮箱',
                            style: AppTextStyles.bodyMedium,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: user.isPremium
                                      ? AppColors.warning.withAlpha(50)
                                      : AppColors.textSecondary.withAlpha(50),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  user.isPro
                                      ? '专业用户'
                                      : (user.isPremium ? '高级用户' : '普通用户'),
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: user.isPremium
                                        ? AppColors.warning
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withAlpha(50),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  '积分: ${user.credits}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // 用户详细信息
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('ID', user.id?.toString() ?? ''),
                      _buildInfoRow('用户ID', user.userId ?? ''),
                      _buildInfoRow('等级', '${user.level}'),
                      _buildInfoRow(
                          '会员到期',
                          user.membershipExpiry != null
                              ? '${user.membershipExpiry!.year}-${user.membershipExpiry!.month.toString().padLeft(2, '0')}-${user.membershipExpiry!.day.toString().padLeft(2, '0')}'
                              : '无'),
                      _buildInfoRow(
                          '会员状态', user.isMembershipActive ? '有效' : '无效'),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // 退出登录按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.logout,
                    icon: Icon(Icons.logout),
                    label: Text('退出登录'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withAlpha(30),
                      foregroundColor: AppColors.error,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ] else
                // 未登录状态
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 48.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '未登录',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '请使用上方的登录功能登录账号',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
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
            // API请求区域
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: controller.apiUrlController,
                    decoration: InputDecoration(
                      labelText: 'API路径',
                      hintText: '/parse',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 1,
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: controller.selectedMethod.value,
                        decoration: InputDecoration(
                          labelText: '方法',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 16.h,
                          ),
                        ),
                        items: controller.httpMethods
                            .map((method) => DropdownMenuItem(
                                  value: method,
                                  child: Text(method),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedMethod.value = value;
                          }
                        },
                      )),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // 参数输入区域
            TextField(
              controller: controller.apiParamsController,
              decoration: InputDecoration(
                labelText: '参数 (JSON)',
                hintText: '{"url": "https://example.com/video"}',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12.h),

            // 发送请求按钮
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                    onPressed: controller.isApiLoading.value
                        ? null
                        : controller.sendApiRequest,
                    icon: controller.isApiLoading.value
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.onPrimary),
                            ),
                          )
                        : Icon(Icons.send),
                    label: Text('发送请求'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  )),
            ),
            SizedBox(height: 16.h),

            // 响应结果区域
            Row(
              children: [
                Icon(Icons.receipt_long, size: 16.sp),
                SizedBox(width: 4.w),
                Text(
                  '响应结果:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border),
              ),
              constraints: BoxConstraints(
                minHeight: 100.h,
                maxHeight: 200.h,
              ),
              child: Obx(() => Text(
                    controller.apiResponse.value.isEmpty
                        ? '请发送请求...'
                        : controller.apiResponse.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: 'monospace',
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建登录测试区域
  Widget _buildLoginTestSection() {
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
            // 输入区域
            TextField(
              controller: controller.emailController,
              decoration: InputDecoration(
                labelText: '邮箱',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller.passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller.mockNameController,
              decoration: InputDecoration(
                labelText: '用户名 (注册时需要)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 16.h),

            // 主要操作按钮
            Row(
              children: [
                Expanded(
                  child: Obx(() => ElevatedButton.icon(
                        onPressed: controller.isLoginLoading.value
                            ? null
                            : controller.apiLogin,
                        icon: controller.isLoginLoading.value
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.onPrimary),
                                ),
                              )
                            : Icon(Icons.login),
                        label: Text('登录'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      )),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() => ElevatedButton.icon(
                        onPressed: controller.isLoginLoading.value
                            ? null
                            : controller.apiRegister,
                        icon: Icon(Icons.person_add),
                        label: Text('注册'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      )),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // 次要操作按钮
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                Obx(() => OutlinedButton.icon(
                      onPressed: controller.isLoginLoading.value
                          ? null
                          : controller.apiResetPassword,
                      icon: Icon(Icons.restore, size: 16.sp),
                      label: Text('重置密码'),
                    )),
                Obx(() => OutlinedButton.icon(
                      onPressed: controller.isLoginLoading.value
                          ? null
                          : controller.apiGetUserInfo,
                      icon: Icon(Icons.info_outline, size: 16.sp),
                      label: Text('获取用户信息'),
                    )),
                Obx(() => controller.isLoggedIn.value
                    ? OutlinedButton.icon(
                        onPressed: controller.logout,
                        icon: Icon(Icons.logout, size: 16.sp),
                        label: Text('退出登录'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                        ),
                      )
                    : SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模拟登录区域
  Widget _buildMockLoginSection() {
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
            // 基本信息
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.mockNameController,
                    decoration: InputDecoration(
                      labelText: '用户名',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: controller.mockEmailController,
                    decoration: InputDecoration(
                      labelText: '邮箱',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // 用户ID和等级
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.mockIdController,
                    decoration: InputDecoration(
                      labelText: '用户ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '用户等级',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star_outline),
                      hintText: '0=普通, 1=高级, 2=专业',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        controller.mockUserLevel.value =
                            int.tryParse(value) ?? 0;
                      }
                    },
                    controller: TextEditingController(
                        text: controller.mockUserLevel.value.toString()),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // 积分
            TextField(
              decoration: InputDecoration(
                labelText: '积分',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  controller.mockUserCredits.value = int.tryParse(value) ?? 0;
                }
              },
              controller: TextEditingController(
                  text: controller.mockUserCredits.value.toString()),
            ),
            SizedBox(height: 16.h),

            // 模拟登录按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.mockLogin,
                icon: Icon(Icons.login),
                label: Text('模拟登录'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建高级用户测试区域
  Widget _buildPremiumTestSection() {
    return Obx(() {
      final isLoggedIn = controller.isLoggedIn.value;
      final isPremium = controller.isPremiumUser.value;
      final isPro = controller.isProUser.value;

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
              if (!isLoggedIn)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(30),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.warning.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '请先登录后再使用会员功能测试',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // 会员等级说明
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '会员等级说明',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '普通用户: 基础功能\n高级用户: 无广告、高清下载\n专业用户: 所有高级功能 + 批量下载',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // 会员切换开关
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: isPremium
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text('高级用户'),
                          ],
                        ),
                        subtitle: Text('无广告、高清下载'),
                        value: isPremium,
                        onChanged: (_) => controller.togglePremiumUser(),
                        activeColor: AppColors.primary,
                      ),
                      Divider(height: 1),
                      SwitchListTile(
                        title: Row(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: isPro
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text('专业用户'),
                          ],
                        ),
                        subtitle: Text('所有高级功能 + 批量下载'),
                        value: isPro,
                        onChanged: (_) => controller.toggleProUser(),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建支付测试区域
  Widget _buildPaymentTestSection() {
    return Obx(() {
      final isLoggedIn = controller.isLoggedIn.value;
      final products = controller.products;
      final selectedProduct = controller.selectedProduct.value;
      final currentOrder = controller.currentOrder.value;
      final isLoading = controller.isPaymentLoading.value;
      final isStripeAvailable = controller.isStripeAvailable.value;
      final isGooglePayAvailable = controller.isGooglePayAvailable.value;

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
                '支付测试',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              if (!isLoggedIn)
                Text(
                  '请先登录',
                  style: AppTextStyles.bodyMedium,
                )
              else ...[
                // 支付服务状态
                _buildPaymentServicesStatus(
                    isStripeAvailable, isGooglePayAvailable),
                SizedBox(height: 16.h),

                // 商品列表
                Text(
                  '选择商品',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                if (products.isEmpty)
                  Text(
                    '暂无商品',
                    style: AppTextStyles.bodyMedium,
                  )
                else
                  SizedBox(
                    height: 120.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final isSelected = selectedProduct?.id == product.id;

                        return GestureDetector(
                          onTap: () => controller.selectProduct(product),
                          child: Container(
                            width: 150.w,
                            margin: EdgeInsets.only(right: 8.w),
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withAlpha(25)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isSelected ? AppColors.primary : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${product.price} ${product.currency}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  product.description,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16.h),

                // 支付方式
                Text(
                  '选择支付方式',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildPaymentMethods(),
                SizedBox(height: 16.h),

                // 订单信息
                if (currentOrder != null) ...[
                  Text(
                    '当前订单',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('订单ID', currentOrder.id),
                        _buildInfoRow('商品', currentOrder.productId),
                        _buildInfoRow('金额',
                            '${currentOrder.amount} ${currentOrder.currency}'),
                        _buildInfoRow('状态', currentOrder.status),
                        _buildInfoRow(
                            '支付方式',
                            currentOrder.paymentMethod
                                .toString()
                                .split('.')
                                .last),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : controller.createOrder,
                        child: isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.onPrimary),
                                ),
                              )
                            : Text('创建订单'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading || currentOrder == null
                            ? null
                            : controller.processPayment,
                        child: Text('处理支付'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isLoading || currentOrder == null
                        ? null
                        : controller.getOrderStatus,
                    child: Text('查询订单状态'),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : controller.testMembershipBenefits,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text('测试会员权益'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : controller.simulateSuccessfulPayment,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                        ),
                        child: Text('模拟支付成功'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  /// 构建支付服务状态
  Widget _buildPaymentServicesStatus(
      bool isStripeAvailable, bool isGooglePayAvailable) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '支付服务状态',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                isStripeAvailable ? Icons.check_circle : Icons.cancel,
                color: isStripeAvailable ? AppColors.success : AppColors.error,
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                'Stripe: ${isStripeAvailable ? '可用' : '不可用'}',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(width: 16.w),
              Icon(
                isGooglePayAvailable ? Icons.check_circle : Icons.cancel,
                color:
                    isGooglePayAvailable ? AppColors.success : AppColors.error,
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                'Google Pay: ${isGooglePayAvailable ? '可用' : '不可用'}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建支付方式
  Widget _buildPaymentMethods() {
    return Obx(() {
      final selectedMethod = controller.selectedPaymentMethod.value;

      return Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          _buildPaymentMethodItem(
              'Stripe', PaymentMethod.stripe, selectedMethod),
          _buildPaymentMethodItem(
              'Google Pay', PaymentMethod.googlePay, selectedMethod),
          _buildPaymentMethodItem('支付宝', PaymentMethod.alipay, selectedMethod),
          _buildPaymentMethodItem(
              '微信支付', PaymentMethod.wechatPay, selectedMethod),
        ],
      );
    });
  }

  /// 构建支付方式项
  Widget _buildPaymentMethodItem(
      String name, PaymentMethod method, PaymentMethod selectedMethod) {
    final isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: () => controller.selectPaymentMethod(method),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withAlpha(25) : AppColors.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
      ),
    );
  }
}
