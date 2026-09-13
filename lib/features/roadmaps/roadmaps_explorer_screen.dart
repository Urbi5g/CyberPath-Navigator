import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'roadmap_details_screen.dart';

class RoadmapsExplorerScreen extends StatefulWidget {
  const RoadmapsExplorerScreen({super.key});

  @override
  State<RoadmapsExplorerScreen> createState() => _RoadmapsExplorerScreenState();
}

class _RoadmapsExplorerScreenState extends State<RoadmapsExplorerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _level;
  String? _interest;

  bool _isLoadingUser = true;
  String? _errorMessage;

  // قائمة الفلاتر وحالة الفلتر الحالي
  final List<String> _filters = ['All', 'Beginner', 'Intermediate', 'Advanced'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No authenticated user was found.');
      }

      final userDocument = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDocument.exists) {
        throw Exception('User data was not found in Firestore.');
      }

      final data = userDocument.data();

      if (data == null) {
        throw Exception('User data is empty.');
      }

      final level = data['level']?.toString().trim();
      final interest = data['interest']?.toString().trim();

      if (level == null ||
          level.isEmpty ||
          interest == null ||
          interest.isEmpty) {
        throw Exception('Your level or job role has not been completed yet.');
      }

      if (!mounted) return;

      setState(() {
        _level = level;
        _interest = interest;
        _isLoadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // دالة الاشتراك في المسار وتحديث سجل النشاطات
  Future<void> _enrollInPath(String pathId, String title) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final progressRef = _firestore.collection('user_progress').doc(user.uid);

    // تنسيق التاريخ لليوم الحالي
    final now = DateTime.now();
    final timeString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      await progressRef.set({
        'activePathways': FieldValue.arrayUnion([
          {
            'id': pathId,
            'title': title,
            'currentStage': 'Introduction',
            'progressPercent': 0.0,
          }
        ]),
        'recentActivities': FieldValue.arrayUnion([
          {
            'title': 'Enrolled in $title',
            'time': timeString,
            'icon': 'pathway',
            'color': 'success',
          }
        ])
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully enrolled! Check your profile.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enrolling: $e')),
        );
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _learningPathsStream() {
    return _firestore.collection('learning_paths').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Learning Paths',
          style: AppTextStyles.headlineMedium.copyWith(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    return RefreshIndicator(
      onRefresh: _loadUserPreferences,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'All Learning Paths',
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Explore all available cybersecurity learning paths across different levels and domains.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // شريط الفلاتر
          _buildFilterBar(theme),
          const SizedBox(height: AppSpacing.lg),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _learningPathsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildFirestoreError(context, snapshot.error.toString());
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final documents = snapshot.data?.docs ?? [];

              // تطبيق الفلتر على البيانات المسترجعة
              final filteredDocuments = documents.where((doc) {
                if (_selectedFilter == 'All') return true;
                final docLevel = doc.data()['level']?.toString().trim() ?? '';
                // مقارنة المستوى بغض النظر عن حالة الأحرف
                return docLevel.toLowerCase() == _selectedFilter.toLowerCase();
              }).toList();

              if (filteredDocuments.isEmpty) {
                return _buildEmptyState(context);
              }

              final sortedDocuments = [...filteredDocuments];

              sortedDocuments.sort((a, b) {
                final aData = a.data();
                final bData = b.data();

                final aCreatedAt = aData['createdAt'];
                final bCreatedAt = bData['createdAt'];

                if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
                  return bCreatedAt.compareTo(aCreatedAt);
                }

                return 0;
              });

              return Column(
                children: [
                  for (final document in sortedDocuments) ...[
                    _buildPathCard(context, document.id, document.data()),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ودجت شريط الفلاتر
  Widget _buildFilterBar(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : theme.dividerColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  filter,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
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

  Widget _buildHeaderCard(BuildContext context) {
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
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Your Profile Specs',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Current level and interest',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildProfileChip(context, Icons.school_rounded, _level ?? '—'),
              _buildProfileChip(
                context,
                Icons.work_outline_rounded,
                _interest ?? '—',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
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
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathCard(
      BuildContext context,
      String pathId,
      Map<String, dynamic> data,
      ) {
    final theme = Theme.of(context);

    final title = data['title']?.toString().trim();
    final description = data['description']?.toString().trim();
    final level = data['level']?.toString().trim();
    final interest = data['interest']?.toString().trim();

    final displayTitle = title == null || title.isEmpty
        ? 'Untitled Learning Path'
        : title;

    final displayDescription = description == null || description.isEmpty
        ? 'No description available.'
        : description;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            displayDescription,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
              if (level != null && level.isNotEmpty)
                _buildInfoChip(context, Icons.school_outlined, level),
              if (interest != null && interest.isNotEmpty)
                _buildInfoChip(context, Icons.work_outline_rounded, interest),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('learning_paths')
                .doc(pathId)
                .collection('stages')
                .snapshots(),
            builder: (context, snapshot) {
              final stageCount = snapshot.hasData
                  ? snapshot.data!.docs.length
                  : 0;

              return Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 19,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '$stageCount ${stageCount == 1 ? 'Stage' : 'Stages'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // الزر الجديد الذي تمت إضافته (الاشتراك)
                  OutlinedButton(
                    onPressed: () {
                      _enrollInPath(pathId, displayTitle);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Enroll'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: () {
                      _openPathDetails(context, pathId, data);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
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

  Widget _buildEmptyState(BuildContext context) {
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
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Learning Paths Found',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'There are currently no learning paths matching the selected filter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
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
              'Unable to Load Roadmaps',
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
              onPressed: _loadUserPreferences,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirestoreError(BuildContext context, String error) {
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
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Colors.redAccent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Could not load learning paths.',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _openPathDetails(
      BuildContext context,
      String pathId,
      Map<String, dynamic> data,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoadmapDetailsScreen(pathId: pathId),
      ),
    );
  }
}