import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/video_compress_model.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../controllers/compress_controller.dart';

/// 视频压缩参数设置面板（移除 ScreenUtil 强依赖）
class CompressSettingsPanel extends GetView<CompressController> {
  const CompressSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Obx(() {
        final cfg = controller.config.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '压缩配置与策略',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 1. 压缩模式
            Text(
              '压缩策略',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _buildPresetChip(CompressPreset.balanced, '★ 推荐平衡 (保真省空间)'),
                _buildPresetChip(CompressPreset.small, '极速减容 (体积减少70%+)'),
                _buildPresetChip(CompressPreset.quality, '高清微损 (画质优先)'),
                _buildPresetChip(CompressPreset.targetSize, '指定体积限制 (MB)'),
                _buildPresetChip(CompressPreset.custom, '自定义'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 目标大小输入框 (仅在 targetSize 模式下展示)
            if (cfg.preset == CompressPreset.targetSize) ...[
              Text(
                '期望体积上限',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: controller.targetSizeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        suffixText: 'MB',
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) {
                        final mb = double.tryParse(val);
                        if (mb != null) controller.setTargetSizeMB(mb);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    children: [10, 25, 50, 100].map((mb) {
                      return ActionChip(
                        label: Text('${mb}MB', style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          controller.targetSizeController.text = mb.toString();
                          controller.setTargetSizeMB(mb.toDouble());
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 2. 分辨率控制
            Text(
              '输出分辨率',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _buildResolutionChip(CompressResolution.original, '保持原画'),
                _buildResolutionChip(CompressResolution.r1080p, '1080P'),
                _buildResolutionChip(CompressResolution.r720p, '720P'),
                _buildResolutionChip(CompressResolution.r480p, '480P'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. 编码格式
            Text(
              '编码格式',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _buildCodecChip(VideoCodecType.h264, 'H.264 (兼容最佳)'),
                _buildCodecChip(VideoCodecType.h265, 'H.265 (压缩率高)'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 硬件加速开关
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('GPU 硬件加速 (VideoToolbox / NVENC / QSV)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('开启后大幅减少编码耗时，并显著降低 CPU 占用', style: TextStyle(fontSize: 11)),
              value: cfg.enableHardwareAcceleration,
              onChanged: controller.setHardwareAcceleration,
            ),
            const Divider(),

            // 保存路径
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '保存路径',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.outputDir.value,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.chooseOutputDir,
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text('更改目录', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 操作主行动按钮
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: controller.isProcessing.value
                    ? null
                    : controller.startBatchCompress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                icon: controller.isProcessing.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  controller.isProcessing.value ? '正在批量压缩中...' : '开始批量压缩',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPresetChip(CompressPreset preset, String label) {
    final isSelected = controller.config.value.preset == preset;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primaryContainer,
      onSelected: (_) => controller.setPreset(preset),
    );
  }

  Widget _buildResolutionChip(CompressResolution res, String label) {
    final isSelected = controller.config.value.resolution == res;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primaryContainer,
      onSelected: (_) => controller.setResolution(res),
    );
  }

  Widget _buildCodecChip(VideoCodecType codec, String label) {
    final isSelected = controller.config.value.codec == codec;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primaryContainer,
      onSelected: (_) => controller.setCodec(codec),
    );
  }
}
