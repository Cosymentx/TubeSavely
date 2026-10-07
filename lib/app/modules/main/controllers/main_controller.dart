import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/views/home_view.dart';
import '../../profile/views/profile_view.dart';
import '../../tasks/views/transfers_view.dart';
import '../../video/convert/views/convert_view.dart';

class MainController extends GetxController {
  // 当前选中的标签页索引
  final RxInt currentIndex = 0.obs;

  // 移动端整合页面列表 (Option A: 传输中心整合下载中与已完成历史，新增媒体工具箱直达)
  final List<Widget> pages = [
    const HomeView(),
    const TransfersView(),
    const ConvertView(),
    const ProfileView(),
  ];

  // 切换标签页
  void changePage(int index) {
    currentIndex.value = index;
  }
}
