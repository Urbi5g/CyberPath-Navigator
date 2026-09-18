import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/stage_progress_model.dart';

// ─────────────────────────────────────────────
// Filter Bar Widget
// ─────────────────────────────────────────────
class ProgressFilterBarWidget extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const ProgressFilterBarWidget({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onFilterChanged(filter),
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
}

// ─────────────────────────────────────────────
// Stage Card Widget
// ─────────────────────────────────────────────
class ProgressStageCardWidget extends StatelessWidget {
  final StageProgressModel stage;
  final VoidCallback onPathTap;

  const ProgressStageCardWidget({
    super.key,
    required this.stage,
    required this.onPathTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isCompleted = stage.isCompleted;

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
                  stage.stageTitle,
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
                child: Text('+${stage.xp} XP', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: onPathTap,
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
                    'مسار: ${stage.pathTitle}',
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
}

// ─────────────────────────────────────────────
// Empty State Widget
// ─────────────────────────────────────────────
class ProgressEmptyStateWidget extends StatelessWidget {
  const ProgressEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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