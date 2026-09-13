import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class StagesProgressScreen extends StatefulWidget {
  const StagesProgressScreen({super.key});

  @override
  State<StagesProgressScreen> createState() => _StagesProgressScreenState();
}

class _StagesProgressScreenState extends State<StagesProgressScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedFilter = 'الكل';
  final List<String> _filters = ['الكل', 'مكتملة', 'غير مكتملة'];

  // دالة لجلب جميع المراحل في قاعدة البيانات وتصنيفها حسب تقدم الطالب
  Future<List<Map<String, dynamic>>> _fetchUserStages() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل الدخول');

    // 1. جلب بيانات تقدم المستخدم لمعرفة المراحل المكتملة فقط
    final progressDoc = await _firestore.collection('user_progress').doc(user.uid).get();
    final progressData = progressDoc.data() ?? {};

    List<dynamic> completedStagesData = progressData['completedStages'] ?? [];

    // إنشاء قائمة سريعة بمعرفات المراحل المكتملة لتسهيل المقارنة
    Set<String> completedStageIds = {};
    for (var c in completedStagesData) {
      if (c is Map && c['stageId'] != null) {
        completedStageIds.add(c['stageId'].toString());
      }
    }

    List<Map<String, dynamic>> allStages = [];

    // 2. جلب جميع المسارات الموجودة في قاعدة البيانات (بدون تصفية بالاشتراك)
    final pathsSnapshot = await _firestore.collection('learning_paths').get();

    // 3. المرور على كل المسارات وجلب جميع المراحل بداخلها
    for (var pathDoc in pathsSnapshot.docs) {
      String pathId = pathDoc.id;
      String pathTitle = pathDoc.data()['title'] ?? 'مسار غير معروف';

      final stagesSnapshot = await _firestore.collection('learning_paths').doc(pathId).collection('stages').get();

      for (var stageDoc in stagesSnapshot.docs) {
        final stageData = stageDoc.data();
        allStages.add({
          'stageId': stageDoc.id,
          'stageTitle': stageData['title'] ?? 'مرحلة بدون عنوان',
          'pathId': pathId,
          'pathTitle': pathTitle,
          'isCompleted': completedStageIds.contains(stageDoc.id),
          'xp': stageData['xp'] ?? 0,
        });
      }
    }

    return allStages;
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
          'سجل المراحل',
          style: AppTextStyles.headlineMedium.copyWith(color: theme.textTheme.bodyLarge?.color),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserStages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}', style: AppTextStyles.bodyMedium));
          }

          final allStages = snapshot.data ?? [];

          if (allStages.isEmpty) {
            return _buildEmptyState(theme);
          }

          // تطبيق الفلتر
          final filteredStages = allStages.where((stage) {
            if (_selectedFilter == 'مكتملة') return stage['isCompleted'] == true;
            if (_selectedFilter == 'غير مكتملة') return stage['isCompleted'] == false;
            return true; // حالة 'الكل' تعيد جميع المراحل
          }).toList();

          return Column(
            children: [
              _buildFilterBar(theme),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filteredStages.length,
                  itemBuilder: (context, index) {
                    return _buildStageCard(filteredStages[index], theme);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm), // left للغة العربية
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : theme.cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : theme.dividerColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStageCard(Map<String, dynamic> stage, ThemeData theme) {
    final bool isCompleted = stage['isCompleted'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success.withValues(alpha: 0.05) : theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isCompleted ? AppColors.success : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  stage['stageTitle'],
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text('+${stage['xp']} XP', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // زر المسار الذي تنتمي إليه المرحلة
          InkWell(
            onTap: () {
              // التوجيه لصفحة تفاصيل المسار عند الضغط
              Navigator.pushNamed(
                context,
                '/roadmap_details',
                arguments: stage['pathId'],
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'مسار: ${stage['pathTitle']}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
          Icon(Icons.layers_clear_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد مراحل مسجلة',
            style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'لم يتم العثور على أي مراحل في قاعدة البيانات حالياً.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
