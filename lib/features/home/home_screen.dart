import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/dynamic_theme.dart';

import 'models/student_model.dart';
import 'widgets/home_widgets.dart'; // ملف التصميم المجمع

// ✅ تم إرجاع الاسم إلى students_dashboard ليتوافق مع مسارات مشروعك
class students_dashboard extends StatefulWidget {
  const students_dashboard({Key? key}) : super(key: key);

  @override
  State<students_dashboard> createState() => _StudentsDashboardState();
}

class _StudentsDashboardState extends State<students_dashboard> {
  bool _isDarkMode = true;

  Future<StudentModel> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User session not found.');

    final userDocument = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDocument.exists) throw Exception('User data was not found in Firestore.');

    final userData = userDocument.data();
    if (userData == null) throw Exception('User data is empty.');

    final progressDocument = await FirebaseFirestore.instance.collection('user_progress').doc(user.uid).get();
    final progressData = progressDocument.data();

    int completedStagesCount = 0;
    final compStages = progressData?['completedStages'];
    if (compStages is int) completedStagesCount = compStages;
    else if (compStages is List) completedStagesCount = compStages.length;

    return StudentModel(
      name: _readString(userData['fullName']),
      level: _readString(userData['level']),
      interest: _readString(userData['interest']),
      points: _readInt(progressData?['xp']),
      badges: _readListLength(progressData?['badges']),
      certificates: _readListLength(progressData?['certificates']),
      completedStages: completedStagesCount,
      activePathways: _readActivePathways(progressData?['activePathways']),
      recentActivities: _readRecentActivities(progressData?['recentActivities']),
    );
  }

  String _readString(dynamic value) => (value?.toString().trim() ?? '').isEmpty ? 'غير متوفر' : value.toString().trim();
  int? _readInt(dynamic value) => value is num ? value.toInt() : null;
  int? _readListLength(dynamic value) => value is List ? value.length : null;

  List<ActivePathway> _readActivePathways(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) => ActivePathway(
      title: _readString(item['title']),
      currentStage: _readString(item['currentStage']),
      progressPercent: (item['progressPercent'] is num) ? (item['progressPercent'] as num).toDouble().clamp(0.0, 1.0) : 0.0,
    )).toList();
  }

  List<ActivityItem> _readRecentActivities(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) => ActivityItem(
      title: _readString(item['title']),
      time: _readString(item['time']),
      icon: _readActivityIcon(item['icon']),
      iconColor: _readActivityColor(item['color']),
    )).toList();
  }

  IconData _readActivityIcon(dynamic value) {
    switch (value?.toString()) {
      case 'task': return Icons.task_alt;
      case 'quiz': return Icons.quiz_outlined;
      case 'badge': return Icons.emoji_events_outlined;
      case 'pathway': return Icons.route_outlined;
      case 'certificate': return Icons.card_membership_outlined;
      default: return Icons.history;
    }
  }

  Color _readActivityColor(dynamic value) {
    final theme = DynamicTheme(_isDarkMode);
    switch (value?.toString()) {
      case 'success': return theme.success;
      case 'warning': return theme.warning;
      case 'info': return theme.info;
      case 'primary': return theme.primary;
      default: return theme.textSecondary;
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) return;
    if (index == 1) Navigator.pushNamed(context, '/roadmaps_explorer');
    else if (index == 2) Navigator.pushNamed(context, '/profile_badges');
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
            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: theme.primary));
            if (snapshot.hasError) return _buildErrorState(context, theme, snapshot.error.toString());
            if (!snapshot.hasData) return _buildErrorState(context, theme, 'لم يتم العثور على بيانات المستخدم.');

            final student = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.screenVertical),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudentProfileSummary(student: student),
                  const SizedBox(height: AppSpacing.xxl),
                  GamificationStats(student: student),
                  const SizedBox(height: AppSpacing.xxl),
                  const ExploreRoadmapsCard(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('الوصول السريع', style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
                  const SizedBox(height: AppSpacing.md),
                  MainNavigationGrid(student: student),
                  const SizedBox(height: AppSpacing.xxl),
                  ActivePathwaysList(pathways: student.activePathways),
                  if (student.activePathways.isNotEmpty) const SizedBox(height: AppSpacing.xxl),
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

  PreferredSizeWidget _buildAppBar(BuildContext context, DynamicTheme theme) {
    return AppBar(
      backgroundColor: theme.bg,
      elevation: 0,
      title: FutureBuilder<StudentModel>(
        future: _loadStudentData(),
        builder: (context, snapshot) {
          final name = snapshot.hasData ? snapshot.data!.name : 'جاري التحميل...';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مسار تعلم الأمن السيبراني', style: AppTextStyles.labelMedium.copyWith(color: theme.textSecondary)),
              Text('مرحباً بك، $name', style: AppTextStyles.headlineMedium.copyWith(color: theme.textPrimary)),
            ],
          );
        },
      ),
      actions: [
        IconButton(icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: theme.textPrimary), onPressed: () => setState(() => _isDarkMode = !_isDarkMode)),
        IconButton(icon: Icon(Icons.notifications_none, color: theme.textPrimary), onPressed: () => Navigator.pushNamed(context, '/profile_setup')),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile_badges'),
            child: CircleAvatar(radius: 18, backgroundColor: theme.primary, child: const Icon(Icons.person, color: Colors.white, size: 20)),
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
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, DynamicTheme theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, color: theme.textMuted, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text('تعذر التحميل', style: AppTextStyles.headlineSmall.copyWith(color: theme.textPrimary)),
          Text(error.replaceFirst('Exception: ', ''), style: AppTextStyles.bodySmall.copyWith(color: theme.textSecondary)),
          ElevatedButton(onPressed: () => setState(() {}), child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}