import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../stages/stage_execution_screen.dart';

class RoadmapDetailsScreen extends StatefulWidget {
  final String pathId;

  const RoadmapDetailsScreen({super.key, required this.pathId});

  @override
  State<RoadmapDetailsScreen> createState() => _RoadmapDetailsScreenState();
}

class _RoadmapDetailsScreenState extends State<RoadmapDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _pathData;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _stages = [];

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    try {
      final pathDocument = await _firestore
          .collection('learning_paths')
          .doc(widget.pathId)
          .get();

      if (!pathDocument.exists) {
        throw Exception('Learning path was not found.');
      }

      final pathData = pathDocument.data();

      if (pathData == null) {
        throw Exception('Learning path data is empty.');
      }

      final stagesSnapshot = await _firestore
          .collection('learning_paths')
          .doc(widget.pathId)
          .collection('stages')
          .orderBy('order')
          .get();

      if (!mounted) return;

      setState(() {
        _pathData = pathData;
        _stages = stagesSnapshot.docs;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Roadmap Details',
          style: AppTextStyles.headlineMedium.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_pathData == null) {
      return const Center(child: Text('No roadmap data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadRoadmap,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildPathHeader(context),
          const SizedBox(height: AppSpacing.xl),
          _buildStagesSection(context),
        ],
      ),
    );
  }

  Widget _buildPathHeader(BuildContext context) {
    final theme = Theme.of(context);

    final title = _pathData!['title']?.toString().trim();
    final description = _pathData!['description']?.toString().trim();
    final level = _pathData!['level']?.toString().trim();
    final interest = _pathData!['interest']?.toString().trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title == null || title.isEmpty ? 'Untitled Learning Path' : title,
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description == null || description.isEmpty
                ? 'No description available.'
                : description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (level != null && level.isNotEmpty)
                _buildInfoChip(context, Icons.school_outlined, level),
              if (interest != null && interest.isNotEmpty)
                _buildInfoChip(context, Icons.work_outline_rounded, interest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStagesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stages',
          style: AppTextStyles.headlineSmall.copyWith(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_stages.length} ${_stages.length == 1 ? 'Stage' : 'Stages'} in this learning path',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_stages.isEmpty)
          _buildEmptyStages(context)
        else
          Column(
            children: [
              for (int index = 0; index < _stages.length; index++) ...[
                _buildStageCard(
                  context,
                  index + 1,
                  _stages[index].id,
                  _stages[index].data(),
                ),
                if (index != _stages.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    int stageNumber,
    String stageId,
    Map<String, dynamic> data,
  ) {
    final theme = Theme.of(context);

    final title = data['title']?.toString().trim();
    final description = data['description']?.toString().trim();
    final xp = data['xp'];
    final duration = data['duration']?.toString().trim();
    final difficulty = data['difficulty']?.toString().trim();

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StageExecutionScreen(pathId: widget.pathId, stageId: stageId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 5),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$stageNumber',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title == null || title.isEmpty ? 'Untitled Stage' : title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description == null || description.isEmpty
                  ? 'No description available.'
                  : description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (xp is num)
                  _buildInfoChip(
                    context,
                    Icons.bolt_rounded,
                    '${xp.toInt()} XP',
                  ),
                if (duration != null && duration.isNotEmpty)
                  _buildInfoChip(context, Icons.schedule_rounded, duration),
                if (difficulty != null && difficulty.isNotEmpty)
                  _buildInfoChip(context, Icons.bar_chart_rounded, difficulty),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStages(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          const Icon(Icons.layers_outlined, size: 46, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Stages Yet',
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This learning path does not have any stages yet.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to Load Roadmap',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _loadRoadmap,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
