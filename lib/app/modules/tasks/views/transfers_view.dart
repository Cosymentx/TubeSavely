import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../history/views/history_view.dart';
import '../controllers/tasks_controller.dart';
import 'tasks_view.dart';

/// 移动端统一传输中心视图 (Option A: 整合下载任务与已完成历史)
class TransfersView extends StatefulWidget {
  const TransfersView({super.key});

  @override
  State<TransfersView> createState() => _TransfersViewState();
}

class _TransfersViewState extends State<TransfersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TasksController _tasksController = Get.find<TasksController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _buildSegmentedHeader(context, isDark),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TasksView(),
          HistoryView(),
        ],
      ),
    );
  }

  Widget _buildSegmentedHeader(BuildContext context, bool isDark) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        tabs: [
          Obx(() {
            final activeCount = _tasksController.downloadTasks
                .where((t) => t.status.index <= 2)
                .length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('下载中'),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const Tab(text: '已完成'),
        ],
      ),
    );
  }
}
