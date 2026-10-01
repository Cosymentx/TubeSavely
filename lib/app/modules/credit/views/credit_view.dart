import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/credit_controller.dart';
import '../../../data/models/credit_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

import 'package:flutter/cupertino.dart';

/// 积分视图
class CreditView extends GetView<CreditController> {
  const CreditView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(
          '我的积分',
          style: AppTextStyles.titleLarge,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      cupertinoNavBar: const CupertinoNavigationBar(
        middle: Text('我的积分'),
      ),
      body: _buildBody(),
    );
  }

  /// 构建主体
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadUserCredits();
        await controller.refreshCreditsHistory();
        await controller.loadCreditAmounts();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreditCard(),
            SizedBox(height: 24.h),
            _buildCreditPackages(),
            SizedBox(height: 24.h),
            _buildCreditHistory(),
          ],
        ),
      ),
    );
  }

  /// 构建积分卡片
  Widget _buildCreditCard() {
    return Obx(() {
      final credits = controller.userCredits.value;
      
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前积分',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                credits?.balance.toString() ?? '0',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '累计获得',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        credits?.totalEarned.toString() ?? '0',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '累计消费',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        credits?.totalSpent.toString() ?? '0',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建积分套餐
  Widget _buildCreditPackages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '积分套餐',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Obx(() {
          if (controller.isLoading.value && controller.creditAmounts.isEmpty) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.creditAmounts.isEmpty) {
            return Center(
              child: Text(
                '暂无积分套餐',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey,
                ),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: controller.creditAmounts.length,
            itemBuilder: (context, index) {
              return _buildCreditPackageItem(controller.creditAmounts[index]);
            },
          );
        }),
      ],
    );
  }

  /// 构建积分套餐项
  Widget _buildCreditPackageItem(CreditAmountModel package) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: package.isPopular
            ? BorderSide(color: Colors.orange, width: 2.w)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showPurchaseDialog(package),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (package.isPopular)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '热门',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              SizedBox(height: 8.h),
              Text(
                package.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${package.amount} 积分',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                '¥${package.price.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建积分历史
  Widget _buildCreditHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '积分记录',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Obx(() {
          if (controller.isLoading.value && controller.creditsHistory.isEmpty) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.creditsHistory.isEmpty) {
            return Center(
              child: Text(
                '暂无积分记录',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.creditsHistory.length + (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.creditsHistory.length) {
                return _buildLoadMoreItem();
              }
              return _buildCreditHistoryItem(controller.creditsHistory[index]);
            },
          );
        }),
      ],
    );
  }

  /// 构建积分历史项
  Widget _buildCreditHistoryItem(CreditHistoryModel history) {
    final isPositive = history.amount > 0;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.action,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (history.description != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      history.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    _formatDateTime(history.createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              (isPositive ? '+' : '') + history.amount.toString(),
              style: AppTextStyles.titleMedium.copyWith(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载更多项
  Widget _buildLoadMoreItem() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        );
      }

      return Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        alignment: Alignment.center,
        child: TextButton(
          onPressed: controller.loadMoreCreditsHistory,
          child: Text('加载更多'),
        ),
      );
    });
  }

  /// 显示购买对话框
  void _showPurchaseDialog(CreditAmountModel package) {
    Get.dialog(
      AlertDialog(
        title: Text('购买积分'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('套餐: ${package.title}'),
            SizedBox(height: 8.h),
            Text('积分: ${package.amount}'),
            SizedBox(height: 8.h),
            Text('价格: ¥${package.price.toStringAsFixed(2)}'),
            SizedBox(height: 16.h),
            Text('请选择支付方式:'),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentMethodButton(
                  icon: Icons.payment,
                  label: '支付宝',
                  onTap: () {
                    Get.back();
                    // TODO: 实现支付宝支付
                    Get.snackbar(
                      '提示',
                      '支付宝支付功能正在开发中',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                _buildPaymentMethodButton(
                  icon: Icons.chat_bubble,
                  label: '微信',
                  onTap: () {
                    Get.back();
                    // TODO: 实现微信支付
                    Get.snackbar(
                      '提示',
                      '微信支付功能正在开发中',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 构建支付方式按钮
  Widget _buildPaymentMethodButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32.w),
            SizedBox(height: 8.h),
            Text(label),
          ],
        ),
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
