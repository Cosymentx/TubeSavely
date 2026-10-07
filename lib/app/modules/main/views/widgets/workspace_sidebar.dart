import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../controllers/workspace_controller.dart';

/// 桌面工作台左侧分类导航栏 (Downie + Motrix 风格)
class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkspaceController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),

          // 主分类导航区域
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              children: [
                // 1. 传输与队列
                _buildSectionHeader('传输任务', isDark),
                const SizedBox(height: 4),
                Obx(() => _buildNavItem(
                      label: '全部任务',
                      icon: Icons.layers_rounded,
                      section: WorkspaceSection.all,
                      count: controller.totalCount,
                      isSelected: controller.currentSection.value == WorkspaceSection.all,
                      onTap: () => controller.setSection(WorkspaceSection.all),
                      isDark: isDark,
                    )),
                const SizedBox(height: 2),
                Obx(() => _buildNavItem(
                      label: '正在下载',
                      icon: Icons.arrow_downward_rounded,
                      section: WorkspaceSection.downloading,
                      count: controller.downloadingCount,
                      isSelected: controller.currentSection.value == WorkspaceSection.downloading,
                      highlightCount: controller.downloadingCount > 0,
                      onTap: () => controller.setSection(WorkspaceSection.downloading),
                      isDark: isDark,
                    )),
                const SizedBox(height: 2),
                Obx(() => _buildNavItem(
                      label: '已完成',
                      icon: Icons.check_circle_outline_rounded,
                      section: WorkspaceSection.completed,
                      count: controller.completedCount,
                      isSelected: controller.currentSection.value == WorkspaceSection.completed,
                      onTap: () => controller.setSection(WorkspaceSection.completed),
                      isDark: isDark,
                    )),

                const SizedBox(height: AppSpacing.md),
                _buildDivider(isDark),

                // 2. 媒体处理工具箱
                _buildSectionHeader('媒体工具箱', isDark),
                const SizedBox(height: 4),
                Obx(() => _buildNavItem(
                      label: '格式转换',
                      icon: Icons.transform_rounded,
                      section: WorkspaceSection.convert,
                      isSelected: controller.currentSection.value == WorkspaceSection.convert,
                      onTap: () => controller.setSection(WorkspaceSection.convert),
                      isDark: isDark,
                    )),
                const SizedBox(height: 2),
                Obx(() => _buildNavItem(
                      label: '智能压缩',
                      icon: Icons.compress_rounded,
                      section: WorkspaceSection.compress,
                      isSelected: controller.currentSection.value == WorkspaceSection.compress,
                      onTap: () => controller.setSection(WorkspaceSection.compress),
                      isDark: isDark,
                    )),

                const SizedBox(height: AppSpacing.md),
                _buildDivider(isDark),

                // 3. 发现
                _buildSectionHeader('探索', isDark),
                const SizedBox(height: 4),
                Obx(() => _buildNavItem(
                      label: '热门发现',
                      icon: Icons.local_fire_department_rounded,
                      section: WorkspaceSection.trending,
                      isSelected: controller.currentSection.value == WorkspaceSection.trending,
                      onTap: () => controller.setSection(WorkspaceSection.trending),
                      isDark: isDark,
                    )),
              ],
            ),
          ),

          // 底部用户简要卡片
          _buildUserFooter(context, controller, isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required IconData icon,
    required WorkspaceSection section,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    int? count,
    bool highlightCount = false,
  }) {
    final activeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final activeFg = isDark ? Colors.white : const Color(0xFF0F172A);
    final inactiveFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: isSelected
              ? Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? AppColors.primary : inactiveFg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? activeFg : inactiveFg,
                ),
              ),
            ),
            if (count != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: highlightCount
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: highlightCount ? AppColors.primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserFooter(BuildContext context, WorkspaceController controller, bool isDark) {
    final profileController = Get.find<ProfileController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        final isLogged = profileController.isLoggedIn.value;
        final user = profileController.user.value;
        final name = user?.username ?? (isLogged ? '已登录会员' : '未登录访客');

        return InkWell(
          onTap: () => controller.setSection(WorkspaceSection.profile),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isLogged ? 'VIP 会员' : '点击登录同步',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
