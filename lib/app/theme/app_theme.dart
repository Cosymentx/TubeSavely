import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  // 主色调 - 保持与 AppColors 严格对齐
  static const Color primaryColor = AppColors.primary;
  static const Color accentColor = AppColors.accent;
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color darkCardBackground = Color(0xFF151D2C);
  static const Color lightTextColor = Color(0xFF0F172A);
  static const Color darkTextColor = Color(0xFFF8FAFC);
  static const Color lightTextSecondaryColor = Color(0xFF64748B);
  static const Color darkTextSecondaryColor = Color(0xFF94A3B8);
  static const Color lightBorderColor = Color(0xFFE2E8F0);
  static const Color darkBorderColor = Color(0xFF1E293B);
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color errorColor = AppColors.error;

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: lightBackground,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          onPrimary: Colors.white,
          primaryContainer: AppColors.lightPrimaryContainer,
          onPrimaryContainer: AppColors.lightOnPrimaryContainer,
          secondary: accentColor,
          onSecondary: Colors.white,
          surface: lightCardBackground,
          onSurface: lightTextColor,
          surfaceContainerLowest: Color(0xFFFFFFFF),
          surfaceContainerLow: Color(0xFFF8FAFC),
          surfaceContainer: Color(0xFFF1F5F9),
          surfaceContainerHigh: Color(0xFFE2E8F0),
          outline: lightBorderColor,
          outlineVariant: Color(0xFFF1F5F9),
          error: errorColor,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBackground,
          foregroundColor: lightTextColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: lightTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: lightCardBackground,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: lightBorderColor, width: 1),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: lightCardBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          height: AppSpacing.mobileBottomBarHeight,
          indicatorColor: AppColors.lightPrimaryContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryColor, size: 22);
            }
            return const IconThemeData(color: lightTextSecondaryColor, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: lightTextSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: lightCardBackground,
          elevation: 0,
          useIndicator: true,
          indicatorColor: AppColors.lightPrimaryContainer,
          selectedIconTheme: const IconThemeData(color: primaryColor, size: 22),
          unselectedIconTheme: const IconThemeData(color: lightTextSecondaryColor, size: 22),
          selectedLabelTextStyle: const TextStyle(
            color: primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: lightTextSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: lightBorderColor,
          thickness: 1,
          space: 1,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: lightTextColor, fontSize: 32, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: lightTextColor, fontSize: 28, fontWeight: FontWeight.w700),
          displaySmall: TextStyle(color: lightTextColor, fontSize: 24, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: lightTextColor, fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: lightTextColor, fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: lightTextColor, fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: lightTextColor, fontSize: 14, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: lightTextColor, fontSize: 13, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: lightTextColor, fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
          bodyMedium: TextStyle(color: lightTextColor, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
          bodySmall: TextStyle(color: lightTextSecondaryColor, fontSize: 12, fontWeight: FontWeight.w400, height: 1.35),
          labelLarge: TextStyle(color: lightTextColor, fontSize: 14, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(color: lightTextSecondaryColor, fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(color: lightTextSecondaryColor, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: lightBorderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: errorColor, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: lightTextColor,
            side: const BorderSide(color: lightBorderColor, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          onPrimary: Colors.white,
          primaryContainer: AppColors.darkPrimaryContainer,
          onPrimaryContainer: AppColors.darkOnPrimaryContainer,
          secondary: accentColor,
          onSecondary: Colors.white,
          surface: darkCardBackground,
          onSurface: darkTextColor,
          surfaceContainerLowest: Color(0xFF070A11),
          surfaceContainerLow: Color(0xFF0F1522),
          surfaceContainer: Color(0xFF151D2C),
          surfaceContainerHigh: Color(0xFF1E293B),
          outline: darkBorderColor,
          outlineVariant: Color(0xFF162032),
          error: errorColor,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackground,
          foregroundColor: darkTextColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: darkTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkCardBackground,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: darkBorderColor, width: 1),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkCardBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          height: AppSpacing.mobileBottomBarHeight,
          indicatorColor: AppColors.darkPrimaryContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryColor, size: 22);
            }
            return const IconThemeData(color: darkTextSecondaryColor, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: darkTextSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: darkCardBackground,
          elevation: 0,
          useIndicator: true,
          indicatorColor: AppColors.darkPrimaryContainer,
          selectedIconTheme: const IconThemeData(color: primaryColor, size: 22),
          unselectedIconTheme: const IconThemeData(color: darkTextSecondaryColor, size: 22),
          selectedLabelTextStyle: const TextStyle(
            color: primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: darkTextSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: darkBorderColor,
          thickness: 1,
          space: 1,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: darkTextColor, fontSize: 32, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: darkTextColor, fontSize: 28, fontWeight: FontWeight.w700),
          displaySmall: TextStyle(color: darkTextColor, fontSize: 24, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: darkTextColor, fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: darkTextColor, fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: darkTextColor, fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: darkTextColor, fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: darkTextColor, fontSize: 14, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: darkTextColor, fontSize: 13, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: darkTextColor, fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
          bodyMedium: TextStyle(color: darkTextColor, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
          bodySmall: TextStyle(color: darkTextSecondaryColor, fontSize: 12, fontWeight: FontWeight.w400, height: 1.35),
          labelLarge: TextStyle(color: darkTextColor, fontSize: 14, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(color: darkTextSecondaryColor, fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(color: darkTextSecondaryColor, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF101724),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: darkBorderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: errorColor, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkTextColor,
            side: const BorderSide(color: darkBorderColor, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
}
