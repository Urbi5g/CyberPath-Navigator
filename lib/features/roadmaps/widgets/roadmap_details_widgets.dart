import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../stages/stage_execution_screen.dart'; // تأكد من المسار الصحيح
import '../models/roadmap_model.dart';

// ─────────────────────────────────────────────
// Roadmap Header Widget
// ─────────────────────────────────────────────
class RoadmapHeaderWidget extends StatelessWidget {
  final RoadmapModel roadmap;

  const RoadmapHeaderWidget({super.key, required this.roadmap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: const Icon(Icons.route_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(roadmap.title, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: AppSpacing.sm),
          Text(roadmap.description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (roadmap.level.isNotEmpty) InfoChipWidget(icon: Icons.school_outlined, text: roadmap.level),
              if (roadmap.interest.isNotEmpty) InfoChipWidget(icon: Icons.work_outline_rounded, text: roadmap.interest),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stages Section Widget
// ─────────────────────────────────────────────
class StagesSectionWidget extends StatelessWidget {
  final String pathId;
  final List<StageModel> stages;

  const StagesSectionWidget({super.key, required this.pathId, required this.stages});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stages', style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${stages.length} ${stages.length == 1 ? 'Stage' : 'Stages'} in this learning path',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (stages.isEmpty)
          const EmptyStagesWidget()
        else
          Column(
            children: List.generate(stages.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == stages.length - 1 ? 0 : AppSpacing.md),
                child: StageCardWidget(
                  pathId: pathId,
                  stageNumber: index + 1,
                  stage: stages[index],
                ),
              );
            }),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Stage Card Widget
// ─────────────────────────────────────────────
class StageCardWidget extends StatelessWidget {
  final String pathId;
  final int stageNumber;
  final StageModel stage;

  const StageCardWidget({super.key, required this.pathId, required this.stageNumber, required this.stage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StageExecutionScreen(pathId: pathId, stageId: stage.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(blurRadius: 14, offset: const Offset(0, 5), color: Colors.black.withValues(alpha: 0.05)),
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
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
                  child: Text(
                    '$stageNumber',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(stage.title, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(stage.description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.45)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (stage.xp != null) InfoChipWidget(icon: Icons.bolt_rounded, text: '${stage.xp} XP'),
                if (stage.duration.isNotEmpty) InfoChipWidget(icon: Icons.schedule_rounded, text: stage.duration),
                if (stage.difficulty.isNotEmpty) InfoChipWidget(icon: Icons.bar_chart_rounded, text: stage.difficulty),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────
class InfoChipWidget extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoChipWidget({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class EmptyStagesWidget extends StatelessWidget {
  const EmptyStagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
          Text('No Stages Yet', style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: AppSpacing.sm),
          Text('This learning path does not have any stages yet.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class RoadmapErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const RoadmapErrorWidget({super.key, required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Colors.redAccent),
            const SizedBox(height: AppSpacing.md),
            Text('Unable to Load Roadmap', textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: AppSpacing.sm),
            Text(errorMessage, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}