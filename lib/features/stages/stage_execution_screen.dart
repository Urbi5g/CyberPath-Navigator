import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class StageExecutionScreen extends StatefulWidget {
  final String pathId;
  final String stageId;

  const StageExecutionScreen({
    super.key,
    required this.pathId,
    required this.stageId,
  });

  @override
  State<StageExecutionScreen> createState() => _StageExecutionScreenState();
}

class _StageExecutionScreenState extends State<StageExecutionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _stageData;

  @override
  void initState() {
    super.initState();
    _loadStage();
  }

  Future<void> _loadStage() async {
    try {
      final stageDocument = await _firestore
          .collection('learning_paths')
          .doc(widget.pathId)
          .collection('stages')
          .doc(widget.stageId)
          .get();

      if (!stageDocument.exists) {
        throw Exception('Stage was not found.');
      }

      final data = stageDocument.data();

      if (data == null) {
        throw Exception('Stage data is empty.');
      }

      if (!mounted) return;

      setState(() {
        _stageData = data;
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
          'Stage',
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

    if (_stageData == null) {
      return const Center(child: Text('No stage data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadStage,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildStageHeader(context),
          const SizedBox(height: AppSpacing.lg),
          _buildTopicsSection(context),
          const SizedBox(height: AppSpacing.lg),
          _buildLinksSection(
            context,
            title: 'Resources',
            icon: Icons.menu_book_rounded,
            links: _readLinks(_stageData!['resources']),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildLinksSection(
            context,
            title: 'Courses',
            icon: Icons.school_rounded,
            links: _readLinks(_stageData!['courses']),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildLinksSection(
            context,
            title: 'Platforms & Labs',
            icon: Icons.computer_rounded,
            links: _readLinks(_stageData!['platforms']),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildLinksSection(
            context,
            title: 'Additional Links',
            icon: Icons.link_rounded,
            links: _readLinks(_stageData!['additionalLinks']),
          ),
        ],
      ),
    );
  }

  Widget _buildStageHeader(BuildContext context) {
    final theme = Theme.of(context);

    final title = _stageData!['title']?.toString().trim();
    final description = _stageData!['description']?.toString().trim();

    final order = _stageData!['order'];
    final xp = _stageData!['xp'];
    final duration = _stageData!['duration']?.toString().trim();
    final estimatedMinutes = _stageData!['estimatedMinutes'];
    final difficulty = _stageData!['difficulty']?.toString().trim();

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
                child: const Icon(
                  Icons.play_lesson_rounded,
                  color: AppColors.primary,
                  size: 28,
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            description == null || description.isEmpty
                ? 'No description available.'
                : description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (order is num)
                _buildInfoChip(
                  context,
                  Icons.format_list_numbered_rounded,
                  'Stage ${order.toInt()}',
                ),
              if (xp is num)
                _buildInfoChip(context, Icons.bolt_rounded, '${xp.toInt()} XP'),
              if (duration != null && duration.isNotEmpty)
                _buildInfoChip(context, Icons.schedule_rounded, duration),
              if (estimatedMinutes is num)
                _buildInfoChip(
                  context,
                  Icons.timer_outlined,
                  '${estimatedMinutes.toInt()} min',
                ),
              if (difficulty != null && difficulty.isNotEmpty)
                _buildInfoChip(context, Icons.bar_chart_rounded, difficulty),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsSection(BuildContext context) {
    final topics = _readStringList(_stageData!['topics']);

    if (topics.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return _buildSectionContainer(
      context,
      title: 'Topics',
      icon: Icons.topic_rounded,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final topic in topics)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                topic,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinksSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> links,
  }) {
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionContainer(
      context,
      title: title,
      icon: icon,
      child: Column(
        children: [
          for (int index = 0; index < links.length; index++) ...[
            _buildLinkCard(context, links[index]),
            if (index != links.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionContainer(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, Map<String, dynamic> link) {
    final theme = Theme.of(context);

    final title = link['title']?.toString().trim();
    final url = link['url']?.toString().trim();
    final platform = link['platform']?.toString().trim();
    final description = link['description']?.toString().trim();

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
              const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title == null || title.isEmpty ? 'Untitled Resource' : title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (platform != null && platform.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              platform,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (url != null && url.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openUrl(context, url),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Open Resource'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final cleanUrl = url.trim();
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This link is not valid.')));
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open this link: $e')));
    }
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _readLinks(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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
              'Unable to Load Stage',
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
              onPressed: _loadStage,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
