import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../models/student_model.dart';
import '../../stages/stages_progress_screen.dart';
import '../activity_log_screen.dart';

// ─────────────────────────────────────────────
// Profile Summary
// ─────────────────────────────────────────────
class StudentProfileSummary extends StatelessWidget {
  final StudentModel student;
  const StudentProfileSummary({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.security, color: theme.primary, size: 32),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المستوى: ${student.level}', style: AppTextStyles.labelLarge.copyWith(color: theme.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text('الاهتمام: ${student.interest}', style: AppTextStyles.bodySmall.copyWith(color: theme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Gamification Stats
// ─────────────────────────────────────────────
class GamificationStats extends StatelessWidget {
  final StudentModel student;
  const GamificationStats({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'النقاط', value: student.points == null ? '—' : '${student.points} XP', icon: Icons.star, color: theme.warning)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _StatCard(title: 'الشارات', value: student.badges == null ? '—' : '${student.badges}', icon: Icons.shield, color: theme.primary)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _StatCard(title: 'الشهادات', value: student.certificates == null ? '—' : '${student.certificates}', icon: Icons.card_membership, color: theme.success)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: theme.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Explore Roadmaps Card
// ─────────────────────────────────────────────
class ExploreRoadmapsCard extends StatelessWidget {
  const ExploreRoadmapsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.primaryDark, theme.isDark ? theme.surface : const Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => Navigator.pushNamed(context, '/roadmaps_explorer'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('استكشف المسارات والدورات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: AppSpacing.xs),
                      Text('اكتشف مسارات الأمن السيبراني المتاحة وابدأ رحلة التعلم.', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Main Navigation Grid
// ─────────────────────────────────────────────
class MainNavigationGrid extends StatelessWidget {
  final StudentModel student;
  const MainNavigationGrid({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    final navItems = [
      {'title': 'مسارات مقترحة', 'desc': 'مسارات تناسب مستواك', 'icon': Icons.auto_awesome, 'route': '/roadmaps_explorer', 'color': theme.info},
      {'title': 'تنفيذ المهام', 'desc': 'تأكيد الإنجاز والمراحل', 'icon': Icons.task_alt, 'route': '/stage_execution', 'color': theme.success},
      {'title': 'عرض المراحل', 'desc': 'أنجزت ${student.completedStages} مراحل', 'icon': Icons.layers_outlined, 'route': '/stages_progress', 'color': theme.warning},
      {'title': 'سجل النشاطات', 'desc': 'تتبع أحدث تحركاتك', 'icon': Icons.history, 'route': '/activity_log', 'color': theme.primary},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 1.05),
      itemCount: navItems.length,
      itemBuilder: (context, index) {
        final item = navItems[index];
        return StudentFeatureCard(title: item['title'] as String, description: item['desc'] as String, icon: item['icon'] as IconData, iconColor: item['color'] as Color, route: item['route'] as String);
      },
    );
  }
}

class StudentFeatureCard extends StatelessWidget {
  final String title, description, route;
  final IconData icon;
  final Color iconColor;
  const StudentFeatureCard({Key? key, required this.title, required this.description, required this.icon, required this.iconColor, required this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.surface, iconColor.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () {
            if (route == '/stages_progress') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StagesProgressScreen()));
            } else if (route == '/activity_log') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityLogScreen()));
            } else {
              Navigator.pushNamed(context, route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 28),
                const Spacer(),
                Text(title, style: AppTextStyles.labelLarge.copyWith(color: theme.textPrimary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(description, style: AppTextStyles.labelSmall.copyWith(color: theme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Active Pathways & Recent Activities
// ─────────────────────────────────────────────
class ActivePathwaysList extends StatelessWidget {
  final List<ActivePathway> pathways;
  const ActivePathwaysList({Key? key, required this.pathways}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pathways.isEmpty) return const SizedBox.shrink();
    final theme = ThemeProvider.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المسارات النشطة', style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        ...pathways.map((p) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: theme.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title, style: AppTextStyles.labelLarge.copyWith(color: theme.textPrimary)),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(value: p.progressPercent, backgroundColor: theme.surfaceLight, color: theme.primary, minHeight: 8),
            ],
          ),
        )).toList(),
      ],
    );
  }
}

class RecentActivitiesList extends StatelessWidget {
  final List<ActivityItem> activities;
  const RecentActivitiesList({Key? key, required this.activities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();
    final theme = ThemeProvider.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('سجل النشاطات', style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        ...activities.map((a) => ListTile(
          leading: Icon(a.icon, color: a.iconColor),
          title: Text(a.title, style: AppTextStyles.bodyMedium.copyWith(color: theme.textPrimary)),
          subtitle: Text(a.time, style: AppTextStyles.caption.copyWith(color: theme.textMuted)),
        )).toList(),
      ],
    );
  }
}