import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/adaptive/adaptive_scaffold.dart';
import '../controllers/compress_controller.dart';
import 'widgets/compress_settings_panel.dart';
import 'widgets/compress_task_card.dart';

class CompressView extends GetView<CompressController> {
  const CompressView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AppBar(
        title: Text('视频压缩 (Video Compressor)', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '打开输出目录',
            onPressed: controller.openOutputFolder,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: '清空已完成',
            onPressed: controller.clearCompleted,
          ),
        ],
      ),
      cupertinoNavBar: CupertinoNavigationBar(
        middle: const Text('视频压缩'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: controller.openOutputFolder,
              child: const Icon(CupertinoIcons.folder, size: 22),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;
            return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
          },
        ),
      ),
    );
  }

  /// PC 桌面端宽屏双栏布局
  Widget _buildDesktopLayout() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：压缩参数设置面板
          SizedBox(
            width: 360.w,
            child: const SingleChildScrollView(
              child: CompressSettingsPanel(),
            ),
          ),
          SizedBox(width: 20.w),

          // 右侧：导入区、任务队列、实时统计
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderActionBar(),
                SizedBox(height: 12.h),
                Expanded(child: _buildTaskList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 移动端单栏滚动布局
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderActionBar(),
          SizedBox(height: 16.h),
          const CompressSettingsPanel(),
          SizedBox(height: 16.h),
          Text('任务队列', style: AppTextStyles.titleMedium),
          SizedBox(height: 8.h),
          _buildTaskList(),
        ],
      ),
    );
  }

  /// 顶部操作卡片与添加视频入口
  Widget _buildHeaderActionBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight10),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.pickVideos,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('添加视频文件 (支持批量多选)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight25,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Obx(() {
            return Row(
              children: [
                _buildStatPill('队列', '${controller.tasks.length}'),
                SizedBox(width: 8.w),
                _buildStatPill('已完成', '${controller.completedCount}'),
                SizedBox(width: 8.w),
                if (controller.totalSavedMB > 0)
                  _buildStatPill('已节省', '${controller.totalSavedMB.toStringAsFixed(1)} MB', isHighlight: true),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.green.withValues(alpha: 0.1) : AppColors.primaryLight10,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.green[800] : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 任务列表
  Widget _buildTaskList() {
    return Obx(() {
      if (controller.tasks.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        shrinkWrap: Get.context != null && MediaQuery.of(Get.context!).size.width < 850,
        physics: Get.context != null && MediaQuery.of(Get.context!).size.width < 850
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        itemCount: controller.tasks.length,
        itemBuilder: (context, index) {
          final task = controller.tasks[index];
          return CompressTaskCard(task: task);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Container(
      height: 240.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight10, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_collection_outlined, size: 48.sp, color: AppColors.primaryLight25),
          SizedBox(height: 12.h),
          Text('暂无待压缩视频', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 6.h),
          Text('点击上方按钮添加视频文件，支持批量压缩', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
