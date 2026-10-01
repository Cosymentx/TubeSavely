import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import 'app/routes/app_pages.dart';
import 'app/services/init_services.dart';
import 'app/theme/app_theme.dart';
import 'app/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务
  await initServices();

  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // 设置设备方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 初始化窗口管理器（桌面平台）
  if (!GetPlatform.isMobile) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: const Size(950, 650),
      minimumSize: const Size(800, 600),
      center: true,
      backgroundColor: const Color(0xFFF8FAFC),
      skipTaskbar: false,
      titleBarStyle: GetPlatform.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 桌面平台：直接使用原生桌面缩放，启动原生专属 DesktopHomeView，绝不套用移动端 360px 缩放
    if (!GetPlatform.isMobile) {
      return GetMaterialApp(
        title: 'TubeSavely',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: Routes.DESKTOP_HOME,
        getPages: AppPages.routes,
        defaultTransition: Transition.fade,
        transitionDuration: const Duration(milliseconds: 200),
        translations: AppTranslations(),
        locale: Get.deviceLocale ?? const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
          Locale('ja', 'JP'),
          Locale('ko', 'KR'),
        ],
      );
    }

    // 移动平台：保持适合手机竖屏的自适应缩放
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'TubeSavely',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          defaultTransition: Transition.fade,
          transitionDuration: const Duration(milliseconds: 300),
          translations: AppTranslations(),
          locale: Get.deviceLocale ?? const Locale('zh', 'CN'),
          fallbackLocale: const Locale('en', 'US'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
            Locale('ja', 'JP'),
            Locale('ko', 'KR'),
          ],
        );
      },
    );
  }
}
