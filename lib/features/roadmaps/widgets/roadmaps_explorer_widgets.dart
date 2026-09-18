import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────
// Profile Header Card
// ─────────────────────────────────────────────
class ExplorerHeaderWidget extends StatelessWidget {
  final String? level;
  final String? interest;

  const ExplorerHeaderWidget({super.key, this.level, this.interest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: theme.cardColor,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Your Profile Specs',
                  style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Current level and interest', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildProfileChip(Icons.school_rounded, level ?? '—'),
              _buildProfileChip(Icons.work_outline_rounded, interest ?? '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 2),
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Filter Bar Widget
// ─────────────────────────────────────────────
class FilterBarWidget extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const FilterBarWidget({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
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
    );
  }
}

// ─────────────────────────────────────────────
// Learning Path Card Widget
// ─────────────────────────────────────────────
class ExplorerPathCardWidget extends StatelessWidget {
  final String pathId;
  final Map<String, dynamic> data;
  final void Function(String pathId, String title) onEnroll;
  final VoidCallback onView;

  const ExplorerPathCardWidget({
    super.key,
    required this.pathId,
    required this.data,
    required this.onEnroll,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = data['title']?.toString().trim();
    final description = data['description']?.toString().trim();
    final level = data['level']?.toString().trim();
    final interest = data['interest']?.toString().trim();

    final displayTitle = title == null || title.isEmpty ? 'Untitled Learning Path' : title;
    final displayDescription = description == null || description.isEmpty ? 'No description available.' : description;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(blurRadius: 16, offset: const Offset(0, 6), color: Colors.black.withValues(alpha: 0.06)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(displayTitle, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(displayDescription, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.45)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (level != null && level.isNotEmpty) _buildInfoChip(Icons.school_outlined, level),
              if (interest != null && interest.isNotEmpty) _buildInfoChip(Icons.work_outline_rounded, interest),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('learning_paths').doc(pathId).collection('stages').snapshots(),
            builder: (context, snapshot) {
              final stageCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.layers_outlined, size: 19, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '$stageCount ${stageCount == 1 ? 'Stage' : 'Stages'}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => onEnroll(pathId, displayTitle),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: const Text('Enroll'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: onView,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: const Text('View Path'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
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

// ─────────────────────────────────────────────
// State Widgets (Empty & Error)
// ─────────────────────────────────────────────
class EmptyExplorerWidget extends StatelessWidget {
  const EmptyExplorerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: const Icon(Icons.route_outlined, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No Learning Paths Found', textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: AppSpacing.sm),
          Text('There are currently no learning paths matching the selected filter.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.45)),
        ],
      ),
    );
  }
}

class ExplorerErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ExplorerErrorWidget({super.key, required this.errorMessage, required this.onRetry});

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
            Text('Unable to Load Roadmaps', textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
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

class FirestoreErrorWidget extends StatelessWidget {
  final String error;

  const FirestoreErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.redAccent),
          const SizedBox(height: AppSpacing.md),
          Text('Could not load learning paths.', textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: AppSpacing.sm),
          Text(error, textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}