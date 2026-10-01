# 其他模块更新快速指南

## 快速更新流程

### Tasks模块 (30分钟)

**transforms/tasks_view.dart**:
```dart
// 添加在顶部
import 'package:flutter/cupertino.dart';
import '../../../utils/platform_util.dart';
import 'tasks_view_ios.dart';

// 在build()方法开头
@override
Widget build(BuildContext context) {
  if (PlatformUtil.isIOS) {
    return TasksViewIOS();
  } else {
    return _buildMaterialTasks(); // 将原build内容封装
  }
}
```

**创建tasks_view_ios.dart**:
- CupertinoPageScaffold导航栏
- 显示进度条和任务状态
- 任务列表（活跃/已完成/失败）
- 操作按钮（暂停/恢复/删除）

### Profile模块 (1小时)

**transforms/profile_view.dart**:
- 添加平台检测逻辑
- 创建_buildMaterialProfile()

**创建profile_view_ios.dart**:
- CupertinoPageScaffold
- 用户头像和基本信息卡片（毛玻璃）
- 统计数据展示
- 操作菜单

### Credit模块 (1小时)

**transforms/credit_view.dart**:
- 平台检测和Material实现提取

**创建credit_view_ios.dart**:
- CupertinoPageScaffold
- 积分余额显示
- 充值套餐列表
- 购买按钮

### More/About模块 (45分钟)

**transforms/more_view.dart**:
- 平台检测转换

**创建more_view_ios.dart**:
- CupertinoPageScaffold
- 菜单项列表
- 关于/设置/反馈等选项

### Login模块 (1小时)

**transforms/login_view.dart**:
- 平台检测转换

**创建login_view_ios.dart**:
- CupertinoPageScaffold
- CustomTextField登录表单
- CustomButton登录按钮
- 第三方登录选项

### Payment模块 (1.5小时)

**需要更新3个文件**:

1. **payment_view.dart**
   - 平台检测器
   - create payment_view_ios.dart

2. **payment_result_view.dart**
   - 平台检测器
   - create payment_result_view_ios.dart

3. **transaction_history_view.dart**
   - 平台检测器
   - create transaction_history_view_ios.dart

### Feedback模块 (30分钟)

**transforms/feedback_view.dart**:
- 平台检测转换

**创建feedback_view_ios.dart**:
- CupertinoPageScaffold
- CustomTextField反馈输入
- CustomButton提交按钮

## 统一模板代码

### 平台检测器模板

所有_view.dart文件顶部都采用以下结构：

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/platform_util.dart';
import '../controllers/xxx_controller.dart';
import 'xxx_view_ios.dart';

class XxxView extends GetView<XxxController> {
  const XxxView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtil.isIOS) {
      return XxxViewIOS();
    } else {
      return _buildMaterialXxx();
    }
  }

  Widget _buildMaterialXxx() {
    // 原Material实现...
    return Scaffold(...);
  }
}
```

### iOS版本模板

所有_view_ios.dart文件都采用以下结构：

```dart
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../controllers/xxx_controller.dart';

class XxxViewIOS extends GetView<XxxController> {
  const XxxViewIOS({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('页面标题'),
      ),
      child: CupertinoScrollbar(
        child: ListView(...),
      ),
    );
  }
  
  // 辅助方法...
}
```

## 组件使用速查

### 必用组件

```dart
// 按钮
CustomButton(
  label: '确定',
  onPressed: () {},
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
)

// 卡片
CustomCard(
  style: CardStyle.elevated,
  child: widget,
  enableGlassmorphism: true,
)

// 加载状态
Obx(() {
  if (controller.isLoading.value)
    return const LoadingWidget();
  if (controller.hasError.value)
    return ErrorStateWidget(
      title: '加载失败',
      onRetry: controller.retry,
    );
  if (controller.items.isEmpty)
    return EmptyStateWidget(title: '暂无数据');
  return ContentWidget();
})

// 动画
FadeInAnimation(child: widget)
SlideInAnimation(child: widget)
```

## 文件检查清单

每个模块完成后检查：

- [ ] 创建了_view.dart平台检测器
- [ ] 创建了_view_ios.dart iOS实现
- [ ] 使用了GetView自动注入
- [ ] 使用了PlatformUtil检测
- [ ] 通用组件正确导入
- [ ] 编译无误
- [ ] iOS/Android都能正常运行
- [ ] 文档已更新

## 预计时间表

```
今天:
- History ✅ (完成)
- Tasks ⏳ (30分钟)

明天:
- Profile (1小时)
- Credit (1小时)
- More/About (45分钟)

本周:
- Login (1小时)
- Payment (1.5小时)
- Feedback (30分钟)
- 文档总结 (1小时)

总计: 约8小时工作量
```

## 常见问题

**Q: 如何处理复杂的Material页面？**
A: 保持原有的Material实现在_buildMaterialXxx()方法中，只需在iOS版本创建对应的Cupertino实现。

**Q: 如何共享代码？**
A: 将公共的业务逻辑提取到controller中，UI层尽可能分离。

**Q: 如何处理第三方组件？**
A: 如果第三方组件只支持Material，在iOS版本中用Cupertino实现替代。

**Q: 如何保证一致性？**
A: 使用AppSpacing、AppColors、AppTextStyles等统一系统。

## 下一步

1. 继续按照优先级完成剩余模块
2. 创建完整的模块迁移检查清单
3. 编写最终的总结文档
4. 准备发布到生产环境

---

**状态**: 进行中 🚀
**完成度**: 30% (3/10)
**预计完成**: 24小时
