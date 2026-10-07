import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ScreenType;
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'responsive_layout.dart';

/// 自适应导航项配置
class AdaptiveNavigationDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? badge;
  final String? tooltip;

  const AdaptiveNavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badge,
    this.tooltip,
  });
}

/// 全新双端自适应导航外壳 (Dual-End Adaptive Navigation Shell)
/// 遵循 UI/UX Pro Max 规范：
/// - 紧凑型屏 (< 600px)：优雅沉浸式底部导航栏 (Bottom Navigation Bar)
/// - 宽屏/桌面端 (>= 600px)：左侧现代导航边栏 (Navigation Sidebar / Rail) + 顶部融合窗体栏
class AdaptiveShell extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveNavigationDestination> destinations;
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? headerLeading;
  final bool showThemeToggle;

  const AdaptiveShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.headerLeading,
    this.showThemeToggle = true,
  });

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType) {
        if (screenType == AppScreenType.compact) {
          return _buildMobileLayout(context);
        } else {
          return _buildDesktopLayout(context, screenType);
        }
      },
    );
  }

  // ==================== 移动端紧凑布局 (Mobile Shell) ====================
  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: widget.title != null || widget.actions != null
          ? AppBar(
              title: widget.title != null
                  ? Text(
                      widget.title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              leading: widget.headerLeading,
              actions: [
                if (widget.showThemeToggle) _buildThemeToggleButton(context),
                if (widget.actions != null) ...widget.actions!,
              ],
            )
          : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: widget.currentIndex,
          onDestinationSelected: widget.onDestinationSelected,
          destinations: widget.destinations.map((dest) {
            Widget icon = dest.icon;
            Widget selectedIcon = dest.selectedIcon ?? dest.icon;

            if (dest.badge != null) {
              icon = Badge(label: Text(dest.badge!), child: icon);
              selectedIcon =
                  Badge(label: Text(dest.badge!), child: selectedIcon);
            }

            return NavigationDestination(
              icon: icon,
              selectedIcon: selectedIcon,
              label: dest.label,
              tooltip: dest.tooltip,
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== 桌面与平板宽屏布局 (Desktop Shell) ====================
  Widget _buildDesktopLayout(BuildContext context, AppScreenType screenType) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 平板默认折叠，宽屏桌面默认展开
    final bool isCollapsed =
        screenType == AppScreenType.medium ? true : _isSidebarCollapsed;
    final double sidebarWidth = isCollapsed
        ? AppSpacing.desktopSidebarCollapsedWidth
        : AppSpacing.desktopSidebarWidth;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070A11) : const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // 左侧现代多态侧边栏 (Sidebar)
          AnimatedContainer(
            duration: AppSpacing.durationFast,
            curve: AppSpacing.curveDefault,
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // 顶部品牌区 (Brand Header)
                _buildSidebarHeader(context, isCollapsed),
                const Divider(height: 1),

                // 中间导航项列表 (Navigation Items)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.xs,
                    ),
                    itemCount: widget.destinations.length,
                    itemBuilder: (context, index) {
                      final dest = widget.destinations[index];
                      final isSelected = widget.currentIndex == index;
                      return _buildSidebarNavItem(
                        context: context,
                        destination: dest,
                        isSelected: isSelected,
                        isCollapsed: isCollapsed,
                        onTap: () => widget.onDestinationSelected(index),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // 底部快捷栏 (Footer: 主题切换 & 折叠控制)
                _buildSidebarFooter(context, isCollapsed, screenType),
              ],
            ),
          ),

          // 右侧主视窗区域 (Main Viewport)
          Expanded(
            child: Column(
              children: [
                // 顶部融合工具栏 (Top Window Header)
                _buildDesktopHeader(context),

                // 主体内容页面 (Page Body)
                Expanded(
                  child: ClipRect(
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 桌面端侧边栏顶部品牌标识
  Widget _buildSidebarHeader(BuildContext context, bool isCollapsed) {
    final theme = Theme.of(context);
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    return Container(
      height: AppSpacing.desktopHeaderHeight + (isMac ? 10 : 0),
      padding: EdgeInsets.only(
        top: isMac ? 12 : 0,
        left: isCollapsed ? 0 : AppSpacing.md,
        right: isCollapsed ? 0 : AppSpacing.sm,
      ),
      alignment: Alignment.center,
      child: isCollapsed
          ? _buildBrandLogo()
          : Row(
              children: [
                _buildBrandLogo(),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TubeSavely',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Media Suite',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // 品牌红色渐变小图标
  Widget _buildBrandLogo() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: const Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // 侧边栏单个导航按钮项
  Widget _buildSidebarNavItem({
    required BuildContext context,
    required AdaptiveNavigationDestination destination,
    required bool isSelected,
    required bool isCollapsed,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget iconWidget = isSelected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;

    if (destination.badge != null) {
      iconWidget = Badge(
        label: Text(destination.badge!),
        child: iconWidget,
      );
    }

    final content = AnimatedContainer(
      duration: AppSpacing.durationFast,
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 0 : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          IconTheme(
            data: IconThemeData(
              color: isSelected ? colorScheme.primary : AppColors.textSecondary,
              size: 20,
            ),
            child: iconWidget,
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                destination.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: isCollapsed ? destination.label : '',
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }

  // 侧边栏底部工具栏
  Widget _buildSidebarFooter(
    BuildContext context,
    bool isCollapsed,
    AppScreenType screenType,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          if (widget.showThemeToggle) _buildThemeToggleButton(context),
          if (!isCollapsed && screenType == AppScreenType.expanded)
            IconButton(
              icon: Icon(
                _isSidebarCollapsed
                    ? Icons.keyboard_double_arrow_right_rounded
                    : Icons.keyboard_double_arrow_left_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              tooltip: _isSidebarCollapsed ? '展开边栏' : '折叠边栏',
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
        ],
      ),
    );
  }

  // 桌面端顶部工具栏 (macOS 避让红绿灯)
  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    return Container(
      height: AppSpacing.desktopHeaderHeight,
      padding: EdgeInsets.only(
        left: isMac ? AppSpacing.xl : AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.title != null)
            Text(
              widget.title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          const Spacer(),
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
    );
  }

  // 昼夜深浅色一键切换按钮
  Widget _buildThemeToggleButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        size: 20,
      ),
      tooltip: isDark ? '切换浅色模式' : '切换暗黑模式',
      onPressed: () {
        if (Get.isRegistered<ThemeService>()) {
          Get.find<ThemeService>().switchTheme();
        } else {
          Get.changeThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
        }
      },
    );
  }
}
