import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/desktop_dialog_wrapper.dart';
import 'desktop_about_dialog.dart';
import 'desktop_compress_view.dart';
import 'desktop_convert_view.dart';
import 'desktop_download_view.dart';
import 'desktop_setting_dialog.dart';

enum DesktopTabType {
  download,
  convert,
  compress,
}

/// 桌面端主框架页面（完全兼容原生桌面端布局，对应用户截图）
class DesktopHomeView extends StatefulWidget {
  const DesktopHomeView({super.key});

  @override
  State<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends State<DesktopHomeView> {
  DesktopTabType _currentTab = DesktopTabType.download;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchTab(DesktopTabType tab) {
    setState(() {
      _currentTab = tab;
    });
    _pageController.jumpToPage(tab.index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isMac = Platform.isMacOS;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: isMac ? 14 : 8,
            left: 14,
            right: 14,
            bottom: 8,
          ),
          child: Column(
            children: [
              // 顶部 Header 栏（Logo/版本号、中间胶囊Tab切换、右侧设置/关于按钮）
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 左侧 Logo 与名称（靠左对齐，不与中间胶囊冲突）
                    Positioned(
                      left: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/ic_logo.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'app_name'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              final version = snapshot.data?.version ?? '1.0.2';
                              return Text(
                                version,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // 中间胶囊切换器（下载 / 转换 / 压缩）
                    Center(
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: primaryColor, width: 0.8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 下载 Tab
                              InkWell(
                                onTap: () => _switchTab(DesktopTabType.download),
                                child: Tooltip(
                                  message: 'download'.tr,
                                  child: Container(
                                    width: 62,
                                    height: 34,
                                    alignment: Alignment.center,
                                    color: _currentTab == DesktopTabType.download
                                        ? primaryColor
                                        : Colors.transparent,
                                    child: Icon(
                                      Icons.file_download,
                                      size: 20,
                                      color: _currentTab == DesktopTabType.download
                                          ? Colors.white
                                          : primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              Container(width: 0.8, color: primaryColor),
                              // 转换 Tab
                              InkWell(
                                onTap: () => _switchTab(DesktopTabType.convert),
                                child: Tooltip(
                                  message: 'convert'.tr,
                                  child: Container(
                                    width: 62,
                                    height: 34,
                                    alignment: Alignment.center,
                                    color: _currentTab == DesktopTabType.convert
                                        ? primaryColor
                                        : Colors.transparent,
                                    child: Icon(
                                      Icons.cached_rounded,
                                      size: 20,
                                      color: _currentTab == DesktopTabType.convert
                                          ? Colors.white
                                          : primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              Container(width: 0.8, color: primaryColor),
                              // 压缩 Tab
                              InkWell(
                                onTap: () => _switchTab(DesktopTabType.compress),
                                child: Tooltip(
                                  message: 'compress'.tr,
                                  child: Container(
                                    width: 62,
                                    height: 34,
                                    alignment: Alignment.center,
                                    color: _currentTab == DesktopTabType.compress
                                        ? primaryColor
                                        : Colors.transparent,
                                    child: Icon(
                                      Icons.compress,
                                      size: 20,
                                      color: _currentTab == DesktopTabType.compress
                                          ? Colors.white
                                          : primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 右侧设置与关于按钮
                  Positioned(
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 20,
                          splashRadius: 18,
                          tooltip: 'general_settings'.tr,
                          icon: Icon(
                            Icons.settings,
                            color: theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                          onPressed: () => DesktopSettingDialog.show(context),
                        ),
                        IconButton(
                          iconSize: 20,
                          splashRadius: 18,
                          tooltip: 'about_us'.tr,
                          icon: Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.35),
                              builder: (context) => const DesktopDialogWrapper(
                                width: 380,
                                child: DesktopAboutDialog(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

              // 主体 PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    DesktopDownloadView(),
                    DesktopConvertView(),
                    DesktopCompressView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
