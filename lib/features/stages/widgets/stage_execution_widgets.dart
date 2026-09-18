import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/stage_execution_model.dart';

// ─────────────────────────────────────────────
// Stage Header Widget
// ─────────────────────────────────────────────
class StageHeaderWidget extends StatelessWidget {
  final StageExecutionModel stage;

  const StageHeaderWidget({super.key, required this.stage});

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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.play_lesson_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  stage.title,
                  style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            stage.description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (stage.order != null) _buildInfoChip(Icons.format_list_numbered_rounded, 'Stage ${stage.order}'),
              if (stage.xp != null) _buildInfoChip(Icons.bolt_rounded, '${stage.xp} XP'),
              if (stage.duration.isNotEmpty) _buildInfoChip(Icons.schedule_rounded, stage.duration),
              if (stage.estimatedMinutes != null) _buildInfoChip(Icons.timer_outlined, '${stage.estimatedMinutes} min'),
              if (stage.difficulty.isNotEmpty) _buildInfoChip(Icons.bar_chart_rounded, stage.difficulty),
            ],
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
// Complete Stage Button Widget
// ─────────────────────────────────────────────
class CompleteStageButtonWidget extends StatelessWidget {
  final bool isCompleted;
  final bool isCompleting;
  final int xp;
  final VoidCallback onComplete;

  const CompleteStageButtonWidget({
    super.key,
    required this.isCompleted,
    required this.isCompleting,
    required this.xp,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      final xpText = xp > 0 ? '+$xp XP' : 'Completed';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green),
            const SizedBox(width: AppSpacing.sm),
            Text('Stage Completed', style: AppTextStyles.bodyLarge.copyWith(color: Colors.green, fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.sm),
            Text(xpText, style: AppTextStyles.bodySmall.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isCompleting ? null : onComplete,
        icon: isCompleting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.check_circle_outline_rounded),
        label: Text(isCompleting ? 'Completing...' : 'Complete Stage'),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Topics Section Widget
// ─────────────────────────────────────────────
class TopicsSectionWidget extends StatelessWidget {
  final List<String> topics;

  const TopicsSectionWidget({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();

    return SectionContainerWidget(
      title: 'Topics',
      icon: Icons.topic_rounded,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: topics.map((topic) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(topic, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Links Section & Cards Widget
// ─────────────────────────────────────────────
class LinksSectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<StageLinkModel> links;

  const LinksSectionWidget({super.key, required this.title, required this.icon, required this.links});

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();

    return SectionContainerWidget(
      title: title,
      icon: icon,
      child: Column(
        children: List.generate(links.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == links.length - 1 ? 0 : AppSpacing.sm),
            child: LinkCardWidget(link: links[index]),
          );
        }),
      ),
    );
  }
}

class LinkCardWidget extends StatelessWidget {
  final StageLinkModel link;

  const LinkCardWidget({super.key, required this.link});

  Future<void> _openUrl(BuildContext context) async {
    final cleanUrl = link.url.trim();
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This link is not valid.')));
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this link.')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open this link: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  link.title,
                  style: AppTextStyles.bodyLarge.copyWith(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (link.platform.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(link.platform, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
          if (link.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(link.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
          ],
          if (link.url.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openUrl(context),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Open Resource'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared Section Container
// ─────────────────────────────────────────────
class SectionContainerWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionContainerWidget({super.key, required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 23),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error State Widget
// ─────────────────────────────────────────────
class StageErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const StageErrorWidget({super.key, required this.errorMessage, required this.onRetry});

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
            Text('Unable to Load Stage', textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
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
