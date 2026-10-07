import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/download_task_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/utils.dart';
import '../../../home/controllers/home_controller.dart';
import '../../../profile/views/profile_view.dart';
import '../../../video/compress/views/compress_view.dart';
import '../../../video/convert/views/convert_view.dart';
import '../../controllers/workspace_controller.dart';

/// 桌面工作台中央主队列与工作流视图 (Downie + Motrix 风格)
class WorkspaceCenterList extends StatelessWidget {
  const WorkspaceCenterList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkspaceController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final section = controller.currentSection.value;

      // 嵌合子工作流视图
      switch (section) {
        case WorkspaceSection.convert:
          return const ConvertView();
        case WorkspaceSection.compress:
          return const CompressView();
        case WorkspaceSection.profile:
          return const ProfileView();
        case WorkspaceSection.trending:
          return _buildTrendingWorkspace(context, isDark);
        default:
          return _buildTaskQueueWorkbench(context, controller, isDark);
      }
    });
  }

  // ==================== 1. 任务队列主工作台 ====================

  Widget _buildTaskQueueWorkbench(
      BuildContext context, WorkspaceController controller, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 顶部操作栏 (分类标题、搜索、批量动作、视图切换)
          _buildCenterToolbar(context, controller, isDark),

          // 核心任务列表 (卡片视图 vs 紧凑表格视图)
          Expanded(
            child: Obx(() {
              final tasks = controller.filteredTasks;
              if (tasks.isEmpty) {
                return _buildEmptyState(context, controller, isDark);
              }

              final isTable = controller.isCompactTableView.value;
              if (isTable) {
                return _buildTableView(context, controller, tasks, isDark);
              } else {
                return _buildCardListView(context, controller, tasks, isDark);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterToolbar(
      BuildContext context, WorkspaceController controller, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0F19) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 区域标题
          Obx(() {
            String title = '全部传输任务';
            if (controller.currentSection.value == WorkspaceSection.downloading) {
              title = '正在下载';
            } else if (controller.currentSection.value == WorkspaceSection.completed) {
              title = '已完成记录';
            }
            final count = controller.filteredTasks.length;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(width: AppSpacing.md),

          // 快速搜索筛选条
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 15,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => controller.searchKeyword.value = val,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: '筛选文件名/格式...',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // 批量控制按钮群 (Motrix 风格)
          Obx(() {
            final activeCount = controller.downloadingCount;
            if (activeCount > 0) {
              return TextButton.icon(
                onPressed: controller.pauseAll,
                icon: const Icon(Icons.pause_circle_outline_rounded, size: 15),
                label: const Text('全部暂停', style: TextStyle(fontSize: 11.5)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          TextButton.icon(
            onPressed: controller.resumeAll,
            icon: const Icon(Icons.play_circle_outline_rounded, size: 15),
            label: const Text('全部恢复', style: TextStyle(fontSize: 11.5)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Obx(() {
            if (controller.completedCount > 0) {
              return TextButton.icon(
                onPressed: controller.clearCompleted,
                icon: const Icon(Icons.cleaning_services_outlined, size: 15),
                label: const Text('清空完成', style: TextStyle(fontSize: 11.5)),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: AppSpacing.xs),

          // 视图切换按钮 (卡片 vs 紧凑表格)
          Obx(() {
            final isTable = controller.isCompactTableView.value;
            return IconButton(
              tooltip: isTable ? '切换为大图卡片视图' : '切换为紧凑表格视图',
              icon: Icon(
                isTable ? Icons.view_headline_rounded : Icons.view_agenda_outlined,
                size: 17,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              onPressed: controller.toggleTableView,
              visualDensity: VisualDensity.compact,
            );
          }),
        ],
      ),
    );
  }

  // ==================== 卡片视图 (Downie 风格) ====================

  Widget _buildCardListView(
      BuildContext context, WorkspaceController controller, List<DownloadTaskModel> tasks, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(context, controller, task, isDark);
      },
    );
  }

  Widget _buildTaskCard(
      BuildContext context, WorkspaceController controller, DownloadTaskModel task, bool isDark) {
    final isSelected = controller.activeTask.value?.id == task.id;
    final isCompleted = task.status == DownloadStatus.completed;
    final isDownloading = task.status == DownloadStatus.downloading;
    final isPaused = task.status == DownloadStatus.paused;

    Color statusColor = AppColors.primary;
    if (isCompleted) {
      statusColor = AppColors.success;
    } else if (isPaused) {
      statusColor = const Color(0xFFF59E0B);
    }

    return InkWell(
      onTap: () => controller.selectTask(task),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? const Color(0xFF1E293B) : const Color(0xFF131B2A))
              : (isSelected ? Colors.white : const Color(0xFFFFFFFF)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            // 16:9 视频微缩预览
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                width: 100,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (task.thumbnail != null && task.thumbnail!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: task.thumbnail!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildPlaceholderThumb(isDark),
                      )
                    else
                      _buildPlaceholderThumb(isDark),

                    // 平台徽章
                    if (task.platform != null)
                      Positioned(
                        top: 3,
                        left: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            task.platform!.toUpperCase(),
                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // 任务详情与进度条
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 规格标签 (如 1080P MP4)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${task.quality ?? "HD"} · ${(task.format ?? "MP4").toUpperCase()}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                    child: LinearProgressIndicator(
                      value: isCompleted ? 1.0 : task.progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // 进度数值、下载速度与状态
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCompleted
                            ? '已完成 · ${task.formattedTotalBytes}'
                            : isDownloading
                                ? '${task.progressText} · ${task.formattedDownloadedBytes} / ${task.formattedTotalBytes}'
                                : isPaused
                                    ? '已暂停 · ${task.progressText}'
                                    : '等待中...',
                        style: AppTextStyles.dataSmall.copyWith(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      if (isDownloading)
                        Text(
                          '${controller.globalSpeedMBs.toStringAsFixed(1)} MB/s',
                          style: AppTextStyles.dataSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // 行内快捷动作按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCompleted)
                  IconButton(
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                    onPressed: () => controller.togglePauseResume(task),
                    visualDensity: VisualDensity.compact,
                  )
                else ...[
                  IconButton(
                    tooltip: '播放/打开文件',
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: AppColors.primary),
                    onPressed: () => controller.openTaskFile(task),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: '在文件夹中定位',
                    icon: Icon(
                      Icons.folder_open_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    onPressed: () => controller.openTaskFolder(task),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                IconButton(
                  tooltip: '删除任务',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  onPressed: () => controller.deleteTask(task.id),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 紧凑表格视图 (Motrix 风格) ====================

  Widget _buildTableView(
      BuildContext context, WorkspaceController controller, List<DownloadTaskModel> tasks, bool isDark) {
    return Column(
      children: [
        // 表头
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
          child: Row(
            children: [
              const SizedBox(width: 32, child: Text('状态', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              const Expanded(flex: 4, child: Text('任务名称', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              const Expanded(flex: 2, child: Text('大小', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              const Expanded(flex: 3, child: Text('进度 / 速度', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              const SizedBox(width: 90, child: Text('操作', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isSelected = controller.activeTask.value?.id == task.id;
              final isCompleted = task.status == DownloadStatus.completed;

              return InkWell(
                onTap: () => controller.selectTask(task),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                        : (index % 2 == 0
                            ? Colors.transparent
                            : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02))),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 状态图标
                      SizedBox(
                        width: 32,
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : task.status == DownloadStatus.paused
                                  ? Icons.pause_circle_rounded
                                  : Icons.arrow_downward_rounded,
                          size: 16,
                          color: isCompleted
                              ? AppColors.success
                              : task.status == DownloadStatus.paused
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 名称
                      Expanded(
                        flex: 4,
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),

                      // 大小
                      Expanded(
                        flex: 2,
                        child: Text(
                          Utils.formatFileSize(task.totalBytes),
                          style: AppTextStyles.dataSmall.copyWith(fontSize: 11),
                        ),
                      ),

                      // 进度与速度
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                                child: LinearProgressIndicator(
                                  value: isCompleted ? 1.0 : task.progress.clamp(0.0, 1.0),
                                  minHeight: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: Text(
                                isCompleted
                                    ? '100%'
                                    : '${controller.globalSpeedMBs.toStringAsFixed(1)}M/s',
                                style: AppTextStyles.dataSmall.copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 操作
                      SizedBox(
                        width: 90,
                        child: Row(
                          children: [
                            if (isCompleted)
                              InkWell(
                                onTap: () => controller.openTaskFile(task),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.primary),
                                ),
                              )
                            else
                              InkWell(
                                onTap: () => controller.togglePauseResume(task),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    task.status == DownloadStatus.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                    size: 16,
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: () => controller.openTaskFolder(task),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.folder_open_rounded, size: 16),
                              ),
                            ),
                            InkWell(
                              onTap: () => controller.deleteTask(task.id),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline_rounded, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== 空状态占位 ====================

  Widget _buildEmptyState(
      BuildContext context, WorkspaceController controller, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_download_outlined,
              size: 32,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '当前分类暂无下载任务',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '在顶部工具栏粘贴任意视频链接，按回车立即极速解析',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: controller.pasteFromClipboard,
            icon: const Icon(Icons.content_paste_rounded, size: 15),
            label: const Text('从剪贴板粘贴链接', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderThumb(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 24,
          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // ==================== 热门发现流 ====================

  Widget _buildTrendingWorkspace(BuildContext context, bool isDark) {
    final homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('热门发现与推荐', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: homeController.refreshTrendingVideos,
          ),
        ],
      ),
      body: Obx(() {
        final list = homeController.trendingVideos;
        if (list.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.25,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final video = list[index];
            return InkWell(
              onTap: () => homeController.openVideoDetail(video),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
                        child: CachedNetworkImage(
                          imageUrl: video.thumbnail ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorWidget: (_, __, ___) => _buildPlaceholderThumb(isDark),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            video.author ?? '知名创作者',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
