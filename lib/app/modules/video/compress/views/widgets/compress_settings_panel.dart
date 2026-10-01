import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../../data/models/video_compress_model.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../controllers/compress_controller.dart';

class CompressSettingsPanel extends GetView<CompressController> {
  const CompressSettingsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight5,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final cfg = controller.config.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text('压缩配置', style: AppTextStyles.titleMedium),
              ],
            ),
            SizedBox(height: 16.h),

            // 1. 压缩模式
            Text('压缩策略', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildPresetChip(CompressPreset.balanced, '★ 推荐平衡 (保真省空间)'),
                _buildPresetChip(CompressPreset.small, '极速省空间 (体积减70%+)'),
                _buildPresetChip(CompressPreset.quality, '高清微损 (画质优先)'),
                _buildPresetChip(CompressPreset.targetSize, '指定体积限制 (MB)'),
                _buildPresetChip(CompressPreset.custom, '自定义'),
              ],
            ),
            SizedBox(height: 16.h),

            // 目标大小输入框 (仅在 targetSize 模式下展示)
            if (cfg.preset == CompressPreset.targetSize) ...[
              Text('期望体积上限', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  SizedBox(
                    width: 120.w,
                    child: TextField(
                      controller: controller.targetSizeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        suffixText: 'MB',
                      ),
                      onChanged: (val) {
                        final mb = double.tryParse(val);
                        if (mb != null) controller.setTargetSizeMB(mb);
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Wrap(
                    spacing: 6.w,
                    children: [10, 25, 50, 100].map((mb) {
                      return ActionChip(
                        label: Text('${mb}MB'),
                        onPressed: () {
                          controller.targetSizeController.text = mb.toString();
                          controller.setTargetSizeMB(mb.toDouble());
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],

            // 2. 分辨率控制
            Text('输出分辨率', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: [
                _buildResolutionChip(CompressResolution.original, '保持原分辨率'),
                _buildResolutionChip(CompressResolution.r1080p, '1080P'),
                _buildResolutionChip(CompressResolution.r720p, '720P'),
                _buildResolutionChip(CompressResolution.r480p, '480P'),
              ],
            ),
            SizedBox(height: 16.h),

            // 3. 编码与硬件加速
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('编码格式', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        children: [
                          _buildCodecChip(VideoCodecType.h264, 'H.264 (兼容最佳)'),
                          _buildCodecChip(VideoCodecType.h265, 'H.265 (压缩率高)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // 硬件加速开关
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('启用 GPU 硬件加速 (VideoToolbox / NVENC / QSV)'),
              subtitle: const Text('开启后大幅减少编码耗时，并显著降低 CPU 占用'),
              value: cfg.enableHardwareAcceleration,
              onChanged: controller.setHardwareAcceleration,
            ),
            const Divider(),

            // 输出目录
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('保存路径', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      SizedBox(height: 4.h),
                      Text(
                        controller.outputDir.value,
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.chooseOutputDir,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('更改目录'),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // 操作主按钮
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton.icon(
                onPressed: controller.isProcessing.value
                    ? null
                    : controller.startBatchCompress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                icon: controller.isProcessing.value
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  controller.isProcessing.value ? '正在批量压缩中...' : '开始批量压缩',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
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
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setPreset(preset),
      selectedColor: AppColors.primaryLight25,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildResolutionChip(CompressResolution res, String label) {
    final isSelected = controller.config.value.resolution == res;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setResolution(res),
      selectedColor: AppColors.primaryLight25,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCodecChip(VideoCodecType codec, String label) {
    final isSelected = controller.config.value.codec == codec;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setCodec(codec),
      selectedColor: AppColors.primaryLight25,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
