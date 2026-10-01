# TubeSavely UI 组件库架构

## 📦 组件库结构

```
lib/app/widgets/
├── custom_button.dart          # 按钮组件（4种变体）
├── custom_card.dart            # 卡片容器
├── custom_text_field.dart      # 输入框
├── custom_appbar.dart          # 应用栏
├── status_badge.dart           # 状态徽章
├── empty_state.dart            # 空状态
├── loading_widget.dart         # 加载组件
├── progress_indicator.dart     # 进度指示器
├── bottom_sheet.dart           # 底部工作表
├── dialog_widgets.dart         # 对话框集合
├── adaptive_layout.dart        # 自适应布局
├── divider_widget.dart         # 分割线
└── animation_wrapper.dart      # 动画包装器

lib/app/theme/
├── app_colors.dart             # 颜色系统（已存在，需更新）
├── app_spacing.dart            # 间距系统（新建）
├── app_animations.dart         # 动画系统（新建）
├── app_text_styles.dart        # 文本样式（需优化）
├── app_theme.dart              # 主题数据（需优化）
└── theme_service.dart          # 主题服务（已存在）
```

---

## 🎨 通用组件规范

### 1. CustomButton 组件

**类型：** 4种变体
```dart
enum ButtonVariant { 
  primary,    // 主按钮 - 蓝色背景+白字
  secondary,  // 次按钮 - 浅灰背景+蓝字
  ghost,      // 幽灵按钮 - 透明+蓝边框+蓝字
  danger      // 危险按钮 - 红背景+白字
}

enum ButtonSize {
  small,      // 32pt 高
  medium,     // 40pt 高
  large       // 48pt 高
}
```

**使用示例：**
```dart
CustomButton(
  label: '下载',
  onPressed: () => controller.download(),
  variant: ButtonVariant.primary,
  size: ButtonSize.large,
  icon: Icons.download,
  isLoading: controller.isLoading.value,
)
```

**特性：**
- ✅ 自动响应式宽度或固定宽度
- ✅ 加载状态显示进度圈
- ✅ 点击动画（缩放95%）
- ✅ 禁用状态处理
- ✅ 图标+文本组合

---

### 2. CustomCard 组件

**用途：** 通用卡片容器

**特性：**
```dart
CustomCard(
  child: Column(...),
  padding: EdgeInsets.all(16.w),
  elevation: 1,
  borderRadius: BorderRadius.circular(12.r),
  onTap: () {},
)
```

**属性：**
- 自动亮/暗模式适配
- 统一边框样式
- 可选点击效果
- 内边距默认lg(16pt)

---

### 3. CustomTextField 组件

**特性：**
```dart
CustomTextField(
  label: '视频链接',
  hint: '输入视频地址...',
  controller: urlController,
  prefixIcon: Icons.link,
  suffixIcon: Icons.paste,
  onSuffixIconPressed: () => pasteFromClipboard(),
  validator: (value) => validateUrl(value),
)
```

**设计：**
- 聚焦时边框变粗（1px → 2pt）
- 聚焦时显示阴影
- 聚焦时边框变主色
- 前缀/后缀图标自动着色
- 标签上方浮动显示

---

### 4. StatusBadge 组件

**用途：** 状态标签（下载中/已完成/失败等）

```dart
StatusBadge(
  status: DownloadStatus.downloading,
  label: '下载中',
)
```

**样式：**
- 背景 = 状态色 + 10%不透明度
- 边框 = 状态色 1px
- 文字 = 状态色 FontWeight.w600
- 内边距：6pt × 2pt
- 圆角：4pt

---

### 5. EmptyState 组件

**用途：** 列表为空时的占位符

```dart
EmptyState(
  icon: Icons.download_done,
  title: '暂无下载任务',
  subtitle: '解析视频后将显示下载任务',
  action: 'Go to Home',
  onAction: () => Get.toNamed('/home'),
)
```

---

### 6. LoadingWidget 组件

**类型：** 3种加载状态

```dart
// 1. 圆形进度
LoadingWidget.circular(size: 40.w)

// 2. 线性进度
LoadingWidget.linear(progress: 0.75)

// 3. 全屏加载
LoadingWidget.fullScreen(message: '加载中...')
```

---

### 7. ProgressIndicator 组件

**用途：** 下载进度显示

```dart
ProgressIndicator(
  progress: 0.65,
  label: '65%',
  showLabel: true,
  color: AppTheme.primaryColor,
)
```

---

## 🔄 页面架构流程

### 导航流程图

```
Splash (启动)
  ↓
Main (选项卡导航)
  ├─ Home (主页)
  │  ├─ → Video Detail (视频详情)
  │  ├─ → Payment (支付/会员)
  │  └─ → Convert (格式转换)
  │
  ├─ Tasks (任务管理)
  │  └─ → Task Detail (任务详情)
  │
  ├─ Settings (设置)
  │  ├─ → Language Selection
  │  ├─ → Quality Settings
  │  └─ → Cache Clearing
  │
  ├─ Profile (个人资料)
  │  └─ → Login (如未登录)
  │
  └─ More (更多)
     ├─ → Feedback (反馈)
     ├─ → About (关于)
     └─ → Privacy (隐私)
```

---

## 🎯 各页面组件组成

### 1. Home 页面组件

