import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import 'models/stage_execution_model.dart';
import 'widgets/stage_execution_widgets.dart';

class StageExecutionScreen extends StatefulWidget {
  final String pathId;
  final String stageId;

  const StageExecutionScreen({super.key, required this.pathId, required this.stageId});

  @override
  State<StageExecutionScreen> createState() => _StageExecutionScreenState();
}

class _StageExecutionScreenState extends State<StageExecutionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;
  StageExecutionModel? _stageModel;

  bool _isCompleting = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadStage();
  }

  Future<void> _loadStage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final stageDocument = await _firestore
          .collection('learning_paths')
          .doc(widget.pathId)
          .collection('stages')
          .doc(widget.stageId)
          .get();

      if (!stageDocument.exists || stageDocument.data() == null) {
        throw Exception('Stage data was not found.');
      }

      final parsedStage = StageExecutionModel.fromMap(stageDocument.data()!);

      // Check if user already completed this stage
      final user = FirebaseAuth.instance.currentUser;
      bool alreadyCompleted = false;

      if (user != null) {
        final progressDoc = await _firestore.collection('user_progress').doc(user.uid).get();
        if (progressDoc.exists) {
          final completedList = progressDoc.data()?['completedStages'] as List?;
          if (completedList != null) {
            alreadyCompleted = completedList.any((stage) =>
            stage['pathId']?.toString() == widget.pathId &&
                stage['stageId']?.toString() == widget.stageId
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _stageModel = parsedStage;
        _isCompleted = alreadyCompleted;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _completeStage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to complete this stage.')),
      );
      return;
    }

    if (_isCompleted || _isCompleting || _stageModel == null) return;

    setState(() => _isCompleting = true);

    try {
      final progressRef = _firestore.collection('user_progress').doc(user.uid);
      final progressSnapshot = await progressRef.get();
      final progressData = progressSnapshot.data() ?? {};

      final completedStages = progressData['completedStages'] is List
          ? List<Map<String, dynamic>>.from((progressData['completedStages'] as List).whereType<Map>())
          : <Map<String, dynamic>>[];

      final alreadyCompleted = completedStages.any(
            (stage) => stage['pathId']?.toString() == widget.pathId && stage['stageId']?.toString() == widget.stageId,
      );

      if (alreadyCompleted) {
        if (!mounted) return;
        setState(() {
          _isCompleted = true;
          _isCompleting = false;
        });
        return;
      }

      final xp = _stageModel!.xp ?? 0;
      final currentXp = progressData['xp'] is num ? (progressData['xp'] as num).toInt() : 0;

      completedStages.add({
        'pathId': widget.pathId,
        'stageId': widget.stageId,
        'completedAt': Timestamp.now(),
      });

      final now = DateTime.now();
      final timeString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await progressRef.set({
        'xp': currentXp + xp,
        'completedStages': completedStages,
        'recentActivities': FieldValue.arrayUnion([{
          'title': 'أكملت ${_stageModel!.title}',
          'time': timeString,
          'icon': 'task',
          'color': 'success',
        }]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _isCompleted = true;
        _isCompleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(xp > 0 ? 'Stage completed! +$xp XP' : 'Stage completed!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete stage: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Stage',
          style: AppTextStyles.headlineMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return StageErrorWidget(errorMessage: _errorMessage!, onRetry: _loadStage);
    }

    if (_stageModel == null) {
      return const Center(child: Text('No stage data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadStage,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          StageHeaderWidget(stage: _stageModel!),
          const SizedBox(height: AppSpacing.lg),
          CompleteStageButtonWidget(
            isCompleted: _isCompleted,
            isCompleting: _isCompleting,
            xp: _stageModel!.xp ?? 0,
            onComplete: _completeStage,
          ),
          const SizedBox(height: AppSpacing.lg),
          TopicsSectionWidget(topics: _stageModel!.topics),
          const SizedBox(height: AppSpacing.lg),
          LinksSectionWidget(title: 'Resources', icon: Icons.menu_book_rounded, links: _stageModel!.resources),
          const SizedBox(height: AppSpacing.sm),
          LinksSectionWidget(title: 'Courses', icon: Icons.school_rounded, links: _stageModel!.courses),
          const SizedBox(height: AppSpacing.sm),
          LinksSectionWidget(title: 'Platforms & Labs', icon: Icons.computer_rounded, links: _stageModel!.platforms),
          const SizedBox(height: AppSpacing.sm),
          LinksSectionWidget(title: 'Additional Links', icon: Icons.link_rounded, links: _stageModel!.additionalLinks),
        ],
      ),
    );
  }
}
