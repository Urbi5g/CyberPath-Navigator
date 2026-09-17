import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/profile_model.dart';

// ─────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────
class ProfileHeaderWidget extends StatelessWidget {
  final ProfileTheme theme;
  final ProfileData profile;
  final VoidCallback onEdit;

  const ProfileHeaderWidget({Key? key, required this.theme, required this.profile, required this.onEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.border),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: -10,
            start: -10,
            child: IconButton(
              icon: Icon(Icons.edit_outlined, color: theme.primary, size: 26),
              onPressed: onEdit,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primary.withOpacity(0.15),
                  border: Border.all(color: theme.primary, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.surfaceLight,
                  child: Icon(Icons.security, size: 50, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(profile.name, style: AppTextStyles.headlineMedium.copyWith(color: theme.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(profile.interest, style: AppTextStyles.bodyMedium.copyWith(color: theme.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(profile.level, style: AppTextStyles.labelLarge.copyWith(color: theme.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Statistics Row
// ─────────────────────────────────────────────
class ProfileStatisticsWidget extends StatelessWidget {
  final ProfileTheme theme;
  final ProfileData profile;

  const ProfileStatisticsWidget({Key? key, required this.theme, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(theme: theme, icon: Icons.star, title: "XP", value: profile.xp.toString(), color: theme.warning)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _StatCard(theme: theme, icon: Icons.emoji_events, title: "Badges", value: profile.badges.toString(), color: theme.primary)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _StatCard(theme: theme, icon: Icons.task_alt, title: "Stages", value: profile.stages.toString(), color: theme.success)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final ProfileTheme theme;
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.theme, required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: theme.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Current Pathway Card
// ─────────────────────────────────────────────
class CurrentPathWidget extends StatelessWidget {
  final ProfileTheme theme;
  final List<Map<String, dynamic>> pathways;

  const CurrentPathWidget({Key? key, required this.theme, required this.pathways}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pathways.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.border),
        ),
        child: Text('لا يوجد مسار مشترك به حالياً', style: AppTextStyles.bodyMedium.copyWith(color: theme.textSecondary)),
      );
    }

    final currentPath = pathways.first;
    final title = currentPath['title'] ?? 'بدون اسم';
    final stage = currentPath['currentStage'] ?? 'غير محدد';
    final progress = (currentPath['progressPercent'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المسار الحالي', style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.bodyLarge.copyWith(color: theme.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Text('المرحلة الحالية: $stage', style: AppTextStyles.bodySmall.copyWith(color: theme.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            backgroundColor: theme.surfaceLight,
            color: theme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(progress * 100).toInt()}% مكتمل', style: AppTextStyles.labelMedium.copyWith(color: theme.primary)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Enrolled Pathways List
// ─────────────────────────────────────────────
class EnrolledPathsWidget extends StatelessWidget {
  final ProfileTheme theme;
  final List<Map<String, dynamic>> paths;
  final VoidCallback onEdit;

  const EnrolledPathsWidget({Key? key, required this.theme, required this.paths, required this.onEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("المسارات المشترك بها", style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
              IconButton(icon: Icon(Icons.edit_outlined, color: theme.primary), onPressed: onEdit),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...paths.map((path) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(path["title"], style: AppTextStyles.labelLarge.copyWith(color: theme.textPrimary))),
                      Text(path["level"], style: AppTextStyles.labelMedium.copyWith(color: theme.primary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: path["progress"],
                    minHeight: 8,
                    color: theme.primary,
                    backgroundColor: theme.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text("${(path["progress"] * 100).toInt()}% مكتمل", style: AppTextStyles.bodySmall.copyWith(color: theme.textSecondary)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings & Buttons
// ─────────────────────────────────────────────
class ThemeSettingsWidget extends StatelessWidget {
  final ProfileTheme theme;
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const ThemeSettingsWidget({Key? key, required this.theme, required this.isDarkMode, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.border),
      ),
      child: SwitchListTile(
        title: Text(isDarkMode ? "الوضع الليلي" : "الوضع النهاري", style: AppTextStyles.bodyLarge.copyWith(color: theme.textPrimary)),
        subtitle: Text("تغيير مظهر التطبيق", style: AppTextStyles.bodySmall.copyWith(color: theme.textSecondary)),
        secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: theme.primary),
        value: isDarkMode,
        activeColor: theme.primary,
        onChanged: onChanged,
      ),
    );
  }
}

class AppUpdateButtonWidget extends StatelessWidget {
  final ProfileTheme theme;

  const AppUpdateButtonWidget({Key? key, required this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.system_update, color: theme.primary),
        label: Text("تحديثات التطبيق", style: AppTextStyles.button.copyWith(color: theme.primary)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: theme.surface,
                title: Text("CyberPath Navigator", style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
                content: Text(
                  "الإصدار الحالي: 1.0.0\n\nآخر التحديثات:\n• تحسين الأداء\n• تحسين واجهة المستخدم\n• إضافة ميزات تعليمية جديدة",
                  style: AppTextStyles.bodyMedium.copyWith(color: theme.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("حسناً", style: TextStyle(color: theme.primary)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class LogoutButtonWidget extends StatelessWidget {
  const LogoutButtonWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
      ),
    );
  }
}