# 平台检测器模式 - 快速参考指南

## 简介

平台检测器模式是TubeSavely采用的iOS优先双平台架构实现方式。通过在运行时检测平台，自动选择最合适的UI实现。

## 快速开始

### 模式概览

```
用户交互
    ↓
xxx_view.dart (平台检测器)
    ↓
    ├─ iOS? → xxx_view_ios.dart (Cupertino) ✅
    └─ 其他? → _buildMaterialXxx() (Material)
    ↓
对应平台的UI
```

### 实现三步走

#### 步骤1: 改造主视图为检测器

**文件**: `lib/app/modules/xxx/views/xxx_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/platform_util.dart';
import '../controllers/xxx_controller.dart';
import 'xxx_view_ios.dart';

/// Xxx视图 - 平台检测器
/// 根据平台选择iOS或Android实现
class XxxView extends GetView<XxxController> {
  const XxxView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 平台检测：iOS使用Cupertino风格，Android使用Material风格
    if (PlatformUtil.isIOS) {
      return XxxViewIOS();
    } else {
      // Android/其他平台使用Material风格
      return _buildMaterialXxx();
    }
  }

  /// 构建Material设计的Xxx视图（Android）
  Widget _buildMaterialXxx() {
    // 原有的Material实现代码
    return Scaffold(
      // ... 原始Material设计
    );
  }
}
```

#### 步骤2: 创建iOS专用视图文件

**文件**: `lib/app/modules/xxx/views/xxx_view_ios.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/xxx_controller.dart';

/// Xxx页面 - iOS Cupertino风格实现
class XxxViewIOS extends GetView<XxxController> {
  const XxxViewIOS({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('标题'),
      ),
      child: CupertinoScrollbar(
        child: ListView(
          children: [
            // iOS风格的UI组件
          ],
        ),
      ),
    );
  }
}
```

#### 步骤3: 验证编译

```bash
# 构建并运行（自动选择当前平台）
flutter run

# 在特定平台运行
flutter run -d <device_id>
```

## 常用模式

### 模式1: 简单页面（推荐）

适用于逻辑简单的页面。

```dart
// xxx_view.dart
class XxxView extends GetView<XxxController> {
  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return XxxViewIOS();
    } else {
      return _buildMaterialXxx();
    }
  }

  Widget _buildMaterialXxx() => Scaffold(...);
}

// xxx_view_ios.dart
class XxxViewIOS extends GetView<XxxController> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(...);
  }
}
```

### 模式2: 共享组件（推荐）

对于可以在两个平台间共享的小组件。

```dart
// xxx_view.dart
class XxxView extends GetView<XxxController> {
  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return XxxViewIOS();
    } else {
      return _buildMaterialXxx();
    }
  }

  // 共享的UI组件
  Widget _buildCommonContent() {
    return Column(
      children: [
        // 可以在两个平台使用的组件
      ],
    );
  }

  Widget _buildMaterialXxx() {
    return Scaffold(
      body: _buildCommonContent(),
    );
  }
}

// xxx_view_ios.dart
class XxxViewIOS extends GetView<XxxController> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // 复用parent中的共享方法
    );
  }
}
```

### 模式3: 复杂页面（标准）

对于有多个复杂部分的页面。

```dart
// 文件结构
lib/app/modules/xxx/views/
├── xxx_view.dart            # 平台检测器
├── xxx_view_ios.dart        # iOS实现
├── xxx_view_android.dart    # Android实现（可选）
└── xxx_view_common.dart     # 共享逻辑

// xxx_view.dart
class XxxView extends GetView<XxxController> {
  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return XxxViewIOS();
    } else {
      return XxxViewAndroid();
    }
  }
}

// xxx_view_common.dart - 共享逻辑
class XxxViewCommon {
  static Widget buildHeader(String title) => ...;
  static Widget buildContent(dynamic data) => ...;
}
```

## 关键API 参考

### PlatformUtil - 平台检测

```dart
import '../../../utils/platform_util.dart';

// 平台检测
PlatformUtil.isIOS        // bool - 是否iOS
PlatformUtil.isAndroid    // bool - 是否Android
PlatformUtil.isWeb        // bool - 是否Web
PlatformUtil.isMacOS      // bool - 是否macOS
PlatformUtil.isWindows    // bool - 是否Windows
PlatformUtil.isLinux      // bool - 是否Linux

// 设备信息
PlatformUtil.deviceType   // iOS/Android/Web等
PlatformUtil.deviceName   // 设备名称
PlatformUtil.osVersion    // OS版本

// 主题信息
PlatformUtil.isDarkMode   // 是否深色模式
PlatformUtil.brightness   // 亮度值

// 安全区
PlatformUtil.safeAreaTop      // 顶部安全区
PlatformUtil.safeAreaBottom   // 底部安全区
```

### Cupertino 组件速查

