import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import 'models/stage_progress_model.dart';
import 'widgets/stages_progress_widgets.dart';

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

  Future<List<StageProgressModel>> _fetchUserStages() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل الدخول');

    // 1. جلب بيانات تقدم المستخدم لمعرفة المراحل المكتملة فقط
    final progressDoc = await _firestore.collection('user_progress').doc(user.uid).get();
    final progressData = progressDoc.data() ?? {};

    List<dynamic> completedStagesData = progressData['completedStages'] ?? [];

    Set<String> completedStageIds = {};
    for (var c in completedStagesData) {
      if (c is Map && c['stageId'] != null) {
        completedStageIds.add(c['stageId'].toString());
      }
    }

    List<StageProgressModel> allStages = [];

    // 2. جلب جميع المسارات الموجودة في قاعدة البيانات
    final pathsSnapshot = await _firestore.collection('learning_paths').get();

    // 3. المرور على كل المسارات وجلب جميع المراحل بداخلها
    for (var pathDoc in pathsSnapshot.docs) {
      String pathId = pathDoc.id;
      String pathTitle = pathDoc.data()['title'] ?? 'مسار غير معروف';

      final stagesSnapshot = await _firestore.collection('learning_paths').doc(pathId).collection('stages').get();

      for (var stageDoc in stagesSnapshot.docs) {
        final stageData = stageDoc.data();

        allStages.add(StageProgressModel(
          stageId: stageDoc.id,
          stageTitle: stageData['title'] ?? 'مرحلة بدون عنوان',
          pathId: pathId,
          pathTitle: pathTitle,
          isCompleted: completedStageIds.contains(stageDoc.id),
          xp: stageData['xp'] is num ? (stageData['xp'] as num).toInt() : 0,
        ));
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
      body: FutureBuilder<List<StageProgressModel>>(
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
            return const ProgressEmptyStateWidget();
          }

          // تطبيق الفلتر
          final filteredStages = allStages.where((stage) {
            if (_selectedFilter == 'مكتملة') return stage.isCompleted;
            if (_selectedFilter == 'غير مكتملة') return !stage.isCompleted;
            return true;
          }).toList();

          return Column(
            children: [
              ProgressFilterBarWidget(
                filters: _filters,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filteredStages.length,
                  itemBuilder: (context, index) {
                    final stage = filteredStages[index];
                    return ProgressStageCardWidget(
                      stage: stage,
                      onPathTap: () => Navigator.pushNamed(
                        context,
                        '/roadmap_details',
                        arguments: stage.pathId,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
