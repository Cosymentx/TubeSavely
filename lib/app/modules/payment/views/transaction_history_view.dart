import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tubesavely/app/data/models/payment_model.dart';
import 'package:tubesavely/app/modules/payment/controllers/transaction_history_controller.dart';
import 'package:tubesavely/app/routes/app_pages.dart';
import 'package:tubesavely/app/theme/app_colors.dart';
import 'package:tubesavely/app/theme/app_text_styles.dart';
import 'package:tubesavely/app/utils/utils.dart';

import 'package:flutter/cupertino.dart';
import '../../../widgets/empty_state.dart';

/// 交易记录页面
class TransactionHistoryView extends GetView<TransactionHistoryController> {
  const TransactionHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text(
          '交易记录',
          style: AppTextStyles.titleLarge,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      cupertinoNavBar: const CupertinoNavigationBar(
        middle: Text('交易记录'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.transactions.isEmpty) {
          return _buildEmptyState();
        }

        return _buildTransactionList();
      }),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: EmptyState(
        icon: Icons.receipt_long,
        title: '暂无交易记录',
        subtitle: '您的充值与会员订阅记录将显示在这里',
        actionLabel: '去充值',
        onAction: () => Get.back(),
      ),
    );
  }

  /// 构建交易列表
  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: controller.loadTransactions,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: controller.transactions.length,
        itemBuilder: (context, index) {
          final transaction = controller.transactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  /// 构建交易项
  Widget _buildTransactionItem(OrderModel transaction) {
    return GestureDetector(
      onTap: () => _showTransactionDetails(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.r),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // 状态图标
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getStatusIcon(transaction.status),
                  color: _getStatusColor(transaction.status),
                  size: 24.r,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // 交易信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.productId,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Get.theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    Utils.formatDateTime(transaction.createdAt,
                        format: 'yyyy-MM-dd HH:mm'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // 金额
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.amount} ${transaction.currency.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _getStatusName(transaction.status),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _getStatusColor(transaction.status),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 显示交易详情
  void _showTransactionDetails(OrderModel transaction) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '交易详情',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // 详情
            _buildDetailItem('订单编号', transaction.id),
            _buildDetailItem('商品', transaction.productId),
            _buildDetailItem('金额',
                '${transaction.amount} ${transaction.currency.toUpperCase()}'),
            _buildDetailItem(
                '支付方式', _getPaymentMethodName(transaction.paymentMethod)),
            _buildDetailItem('状态', _getStatusName(transaction.status)),
            _buildDetailItem(
                '创建时间',
                Utils.formatDateTime(transaction.createdAt,
                    format: 'yyyy-MM-dd HH:mm')),
            if (transaction.completedAt != null)
              _buildDetailItem(
                  '完成时间',
                  Utils.formatDateTime(transaction.completedAt!,
                      format: 'yyyy-MM-dd HH:mm')),
            SizedBox(height: 24.h),
            // 按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  '关闭',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建详情项
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Get.theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 获取状态图标
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /// 获取支付方式名称
  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.creem:
        return 'Creem';
      case PaymentMethod.alipay:
        return '支付宝';
      case PaymentMethod.wechatPay:
        return '微信支付';
    }
    return '未知';
  }

  /// 获取状态名称
  String _getStatusName(String status) {
    switch (status) {
      case 'pending':
        return '待支付';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      case 'canceled':
        return '已取消';
      default:
        return '未知';
    }
  }
}