| Material | Cupertino | 用途 |
|----------|-----------|------|
| Scaffold | CupertinoPageScaffold | 页面容器 |
| AppBar | CupertinoNavigationBar | 顶部导航 |
| Switch | CupertinoSwitch | 开关控件 |
| FlatButton | CupertinoButton | 按钮 |
| AlertDialog | CupertinoAlertDialog | 对话框 |
| BottomSheet | CupertinoActionSheet | 底部动作表 |
| ProgressIndicator | CupertinoActivityIndicator | 加载指示 |
| TextField | CupertinoTextField | 文本输入 |
| ListView | CupertinoScrollbar + ListView | 列表 |
| ListTile | CupertinoListTile | 列表项 |

### 图标映射

```dart
// Material → Cupertino
Icons.home              // CupertinoIcons.home
Icons.settings          // CupertinoIcons.settings
Icons.favorite          // CupertinoIcons.heart_fill
Icons.add               // CupertinoIcons.plus
Icons.delete            // CupertinoIcons.trash
Icons.more_vert         // CupertinoIcons.ellipsis_vertical
Icons.arrow_back        // CupertinoIcons.back
Icons.search            // CupertinoIcons.search
Icons.person            // CupertinoIcons.person_solid
Icons.download          // CupertinoIcons.arrow_down
```

## 最佳实践

### ✅ 推荐做法

1. **使用 GetView 模式**
   ```dart
   class XxxView extends GetView<XxxController> {
     // 自动获取controller，无需传参
   }
   ```

2. **统一命名规范**
   - 检测器: `xxx_view.dart`
   - iOS版本: `xxx_view_ios.dart`
   - Android版本: `xxx_view_android.dart`（如果需要）

3. **提取共享代码**
   ```dart
   // 共享的UI逻辑
   Widget _buildCommonHeader() => ...;
   ```

4. **充分利用 Obx 响应式**
   ```dart
   Obx(() => Text(controller.title.value));
   ```

5. **使用毛玻璃卡片**
   ```dart
   GlassmorphismCard(
     child: Container(...)
   )
   ```

### ❌ 避免做法

1. **不要在运行时创建controller**
   ```dart
   // ❌ 错误
   final controller = XxxController();
   
   // ✅ 正确
   // 使用 GetView<XxxController>
   ```

2. **不要硬编码平台判断**
   ```dart
   // ❌ 错误
   if (Platform.isIOS) { ... }
   
   // ✅ 正确
   if (PlatformUtil.isIOS) { ... }
   ```

3. **不要复制整个UI到另一个文件**
   ```dart
   // ❌ 错误 - 代码重复太多
   // ✅ 正确 - 提取共享方法
   ```

4. **不要混合Cupertino和Material**
   ```dart
   // ❌ 错误
   CupertinoPageScaffold(
     child: Material(...)
   )
   
   // ✅ 正确 - 保持风格一致
   ```

## 常见问题

### Q: 如何测试两个平台的UI？

```bash
# iOS模拟器
flutter run -d <ios_device>

# Android模拟器  
flutter run -d <android_device>

# 或使用快速切换
flutter run -d emulator-5554  # Android
flutter run -d iPhone         # iOS
```

### Q: 如何在Android上调试iOS代码？

使用条件编译来跳过平台检测：

```dart
// 在main.dart中
void main() {
  // 强制使用iOS UI进行调试（仅开发用）
  // debugForceIOSUI = true;
  runApp(MyApp());
}
```

### Q: 如何添加平台特定的初始化？

```dart
@override
void onInit() {
  super.onInit();
  
  if (PlatformUtil.isIOS) {
    _initializeForIOS();
  } else {
    _initializeForAndroid();
  }
}
```

### Q: 共享方法如何访问controller？

```dart
// 在XxxView中
Widget _buildCommon() {
  return GestureDetector(
    onTap: () => controller.doSomething(), // 直接访问
    child: Text('Tap me'),
  );
}
```

## 文件模板

### 完整的平台检测器模板

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../utils/platform_util.dart';
import '../../../theme/app_colors.dart';
import '../controllers/xxx_controller.dart';
import 'xxx_view_ios.dart';

/// Xxx视图 - 平台检测器
/// 根据平台选择iOS或Android实现
class XxxView extends GetView<XxxController> {
  const XxxView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 平台检测：iOS使用Cupertino风格，Android使用Material风格
    if (PlatformUtil.isIOS) {
      return XxxViewIOS();
    } else {
      // Android/其他平台使用Material风格
      return _buildMaterialXxx();
    }
  }

  /// 构建Material设计的Xxx视图（Android）
  Widget _buildMaterialXxx() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标题'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Material风格的内容
            ],
          ),
        ),
      ),
    );
  }
}
```

## 相关文档

- [PLATFORM_DETECTOR_IMPLEMENTATION.md](./PLATFORM_DETECTOR_IMPLEMENTATION.md) - 实现总结
- [DESIGN_GUIDELINES.md](./DESIGN_GUIDELINES.md) - iOS 18设计指南
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 完整架构文档

---

**最后更新**: 2024年
**维护者**: TubeSavely Team
**版本**: 1.0