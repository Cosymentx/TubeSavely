import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../data/models/download_task_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/utils.dart';
import '../../controllers/workspace_controller.dart';

/// 桌面工作台右侧任务检视器面板 (Downie + Motrix 风格)
/// 提供 16:9 媒体预览、元数据深度解析、实时速度曲线、以及【发送至转换/压缩】无缝工作流协同
class WorkspaceInspector extends StatelessWidget {
  const WorkspaceInspector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkspaceController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final task = controller.activeTask.value;

      return Container(
        width: 330,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B0F19) : Colors.white,
          border: Border(
            left: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // 检视器头部栏
            _buildInspectorHeader(context, controller, task, isDark),

            // 检视器主体内容
            Expanded(
              child: task == null
                  ? _buildEmptyInspector(context, isDark)
                  : _buildTaskDetailBody(context, controller, task, isDark),
            ),
          ],
        ),
      );
    });
  }

  // ==================== 顶部标题与状态 ====================

  Widget _buildInspectorHeader(BuildContext context, WorkspaceController controller,
      DownloadTaskModel? task, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          const Text(
            '任务检视器',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (task != null) _buildStatusPill(task, isDark),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '收起检视器',
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: controller.toggleInspector,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(DownloadTaskModel task, bool isDark) {
    Color bg = AppColors.primary.withValues(alpha: 0.15);
    Color fg = AppColors.primary;
    String label = '下载中';

    if (task.status == DownloadStatus.completed) {
      bg = AppColors.success.withValues(alpha: 0.15);
      fg = AppColors.success;
      label = '已完成';
    } else if (task.status == DownloadStatus.paused) {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      fg = const Color(0xFFF59E0B);
      label = '已暂停';
    } else if (task.status == DownloadStatus.failed) {
      bg = AppColors.error.withValues(alpha: 0.15);
      fg = AppColors.error;
      label = '失败';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // ==================== 检视详情主体 ====================

  Widget _buildTaskDetailBody(BuildContext context, WorkspaceController controller,
      DownloadTaskModel task, bool isDark) {
    final isCompleted = task.status == DownloadStatus.completed;
    final isDownloading = task.status == DownloadStatus.downloading;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 1. 16:9 媒体预览 / 封面与播放启动
        _buildMediaPreview(context, controller, task, isDark),
        const SizedBox(height: AppSpacing.md),

        // 2. 视频标题与原链接
        SelectableText(
          task.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        if (task.url.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  task.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: task.url));
                  Utils.showSnackbar('已复制', '源视频链接已复制到剪贴板');
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
                ),
              ),
            ],
          ),

        const SizedBox(height: AppSpacing.lg),

        // 3. 实时进度与速率指示 (如果处于下载中)
        if (isDownloading) ...[
          _buildLiveMetricsCard(context, controller, task, isDark),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 4. 深度媒体元数据参数卡片
        _buildMetadataSection(context, controller, task, isDark),
        const SizedBox(height: AppSpacing.lg),

        // 5. 跨工具链即时协同动作 (Workflow Handoff)
        _buildWorkflowHandoff(context, controller, task, isDark, isCompleted),
      ],
    );
  }

  Widget _buildMediaPreview(BuildContext context, WorkspaceController controller,
      DownloadTaskModel task, bool isDark) {
    final isCompleted = task.status == DownloadStatus.completed;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
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

            // 渐变蒙层
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),

            // 播放或定位居中动作
            if (isCompleted)
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.openTaskFile(task),
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

            // 底部媒体规格浮动徽章
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${task.platform?.toUpperCase() ?? "WEB"} · ${task.quality ?? "HD"}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      Utils.formatFileSize(task.totalBytes),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetricsCard(BuildContext context, WorkspaceController controller,
      DownloadTaskModel task, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '实时传输速率',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                '${controller.globalSpeedMBs.toStringAsFixed(1)} MB/s',
                style: AppTextStyles.dataLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            child: LinearProgressIndicator(
              value: task.progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已下载: ${task.formattedDownloadedBytes}',
                style: AppTextStyles.dataSmall.copyWith(
                  fontSize: 10.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                '总计: ${task.formattedTotalBytes} (${task.progressText})',
                style: AppTextStyles.dataSmall.copyWith(
                  fontSize: 10.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context, WorkspaceController controller,
      DownloadTaskModel task, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.data_object_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                const Text(
                  '媒体元数据',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          _buildMetaRow('封装格式', (task.format ?? 'MP4').toUpperCase(), isDark),
          _buildMetaRow('目标规格', task.quality ?? '1080P Full HD', isDark),
          _buildMetaRow('文件总大小', Utils.formatFileSize(task.totalBytes), isDark),
          _buildMetaRow('解析平台', task.platform ?? 'Universal', isDark),
          if (task.savePath != null && task.savePath!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '本地路径',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: task.savePath!));
                          Utils.showSnackbar('已复制', '本地存储路径已复制');
                        },
                        child: const Text(
                          '复制路径',
                          style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.savePath!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 即时协同流 (Handoff) ====================

  Widget _buildWorkflowHandoff(BuildContext context, WorkspaceController controller,
      DownloadTaskModel task, bool isDark, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '工作流即时协同',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 1. 打开文件 (仅已完成可用)
        if (isCompleted) ...[
          ElevatedButton.icon(
            onPressed: () => controller.openTaskFile(task),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('播放 / 打开本地文件', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: () => controller.openTaskFolder(task),
            icon: const Icon(Icons.folder_open_rounded, size: 16),
            label: const Text('在系统文件夹中定位', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 2. 协同至转换 / 压缩
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.sendToConvert(task),
                icon: const Icon(Icons.transform_rounded, size: 14, color: Color(0xFF3B82F6)),
                label: const Text('转到格式转换', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.sendToCompress(task),
                icon: const Icon(Icons.compress_rounded, size: 14, color: AppColors.success),
                label: const Text('转到智能压缩', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyInspector(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 36,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '选择左侧任意任务',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '可检视视频规格、查看下载速率曲线或直达转换/压缩工作流',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumb(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 28,
          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
