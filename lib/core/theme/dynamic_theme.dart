import 'package:flutter/material.dart';
import 'app_colors.dart';

class DynamicTheme {
  final bool isDark;
  DynamicTheme(this.isDark);

  Color get bg => isDark ? AppColors.background : const Color(0xFFF4F7F9);
  Color get surface => isDark ? AppColors.surface : const Color(0xFFFFFFFF);
  Color get surfaceLight => isDark ? AppColors.surfaceLight : const Color(0xFFF8FAFC);

  Color get textPrimary => isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
  Color get textSecondary => isDark ? AppColors.textSecondary : const Color(0xFF64748B);
  Color get textMuted => isDark ? AppColors.textMuted : const Color(0xFF94A3B8);

  Color get border => isDark ? AppColors.border : const Color(0xFFE2E8F0);
  Color get borderLight => isDark ? AppColors.borderLight : const Color(0xFFF1F5F9);

  Color get primary => AppColors.primary;
  Color get primaryDark => AppColors.primaryDark;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get info => AppColors.info;

  Color? get error => AppColors.error;
}

class ThemeProvider extends InheritedWidget {
  final DynamicTheme theme;

  const ThemeProvider({Key? key, required this.theme, required Widget child})
      : super(key: key, child: child);

  static DynamicTheme of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();

    // إذا لم يجد الـ Provider، قم بإرجاع ثيم افتراضي بدلاً من إظهار شاشة حمراء
    if (provider == null) {
      return DynamicTheme(true); // true تعني الوضع الليلي كافتراضي
    }

    return provider.theme;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) => theme.isDark != oldWidget.theme.isDark;
}