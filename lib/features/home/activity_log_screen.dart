import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> _fetchActivities() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل الدخول');

    final progressDoc = await _firestore.collection('user_progress').doc(user.uid).get();

    if (!progressDoc.exists) return [];

    final progressData = progressDoc.data() ?? {};
    final activitiesList = progressData['recentActivities'] as List<dynamic>? ?? [];

    // تحويل القائمة وترتيبها من الأحدث للأقدم (بافتراض أن الأحدث يُضاف آخراً)
    return activitiesList.map((e) => Map<String, dynamic>.from(e)).toList().reversed.toList();
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'task': return Icons.task_alt;
      case 'quiz': return Icons.quiz_outlined;
      case 'badge': return Icons.emoji_events_outlined;
      case 'pathway': return Icons.route_outlined;
      case 'certificate': return Icons.card_membership_outlined;
      default: return Icons.history;
    }
  }

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'success': return AppColors.success;
      case 'warning': return AppColors.warning;
      case 'info': return AppColors.info;
      case 'primary': return AppColors.primary;
      case 'error': return Colors.red;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'سجل النشاطات',
          style: AppTextStyles.headlineMedium.copyWith(color: theme.textTheme.bodyLarge?.color),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ أثناء تحميل السجل', style: AppTextStyles.bodyMedium));
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(activity, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, ThemeData theme) {
    final title = activity['title'] ?? 'نشاط غير معروف';
    final time = activity['time'] ?? 'غير محدد';
    final iconColor = _getColor(activity['color']);
    final icon = _getIcon(activity['icon']);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا يوجد نشاطات بعد',
            style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'أكمل المراحل وابدأ التعلم ليظهر سجلك هنا.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}