```
HomeView
├── AppBar (自定义)
│  ├── Logo (渐变文字)
│  ├── History Button
│  ├── Tasks Button
│  └── Settings Button
│
├── ScrollView
│  ├── URL Input Section
│  │  └── CustomTextField + CustomButton
│  │
│  ├── Quick Actions Grid
│  │  ├── CustomCard × 2
│  │  └── 渐变背景
│  │
│  ├── Trending Videos
│  │  ├── Horizontal ListView
│  │  └── Video Card × N
│  │
│  ├── Download Options (条件)
│  │  ├── Video Info Card
│  │  ├── Quality Selector
│  │  ├── Format Selector
│  │  └── CustomButton (下载)
│  │
│  ├── Supported Platforms
│  │  └── GridView 4列
│  │
│  └── Video Tools
│     ├── CustomCard
│     └── Tool Card × 2
```

### 2. Tasks 页面组件

```
TasksView
├── AppBar (固定)
│  ├── 标题
│  └── Edit Button
│
├── Stats Row (固定)
│  ├── CustomCard × 3
│  │  ├── Icon + Number
│  │  └── Label
│  └── 间距 8pt
│
└── ListView (可滚动)
   ├── TaskItem × N
   │  ├── ClipRRect (缩略图)
   │  ├── Info Column
   │  │  ├── Title
   │  │  ├── StatusBadge
   │  │  └── Meta
   │  ├── Action Button
   │  └── LinearProgressIndicator (条件)
   └── 卡片边距 12pt
```

### 3. Settings 页面组件

```
SettingsView
├── AppBar (固定)
│
└── ScrollView
   ├── Section × N
   │  ├── Section Title (渐变)
   │  └── Setting Item × M
   │     ├── Leading Icon
   │     ├── Title + Subtitle
   │     └── Trailing Widget
   │           ├── Switch
   │           ├── Icon
   │           └── Text
   └── 分区间距 24pt
```

### 4. Video Detail 页面组件

```
VideoDetailView
├── AppBar
│  ├── 标题
│  ├── Share Button
│  └── Favorite Button
│
└── ScrollView
   ├── Video Preview/Player
   │  ├── AspectRatio 16:9
   │  ├── Video Widget 或 Image
   │  ├── Play Button Overlay
   │  └── Controls (条件)
   │
   ├── Video Info
   │  ├── Title
   │  ├── Meta Row (平台/时长/作者)
   │  └── Divider
   │
   ├── Download Options
   │  ├── Quality Selector
   │  └── Format Selector
   │
   └── Action Buttons
      ├── Download Button (全宽)
      └── Convert Button (全宽)
```

---

## 🎬 动画规范

### 页面进出动画

```dart
// Home → Video Detail
Transition: Fade + Scale
Duration: 300ms
Curve: easeInOut

// Task 列表项动画
SlideTransition: 从左进入
Duration: 200ms
Curve: easeOut
```

### 按钮交互动画

```dart
// 按下时
ScaleTransition: 1.0 → 0.95
Duration: 100ms
Curve: easeInOut

// 释放时
反向动画
```

### 加载状态动画

```dart
// 下载进度圈
RotationTransition: 0° → 360°
Duration: 1200ms
Curve: linear
Repeat: infinite
```

---

## 🌓 主题适配规则

### 亮色模式（Light Theme）

```
背景色：#F8FAFC (浅灰)
卡片色：#FFFFFF (白色)
文字色：#1E293B (深灰)
次文字：#64748B (中灰)
边框色：#E2E8F0 (浅边框)
```

### 暗色模式（Dark Theme）

```
背景色：#0F172A (深黑)
卡片色：#1E293B (深灰)
文字色：#F8FAFC (亮灰)
次文字：#94A3B8 (灰)
边框色：#334155 (深边框)
```

---

## 📊 响应式布局规则

### 屏幕分类

```
Mobile:  < 600pt
Tablet: 600-1200pt
Desktop: > 1200pt
```

### 布局调整

```
Mobile:
- 单列布局
- 全宽按钮
- 卡片间距 16pt

Tablet:
- 双列布局
- 75%宽度按钮
- 卡片间距 20pt

Desktop:
- 三列布局
- 50%宽度按钮
- 卡片间距 24pt
```

---

## 🚀 开发优先级

### Phase 1: 基础组件（Week 1）
- [ ] AppSpacing 系统
- [ ] AppAnimations 系统
- [ ] CustomButton
- [ ] CustomCard
- [ ] CustomTextField
- [ ] StatusBadge

### Phase 2: 页面重构（Week 2-3）
- [ ] Home 页面
- [ ] Tasks 页面
- [ ] Settings 页面
- [ ] Video Detail 页面

### Phase 3: 增强组件（Week 4）
- [ ] EmptyState
- [ ] LoadingWidget
- [ ] ProgressIndicator
- [ ] AnimationWrapper

### Phase 4: 细节打磨（Week 5）
- [ ] 主题适配完善
- [ ] 暗色模式优化
- [ ] 响应式测试
- [ ] 性能优化

---

## 📝 组件使用指南

### 禁止事项 ❌
- ❌ 直接使用ElevatedButton（应使用CustomButton）
- ❌ 硬编码颜色值（应使用AppTheme）
- ❌ 硬编码间距（应使用AppSpacing）
- ❌ 硬编码圆角（应使用AppSpacing）
- ❌ 页面内定义局部样式（应集中管理）

### 推荐做法 ✅
- ✅ 所有按钮使用CustomButton
- ✅ 所有颜色从AppTheme获取
- ✅ 所有间距使用AppSpacing
- ✅ 所有动画使用AppAnimations
- ✅ 共用逻辑提取到Controller

---

## 🔗 相关文档
- UI_DESIGN_PLAN.md - 详细设计方案
- app_theme.dart - 主题配置
- app_spacing.dart - 间距系统
- app_animations.dart - 动画系统
