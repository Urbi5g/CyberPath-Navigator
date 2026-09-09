import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────
// Dynamic Theme Manager
// ─────────────────────────────────────────────
class DynamicTheme {
  final bool isDark;
  DynamicTheme(this.isDark);

  Color get bg => isDark ? AppColors.background : const Color(0xFFF4F7F9);
  Color get surface => isDark ? AppColors.surface : const Color(0xFFFFFFFF);
  Color get surfaceLight =>
      isDark ? AppColors.surfaceLight : const Color(0xFFF8FAFC);

  Color get textPrimary =>
      isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
  Color get textSecondary =>
      isDark ? AppColors.textSecondary : const Color(0xFF64748B);
  Color get textMuted => isDark ? AppColors.textMuted : const Color(0xFF94A3B8);

  Color get border => isDark ? AppColors.border : const Color(0xFFE2E8F0);
  Color get borderLight =>
      isDark ? AppColors.borderLight : const Color(0xFFF1F5F9);

  Color get primary => AppColors.primary;
  Color get primaryDark => AppColors.primaryDark;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get info => AppColors.info;

  Color? get error => null;
}

class ThemeProvider extends InheritedWidget {
  final DynamicTheme theme;

  const ThemeProvider({Key? key, required this.theme, required Widget child})
    : super(key: key, child: child);

  static DynamicTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()!.theme;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) =>
      theme.isDark != oldWidget.theme.isDark;
}

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────
class StudentModel {
  final String name;
  final String level;
  final String interest;
  final int? points;
  final int? badges;
  final int? certificates;
  final List<ActivePathway> activePathways;
  final List<ActivityItem> recentActivities;

  StudentModel({
    required this.name,
    required this.level,
    required this.interest,
    required this.points,
    required this.badges,
    required this.certificates,
    required this.activePathways,
    required this.recentActivities,
  });
}

class ActivePathway {
  final String title;
  final String currentStage;
  final double progressPercent;

  ActivePathway({
    required this.title,
    required this.currentStage,
    required this.progressPercent,
  });
}

class ActivityItem {
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;

  ActivityItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}

// ─────────────────────────────────────────────
// Main Dashboard Screen
// ─────────────────────────────────────────────
class students_dashboard extends StatefulWidget {
  const students_dashboard({Key? key}) : super(key: key);

  @override
  State<students_dashboard> createState() => _StudentsDashboardScreenState();
}

class _StudentsDashboardScreenState extends State<students_dashboard> {
  bool _isDarkMode = true;

