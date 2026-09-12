import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login/login_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

// ===============================
// Dynamic Theme
// ===============================

class ProfileTheme {
  final bool isDark;

  ProfileTheme(this.isDark);

  Color get bg => isDark ? AppColors.background : const Color(0xFFF4F7F9);

  Color get surface => isDark ? AppColors.surface : Colors.white;

  Color get surfaceLight =>
      isDark ? AppColors.surfaceLight : const Color(0xFFF8FAFC);

  Color get textPrimary =>
      isDark ? AppColors.textPrimary : const Color(0xFF1E293B);

  Color get textSecondary =>
      isDark ? AppColors.textSecondary : const Color(0xFF64748B);

  Color get border => isDark ? AppColors.border : const Color(0xFFE2E8F0);

  Color get primary => AppColors.primary;

  Color get success => AppColors.success;

  Color get warning => AppColors.warning;

  Color get error => AppColors.error;
}

// ===============================
// Profile Screen
// ===============================
class ProfileData {
  final String name;
  final String email;
  final String level;
  final String interest;

  final int xp;
  final int badges;
  final int certificates;

  final List<Map<String,dynamic>> pathways;

  ProfileData({
    required this.name,
    required this.email,
    required this.level,
    required this.interest,
    required this.xp,
    required this.badges,
    required this.certificates,
    required this.pathways,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isDarkMode = true;
  Future<ProfileData> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if(user == null){
      throw Exception("User not logged in");
    }

    // users/{uid}
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    if(userData == null){
      throw Exception("User data not found");
    }

    // user_progress/{uid}
    final progressDoc = await FirebaseFirestore.instance
        .collection('user_progress')
        .doc(user.uid)
        .get();

    final progressData = progressDoc.data() ?? {};

    final pathways = <Map<String,dynamic>>[];

    if(progressData['activePathways'] != null){
      for(final item in progressData['activePathways']){
        pathways.add(
            {
              "title": item['title'] ?? '',
              "level": item['level'] ?? '',
              "progress": item['progressPercent'] ?? 0,
            }
        );
      }
    }

    return ProfileData(
      name: userData['fullName'] ?? 'User',
      email: userData['email'] ?? user.email ?? '',
      level: userData['level'] ?? 'Unknown',
      interest: userData['interest'] ?? 'Unknown',
      xp: progressData['xp'] ?? 0,
      badges: (progressData['badges'] as List?)?.length ?? 0,
      certificates: (progressData['certificates'] as List?)?.length ?? 0,
      pathways: pathways,
    );
  }

  final List<Map<String, dynamic>> paths = [
    {
      "title": "SOC Analyst Fundamentals",
      "level": "Intermediate",
      "progress": 0.75,
    },
    {"title": "Network Security", "level": "Beginner", "progress": 0.40},
    {"title": "Incident Response", "level": "Advanced", "progress": 0.20},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ProfileTheme(isDarkMode);

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        title: Text(
          "الملف الشخصي",
          style: AppTextStyles.headlineMedium.copyWith(
            color: theme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: theme.textPrimary,
            ),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<ProfileData>(
        future: loadProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("لا توجد بيانات"),
            );
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(
              AppSpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                _profileHeader(
                  theme,
                  profile,
                ),
                const SizedBox(
                  height: AppSpacing.xxl,
                ),
                _statistics(
                  theme,
                  profile,
                ),
                const SizedBox(
                  height: AppSpacing.xxl,
                ),
                _currentPath(
                    theme,profile.pathways
                ),
                const SizedBox(
                  height: AppSpacing.xxl,
                ),
                _enrolledPaths(
                  theme,
                  profile.pathways,
                ),
                const SizedBox(
                  height: AppSpacing.xxl,
                ),
                // تم إضافة العناصر هنا لتظهر في الشاشة
                _settings(theme),
                const SizedBox(
                  height: AppSpacing.xxl,
                ),
                _updateButton(theme),
                const SizedBox(
                  height: AppSpacing.xxl,
                ),
                _logoutButton(),
                const SizedBox(
                  height: AppSpacing.xxl,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===============================
  // Profile Header
  // ===============================

  Widget _profileHeader(
      ProfileTheme theme,
      ProfileData profile,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
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
          Text(
            profile.name,
            style: AppTextStyles.headlineMedium.copyWith(
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile.interest,
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              profile.level,
              style: AppTextStyles.labelLarge.copyWith(color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // Statistics
  // ===============================

  Widget _statistics(
      ProfileTheme theme,
      ProfileData profile,
      ) {
    return Row(
      children: [
        Expanded(
          child: _statCard(theme, Icons.star,
              "XP", profile.xp.toString(),
              theme.warning),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _statCard(
            theme,
            Icons.emoji_events,
            "Badges",
            profile.badges.toString(),
            theme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _statCard(
            theme,
            Icons.task_alt,
            "Stages",
            profile.certificates.toString(),
            theme.success,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      ProfileTheme theme,
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
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

  // ===============================
  // Current Path
  // ===============================

  Widget _currentPath(
      ProfileTheme theme,
      List<Map<String, dynamic>> pathways,
      ) {
    if (pathways.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.border,
          ),
        ),
        child: Text(
          'لا يوجد مسار مشترك به حالياً',
          style: AppTextStyles.bodyMedium.copyWith(
            color: theme.textSecondary,
          ),
        ),
      );
    }

    // نأخذ أول مسار باعتباره المسار الحالي
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
          Text(
            'المسار الحالي',
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'المرحلة الحالية: $stage',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.textSecondary,
            ),
          ),
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
            child: Text(
              '${(progress * 100).toInt()}% مكتمل',
              style: AppTextStyles.labelMedium.copyWith(
                color: theme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // Enrolled Paths
  // ===============================

  Widget _enrolledPaths(
      ProfileTheme theme,
      List<Map<String,dynamic>> paths,
      ) {
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
          Text(
            "المسارات المشترك بها",
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.textPrimary,
            ),
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
                      Expanded(
                        child: Text(
                          path["title"],
                          style: AppTextStyles.labelLarge.copyWith(
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        path["level"],
                        style: AppTextStyles.labelMedium.copyWith(
                          color: theme.primary,
                        ),
                      ),
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
                  Text(
                    "${(path["progress"] * 100).toInt()}% مكتمل",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ===============================
  // Settings
  // ===============================
  Widget _settings(ProfileTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.border),
      ),
      child: SwitchListTile(
        title: Text(
          isDarkMode ? "الوضع الليلي" : "الوضع النهاري",
          style: AppTextStyles.bodyLarge.copyWith(color: theme.textPrimary),
        ),
        subtitle: Text(
          "تغيير مظهر التطبيق",
          style: AppTextStyles.bodySmall.copyWith(color: theme.textSecondary),
        ),
        secondary: Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: theme.primary,
        ),
        value: isDarkMode,
        activeColor: theme.primary,
        onChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
    );
  }

  // ===============================
  // App Updates
  // ===============================

  Widget _updateButton(ProfileTheme theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.system_update, color: theme.primary),
        label: Text(
          "تحديثات التطبيق",
          style: AppTextStyles.button.copyWith(color: theme.primary),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: theme.surface,
                title: Text(
                  "CyberPath Navigator",
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                content: Text(
                  "الإصدار الحالي: 1.0.0\n\n"
                      "آخر التحديثات:\n"
                      "• تحسين الأداء\n"
                      "• تحسين واجهة المستخدم\n"
                      "• إضافة ميزات تعليمية جديدة",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "حسناً",
                      style: TextStyle(color: theme.primary),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ===============================
  // Logout
  // ===============================

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          // تم إضافة دالة تسجيل الخروج الفعلي من فايربيس
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
                  (route) => false,
            );
          }
        },
      ),
    );
  }
}