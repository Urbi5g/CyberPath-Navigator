import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ===============================
// Dynamic Theme
// ===============================
class ProfileTheme {
  final bool isDark;

  ProfileTheme(this.isDark);

  Color get bg => isDark ? AppColors.background : const Color(0xFFF4F7F9);
  Color get surface => isDark ? AppColors.surface : Colors.white;
  Color get surfaceLight => isDark ? AppColors.surfaceLight : const Color(0xFFF8FAFC);
  Color get textPrimary => isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
  Color get textSecondary => isDark ? AppColors.textSecondary : const Color(0xFF64748B);
  Color get border => isDark ? AppColors.border : const Color(0xFFE2E8F0);
  Color get primary => AppColors.primary;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get error => AppColors.error;
}

// ===============================
// Profile Data Model
// ===============================
class ProfileData {
  final String name;
  final String email;
  final String level;
  final String interest;
  final int xp;
  final int badges;
  final int certificates;
  final int stages;
  final List<Map<String, dynamic>> pathways;

  ProfileData({
    required this.name,
    required this.email,
    required this.level,
    required this.interest,
    required this.xp,
    required this.badges,
    required this.certificates,
    required this.stages,
    required this.pathways,
  });
}