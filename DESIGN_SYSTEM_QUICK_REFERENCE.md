# TubeSavely 设计系统快速参考卡

## 🎨 颜色使用

```dart
// ✅ 导入
import 'package:tubesavely/app/theme/app_colors.dart';

// 主色
AppColors.primary         // #3B82F6 (蓝色)
AppColors.accent          // #0EA5E9 (青色)

// 状态色
AppColors.success         // #22C55E (绿色)
AppColors.warning         // #F59E0B (橙色)
AppColors.error           // #EF4444 (红色)
AppColors.info            // #3B82F6 (蓝色)

// 背景和文本
AppColors.background      // 自动切换亮/暗
AppColors.surface         // 卡片背景
AppColors.textPrimary     // 主文本
AppColors.textSecondary   // 次文本
AppColors.border          // 边框色

// 透明度变体
AppColors.primaryLight5   // 5% 不透明度
AppColors.primaryLight10  // 10% 不透明度
AppColors.primaryLight25  // 25% 不透明度
```

## 📏 间距使用

```dart
// ✅ 导入
import 'package:tubesavely/app/theme/app_spacing.dart';

// 基础间距 (8pt基准)
AppSpacing.xs    // 4pt  - 微小间距
AppSpacing.sm    // 8pt  - 小间距
AppSpacing.md    // 12pt - 标准间距
AppSpacing.lg    // 16pt - 大间距
AppSpacing.xl    // 24pt - 超大间距
AppSpacing.xxl   // 32pt - 页面级间距
AppSpacing.xxxl  // 48pt - 最大间距

// 圆角规范
AppSpacing.radiusSm   // 8pt  - 小组件
AppSpacing.radiusMd   // 12pt - 卡片、按钮
AppSpacing.radiusLg   // 16pt - 大容器
AppSpacing.radiusXl   // 20pt - 模态框
AppSpacing.radiusRound // 999pt - 完全圆形

// 图标大小
AppSpacing.iconSm   // 16pt
AppSpacing.iconMd   // 24pt
AppSpacing.iconLg   // 32pt
AppSpacing.iconXl   // 48pt

// 按钮高度
AppSpacing.buttonHeightSm   // 32pt
AppSpacing.buttonHeightMd   // 40pt
AppSpacing.buttonHeightLg   // 48pt
```

## 🔤 排版使用

```dart
// ✅ 导入
import 'package:tubesavely/app/theme/app_text_styles.dart';

// 标题类
AppTextStyles.displayLarge   // 57sp, w400
AppTextStyles.displayMedium  // 45sp, w400
AppTextStyles.displaySmall   // 36sp, w400

// 大标题
AppTextStyles.headlineLarge  // 32sp, w400
AppTextStyles.headlineMedium // 28sp, w400
AppTextStyles.headlineSmall  // 24sp, w400

// 区域标题
AppTextStyles.titleLarge     // 22sp, w500
AppTextStyles.titleMedium    // 16sp, w500
AppTextStyles.titleSmall     // 14sp, w500

// 正文
AppTextStyles.bodyLarge      // 16sp, w400
AppTextStyles.bodyMedium     // 14sp, w400
AppTextStyles.bodySmall      // 12sp, w400

// 标签/按钮文本
AppTextStyles.labelLarge     // 14sp, w500
AppTextStyles.labelMedium    // 12sp, w500
AppTextStyles.labelSmall     // 11sp, w500

// 🎯 使用方法
Text(
  'Hello',
  style: AppTextStyles.titleMedium.copyWith(
    color: AppColors.textPrimary,
  ),
)
```

## 🎛️ 动画使用

```dart
// ✅ 导入
import 'package:tubesavely/app/theme/app_animations.dart';

// 动画时长
AppAnimations.durationXs   // 100ms - 微交互
AppAnimations.durationSm   // 200ms - 快速转换
AppAnimations.durationMd   // 300ms - 标准动画
AppAnimations.durationLg   // 500ms - 模态框
AppAnimations.durationXl   // 800ms - 复杂动画

// 缓动曲线
AppAnimations.curveEaseOut     // 最常用
AppAnimations.curveEaseIn      // 反向开始
AppAnimations.curveEaseInOut   // 平滑往返
AppAnimations.curveBounce      // 弹跳
AppAnimations.curveElastic     // 弹性

// 页面过渡
AppAnimations.pageTransitionDuration  // 300ms
AppAnimations.pageTransitionCurve     // easeInOut
```

## 🧩 组件使用

### CustomButton
```dart
import 'package:tubesavely/app/widgets/custom_button.dart';

CustomButton(
  label: '下载',
  onPressed: () {},
  variant: ButtonVariant.primary,     // primary/secondary/ghost/danger
  size: ButtonSize.large,              // small/medium/large
  icon: Icons.download,                // 可选
  isLoading: false,                    // 加载状态
  width: double.infinity,              // 可选
)
```

### CustomCard
```dart
import 'package:tubesavely/app/widgets/custom_card.dart';

CustomCard(
  child: Text('Content'),
  style: CardStyle.elevated,           // elevated/outlined/filled/ghost
  padding: EdgeInsets.all(16.w),       // 使用 AppSpacing
  backgroundColor: AppColors.surface,  // 可选
  onTap: () {},                        // 可选
)
```

