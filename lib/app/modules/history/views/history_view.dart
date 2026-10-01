import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/models/video_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../widgets/adaptive/adaptive_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../controllers/history_controller.dart';

/// History视图 - 自适应多端支持
class HistoryView extends GetView<HistoryController> {
  const HistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: _buildAppBar(),
      cupertinoNavBar: _buildCupertinoNavBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildHistoryList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  CupertinoNavigationBar _buildCupertinoNavBar() {
    return CupertinoNavigationBar(
      middle: const Text('下载历史'),
      trailing: Obx(() {
        if (controller.isEditing.value) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: controller.selectAll,
                child: const Icon(CupertinoIcons.checkmark_circle, size: 22),
              ),
              SizedBox(width: 8.w),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: controller.selectedItems.isNotEmpty ? controller.deleteSelected : null,
                child: Icon(
                  CupertinoIcons.delete,
                  size: 22,
                  color: controller.selectedItems.isNotEmpty
                      ? CupertinoColors.destructiveRed
                      : CupertinoColors.inactiveGray,
                ),
              ),
            ],
          );
        } else {
          return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: controller.toggleEditMode,
            child: const Icon(CupertinoIcons.pencil, size: 22),
          );
        }
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        '下载历史',
        style: AppTextStyles.titleLarge,
      ),
      centerTitle: true,
      elevation: 0,
      actions: [
        Obx(() {
          if (controller.isEditing.value) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: controller.selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: controller.selectedItems.isNotEmpty ? controller.deleteSelected : null,
                ),
              ],
            );
          } else {
            return IconButton(
              icon: const Icon(Icons.edit),
              onPressed: controller.toggleEditMode,
            );
          }
        }),
      ],
    );
  }

  // 搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索历史记录...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Get.theme.colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        onChanged: controller.searchHistory,
      ),
    );
  }

  // 历史记录列表
  Widget _buildHistoryList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.historyList.isEmpty) {
        return const Center(
          child: EmptyState(
            icon: Icons.history_rounded,
            title: '暂无下载历史',
            subtitle: '已下载完成的视频将显示在此处',
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: controller.historyList.length,
        itemBuilder: (context, index) {
          final video = controller.historyList[index];
          return _buildHistoryItem(video);
        },
      );
    });
  }

  // 历史记录项
  Widget _buildHistoryItem(VideoModel video) {
    return Obx(() {
      final isSelected = controller.isSelected(video);

      return Card(
        margin: EdgeInsets.only(bottom: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => controller.viewVideoDetail(video),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 缩略图
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: video.thumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: video.thumbnail!,
                          width: 100.w,
                          height: 70.h,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceVariant,
                            child: Icon(
                              Icons.error,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Container(
                          width: 100.w,
                          height: 70.h,
                          color: AppColors.surfaceVariant,
                          child: Icon(
                            Icons.video_library,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                // 视频信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            video.platform ?? '未知平台',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.access_time,
                            size: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            video.formattedDuration,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      if (video.createdAt != null)
                        Text(
                          '添加时间: ${_formatDateTime(video.createdAt!)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // 选择指示器
                if (controller.isEditing.value)
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary.withAlpha(76),
                      size: 24.sp,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // 构建浮动操作按钮
  Widget? _buildFloatingActionButton() {
    return Obx(() {
      if (controller.isEditing.value) {
        return FloatingActionButton(
          onPressed: controller.toggleEditMode,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.check),
        );
      } else {
        return FloatingActionButton(
          onPressed: _showClearHistoryConfirmation,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.delete_sweep),
        );
      }
    });
  }

  // 显示清空历史记录确认对话框
  void _showClearHistoryConfirmation() {
    Get.dialog(
      AdaptiveDialog(
        title: '清空历史记录',
        message: '确定要清空所有下载历史记录吗？',
        confirmButtonText: '清空',
        cancelButtonText: '取消',
        isDangerousAction: true,
        onConfirm: () => controller.clearHistory(),
      ),
    );
  }
}