  Future<StudentModel> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User session not found.');
    }

    // ─────────────────────────────────────────────
    // Load basic user information
    // ─────────────────────────────────────────────
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDocument.exists) {
      throw Exception('User data was not found in Firestore.');
    }

    final userData = userDocument.data();

    if (userData == null) {
      throw Exception('User data is empty.');
    }

    // ─────────────────────────────────────────────
    // Load user progress
    // ─────────────────────────────────────────────
    final progressDocument = await FirebaseFirestore.instance
        .collection('user_progress')
        .doc(user.uid)
        .get();

    final progressData = progressDocument.data();

    // ─────────────────────────────────────────────
    // Read real progress values
    // ─────────────────────────────────────────────
    final points = _readInt(progressData?['xp']);

    final badges = _readListLength(progressData?['badges']);

    final certificates = _readListLength(progressData?['certificates']);

    final activePathways = _readActivePathways(progressData?['activePathways']);

    final recentActivities = _readRecentActivities(
      progressData?['recentActivities'],
    );

    return StudentModel(
      name: _readString(userData['fullName']),
      level: _readString(userData['level']),
      interest: _readString(userData['interest']),
      points: points,
      badges: badges,
      certificates: certificates,
      activePathways: activePathways,
      recentActivities: recentActivities,
    );
  }

  String _readString(dynamic value) {
    if (value == null) return 'غير متوفر';

    final text = value.toString().trim();

    if (text.isEmpty) return 'غير متوفر';

    return text;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  int? _readListLength(dynamic value) {
    if (value is List) {
      return value.length;
    }

    return null;
  }

  List<ActivePathway> _readActivePathways(dynamic value) {
    if (value is! List) {
      return [];
    }

    final pathways = <ActivePathway>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      final title = _readString(item['title']);

      final currentStage = _readString(item['currentStage']);

      double progressPercent = 0;

      final progress = item['progressPercent'];

      if (progress is num) {
        progressPercent = progress.toDouble().clamp(0.0, 1.0);
      }

      pathways.add(
        ActivePathway(
          title: title,
          currentStage: currentStage,
          progressPercent: progressPercent,
        ),
      );
    }

    return pathways;
  }

  List<ActivityItem> _readRecentActivities(dynamic value) {
    if (value is! List) {
      return [];
    }

    final activities = <ActivityItem>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      final title = _readString(item['title']);

      final time = _readString(item['time']);

      activities.add(
        ActivityItem(
          title: title,
          time: time,
          icon: _readActivityIcon(item['icon']),
          iconColor: _readActivityColor(item['color']),
        ),
      );
    }

    return activities;
  }

  IconData _readActivityIcon(dynamic value) {
    switch (value?.toString()) {
      case 'task':
        return Icons.task_alt;

      case 'quiz':
        return Icons.quiz_outlined;

      case 'badge':
        return Icons.emoji_events_outlined;

      case 'pathway':
        return Icons.route_outlined;

      case 'certificate':
        return Icons.card_membership_outlined;

      default:
        return Icons.history;
    }
  }

  Color _readActivityColor(dynamic value) {
    final theme = DynamicTheme(_isDarkMode);

    switch (value?.toString()) {
      case 'success':
        return theme.success;

      case 'warning':
        return theme.warning;

      case 'info':
        return theme.info;

      case 'primary':
        return theme.primary;

      default:
        return theme.textSecondary;
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) return;

    if (index == 1) {
      Navigator.pushNamed(context, '/roadmaps_explorer');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile_badges');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = DynamicTheme(_isDarkMode);

    return ThemeProvider(
      theme: theme,
      child: Scaffold(
        backgroundColor: theme.bg,
        appBar: _buildAppBar(context, theme),
        body: FutureBuilder<StudentModel>(
          future: _loadStudentData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.primary),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(
                context,
                theme,
                snapshot.error.toString(),
              );
            }

            if (!snapshot.hasData) {
              return _buildErrorState(
                context,
                theme,
                'لم يتم العثور على بيانات المستخدم.',
              );
            }

            final student = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.screenVertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudentProfileSummary(student: student),
                  const SizedBox(height: AppSpacing.xxl),

                  GamificationStats(student: student),
                  const SizedBox(height: AppSpacing.xxl),

                  const ExploreRoadmapsCard(),
                  const SizedBox(height: AppSpacing.xxl),

                  Text(
                    'الوصول السريع',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  const MainNavigationGrid(),
                  const SizedBox(height: AppSpacing.xxl),

                  ActivePathwaysList(pathways: student.activePathways),

                  if (student.activePathways.isNotEmpty)
                    const SizedBox(height: AppSpacing.xxl),

                  RecentActivitiesList(activities: student.recentActivities),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNav(theme),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    DynamicTheme theme,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, color: theme.textMuted, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'تعذر تحميل بيانات المستخدم',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DynamicTheme theme) {
    return AppBar(
      backgroundColor: theme.bg,
      elevation: 0,
      title: FutureBuilder<StudentModel>(
        future: _loadStudentData(),
        builder: (context, snapshot) {
          final name = snapshot.hasData
              ? snapshot.data!.name
              : 'جاري التحميل...';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cybersecurity Learning Pathway',
                style: AppTextStyles.labelMedium.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              Text(
                'مرحباً بك، $name',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: theme.textPrimary,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: theme.textPrimary,
          ),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
          tooltip: 'تبديل المظهر',
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: theme.textPrimary),
              onPressed: () => Navigator.pushNamed(context, '/profile_setup'),
              tooltip: 'إكمال الملف الشخصي',
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.bg, width: 2),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.sm,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pushNamed(context, '/profile_badges'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(DynamicTheme theme) {
    return BottomNavigationBar(
      backgroundColor: theme.surface,
      selectedItemColor: theme.primary,
      unselectedItemColor: theme.textMuted,
      currentIndex: 0,
      onTap: _onBottomNavTapped,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'المسارات'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'الملف الشخصي',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Explore Content Card
// ─────────────────────────────────────────────
class ExploreRoadmapsCard extends StatelessWidget {
  const ExploreRoadmapsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryDark,
            theme.isDark ? theme.surface : const Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'استكشف المسارات والدورات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'اكتشف مسارات الأمن السيبراني المتاحة وابدأ رحلة التعلم.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Navigation Widgets
// ─────────────────────────────────────────────
class MainNavigationGrid extends StatelessWidget {
  const MainNavigationGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);

    final navItems = [
      {
        'title': 'مسارات مقترحة',
        'desc': 'مسارات تناسب مستواك',
        'icon': Icons.auto_awesome,
        'route': '/roadmaps_explorer',
        'color': theme.info,
      },
      {
        'title': 'تنفيذ المهام',
        'desc': 'تأكيد الإنجاز والمراحل',
        'icon': Icons.task_alt,
        'route': '/stage_execution',
        'color': theme.success,
      },
      {
        'title': 'الشارات والملف',
        'desc': 'إنجازاتك ونقاطك',
        'icon': Icons.emoji_events,
        'route': '/profile_badges',
        'color': theme.warning,
      },
      {
        'title': 'سجل النشاطات',
        'desc': 'تتبع أحدث تحركاتك',
        'icon': Icons.history,
        'route': '/activity_log',
        'color': theme.primary,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.05,
      ),
      itemCount: navItems.length,
      itemBuilder: (context, index) {
        final item = navItems[index];

        return StudentFeatureCard(
          title: item['title'] as String,
          description: item['desc'] as String,
          icon: item['icon'] as IconData,
          iconColor: item['color'] as Color,
          route: item['route'] as String,
        );
      },
    );
  }
}

class StudentFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String route;

  const StudentFeatureCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.surfaceLight, theme.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(theme.isDark ? 0.12 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: theme.isDark ? Colors.black26 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          highlightColor: iconColor.withOpacity(0.05),
          splashColor: iconColor.withOpacity(0.15),
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: iconColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: theme.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dashboard Components
// ─────────────────────────────────────────────
class StudentProfileSummary extends StatelessWidget {
  final StudentModel student;

  const StudentProfileSummary({Key? key, required this.student})
    : super(key: key);

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
            color: theme.isDark
                ? Colors.black12
                : Colors.black.withOpacity(0.05),
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
                Text(
                  'المستوى: ${student.level}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'الاهتمام: ${student.interest}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GamificationStats extends StatelessWidget {
  final StudentModel student;

  const GamificationStats({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'النقاط',
            value: student.points == null ? '—' : '${student.points} XP',
            icon: Icons.star,
            color: theme.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            title: 'الشارات',
            value: student.badges == null ? '—' : '${student.badges}',
            icon: Icons.shield,
            color: theme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            title: 'الشهادات',
            value: student.certificates == null
                ? '—'
                : '${student.certificates}',
            icon: Icons.card_membership,
            color: theme.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black12
                : Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.textPrimary,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivePathwaysList extends StatelessWidget {
  final List<ActivePathway> pathways;

  const ActivePathwaysList({Key? key, required this.pathways})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pathways.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = ThemeProvider.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المسارات النشطة',
          style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        ...pathways
            .map((pathway) => _buildPathwayCard(context, pathway, theme))
            .toList(),
      ],
    );
  }

  Widget _buildPathwayCard(
    BuildContext context,
    ActivePathway pathway,
    DynamicTheme theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black12
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => Navigator.pushNamed(context, '/roadmap_details'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pathway.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: theme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(pathway.progressPercent * 100).toInt()}%',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'المرحلة الحالية: ${pathway.currentStage}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: pathway.progressPercent,
                  backgroundColor: theme.surfaceLight,
                  color: theme.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecentActivitiesList extends StatelessWidget {
  final List<ActivityItem> activities;

  const RecentActivitiesList({Key? key, required this.activities})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = ThemeProvider.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'سجل النشاطات',
              style: AppTextStyles.headlineSmall.copyWith(
                color: theme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/activity_log'),
              style: TextButton.styleFrom(foregroundColor: theme.primary),
              child: Text(
                'عرض الكل',
                style: AppTextStyles.labelMedium.copyWith(color: theme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...activities
            .map((activity) => _buildActivityItem(activity, theme))
            .toList(),
      ],
    );
  }

  Widget _buildActivityItem(ActivityItem activity, DynamicTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: activity.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(activity.icon, color: activity.iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  activity.time,
                  style: AppTextStyles.caption.copyWith(color: theme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