### CustomTextField
```dart
import 'package:tubesavely/app/widgets/custom_text_field.dart';

CustomTextField(
  label: '视频链接',
  hint: '输入视频地址...',
  controller: controller,
  prefixIcon: Icons.link,              // 可选
  suffixIcon: Icons.paste,             // 可选
  validator: (value) => null,          // 可选
)
```

### StatusBadgeWidget
```dart
import 'package:tubesavely/app/widgets/status_badge_widget.dart';

StatusBadgeWidget(
  status: DownloadStatus.downloading,  // 状态枚举
  label: '下载中',
  showBackground: true,                // 是否显示背景
)
```

### EmptyStateWidget
```dart
import 'package:tubesavely/app/widgets/empty_state_widget.dart';

EmptyStateWidget(
  icon: Icons.download_done,
  title: '暂无下载任务',
  subtitle: '解析视频后将显示下载任务',
  actionLabel: '返回首页',             // 可选
  onAction: () => Get.toNamed('/home'), // 可选
)
```

### ProgressIndicatorWidget
```dart
import 'package:tubesavely/app/widgets/progress_indicator_widget.dart';

// 线性进度条
ProgressIndicatorWidget(
  progress: 0.65,
  label: '65%',
  showLabel: true,
  color: AppColors.primary,            // 可选
)

// 圆形进度条
ProgressIndicatorWidget.circular(
  progress: 0.75,
  label: '75%',
  showLabel: true,
  size: 60.0,
  strokeWidth: 3.0,
)
```

## ❌ 禁止事项

```dart
// ❌ 错误: 硬编码颜色
color: Color(0xFF3B82F6)
// ✅ 正确:
color: AppColors.primary

// ❌ 错误: 硬编码间距
padding: EdgeInsets.all(16.w)
// ✅ 正确:
padding: EdgeInsets.all(AppSpacing.lg)

// ❌ 错误: 硬编码圆角
borderRadius: BorderRadius.circular(12.r)
// ✅ 正确:
borderRadius: BorderRadius.circular(AppSpacing.radiusMd)

// ❌ 错误: 直接使用 ElevatedButton
ElevatedButton(...)
// ✅ 正确:
CustomButton(...)

// ❌ 错误: 硬编码字体大小和权重
TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)
// ✅ 正确:
AppTextStyles.bodyMedium

// ❌ 错误: 使用 withAlpha 计算透明度
color: Colors.black.withAlpha(13)
// ✅ 正确:
color: AppColors.primaryLight5
```

## 📝 页面构建清单

每个新页面需要:

- [ ] 导入所需的主题文件 (AppColors, AppSpacing, AppTextStyles)
- [ ] 使用 AppSpacing 定义所有 padding/margin
- [ ] 使用 AppColors 定义所有颜色
- [ ] 使用 AppTextStyles 定义所有文本样式
- [ ] 使用圆角常量 (AppSpacing.radiusMd 等)
- [ ] 优先使用 Custom* 组件库
- [ ] 测试亮/暗模式
- [ ] 验证响应式布局

## 🎨 颜色搭配建议

**主要操作**:
- 按钮: AppColors.primary (蓝色)
- 加载: AppColors.accent (青色)
- 禁用: AppColors.border

**状态提示**:
- 成功: AppColors.success (绿色)
- 警告: AppColors.warning (橙色)
- 错误: AppColors.error (红色)

**背景层级**:
1. 背景: AppColors.background
2. 卡片: AppColors.surface
3. 容器: AppColors.surfaceVariant

## 📐 间距规律

- **相邻元素**: AppSpacing.sm (8pt)
- **区域内间距**: AppSpacing.md (12pt) 到 AppSpacing.lg (16pt)
- **区域间距**: AppSpacing.xl (24pt)
- **页面边距**: AppSpacing.lg (16pt)
- **区域标题间距**: AppSpacing.xl (24pt)

## 🔍 常见问题

**Q: 如何自定义颜色?**
A: 在 AppColors 中添加新常量，避免硬编码

**Q: 如何创建新的按钮样式?**
A: 使用 CustomButton 的 variant 参数，无需创建新组件

**Q: 如何在主题切换时保持效果?**
A: 使用 Get.isDarkMode 判断，使用响应式颜色属性

**Q: 如何保证响应式布局?**
A: 使用 flutter_screenutil 的 .w, .h, .r 后缀

## 📚 相关文件

| 文件 | 用途 |
|------|------|
| `app_colors.dart` | 颜色定义 |
| `app_spacing.dart` | 间距、圆角、图标大小 |
| `app_text_styles.dart` | 排版系统 |
| `app_animations.dart` | 动画定义 |
| `custom_button.dart` | 按钮组件 |
| `custom_card.dart` | 卡片组件 |
| `custom_text_field.dart` | 输入框组件 |
| `status_badge_widget.dart` | 状态徽章组件 |
| `empty_state_widget.dart` | 空状态组件 |
| `progress_indicator_widget.dart` | 进度条组件 |

---

**版本**: 1.0 (2025-10-26)  
**维护者**: UI 团队
