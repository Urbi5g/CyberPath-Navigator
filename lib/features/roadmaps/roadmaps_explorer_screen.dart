import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import 'roadmap_details_screen.dart';
import 'widgets/roadmaps_explorer_widgets.dart';

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
      if (user == null) throw Exception('No authenticated user was found.');

      final userDocument = await _firestore.collection('users').doc(user.uid).get();
      if (!userDocument.exists) throw Exception('User data was not found in Firestore.');

      final data = userDocument.data();
      if (data == null) throw Exception('User data is empty.');

      final level = data['level']?.toString().trim();
      final interest = data['interest']?.toString().trim();

      if (level == null || level.isEmpty || interest == null || interest.isEmpty) {
        throw Exception('Your level or job role has not been completed yet.');
      }

      if (!mounted) return;

      setState(() {
        _level = level;
        _interest = interest;
        _isLoadingUser = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _enrollInPath(String pathId, String title) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final progressRef = _firestore.collection('user_progress').doc(user.uid);
    final now = DateTime.now();
    final timeString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      await progressRef.set({
        'activePathways': FieldValue.arrayUnion([{
          'id': pathId,
          'title': title,
          'currentStage': 'Introduction',
          'progressPercent': 0.0,
        }]),
        'recentActivities': FieldValue.arrayUnion([{
          'title': 'Enrolled in $title',
          'time': timeString,
          'icon': 'pathway',
          'color': 'success',
        }])
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

  void _openPathDetails(String pathId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RoadmapDetailsScreen(pathId: pathId)),
    );
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
          style: AppTextStyles.headlineMedium.copyWith(color: theme.textTheme.bodyLarge?.color),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoadingUser) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return ExplorerErrorWidget(errorMessage: _errorMessage!, onRetry: _loadUserPreferences);
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadUserPreferences,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ExplorerHeaderWidget(level: _level, interest: _interest),
          const SizedBox(height: AppSpacing.lg),
          Text('All Learning Paths', style: AppTextStyles.headlineSmall.copyWith(color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Explore all available cybersecurity learning paths across different levels and domains.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilterBarWidget(
            filters: _filters,
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: AppSpacing.lg),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('learning_paths').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return FirestoreErrorWidget(error: snapshot.error.toString());
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()));
              }

              final documents = snapshot.data?.docs ?? [];
              final filteredDocuments = documents.where((doc) {
                if (_selectedFilter == 'All') return true;
                final docLevel = doc.data()['level']?.toString().trim() ?? '';
                return docLevel.toLowerCase() == _selectedFilter.toLowerCase();
              }).toList();

              if (filteredDocuments.isEmpty) return const EmptyExplorerWidget();

              filteredDocuments.sort((a, b) {
                final aData = a.data();
                final bData = b.data();
                if (aData['createdAt'] is Timestamp && bData['createdAt'] is Timestamp) {
                  return (bData['createdAt'] as Timestamp).compareTo(aData['createdAt'] as Timestamp);
                }
                return 0;
              });

              return Column(
                children: filteredDocuments.map((document) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ExplorerPathCardWidget(
                      pathId: document.id,
                      data: document.data(),
                      onEnroll: _enrollInPath,
                      onView: () => _openPathDetails(document.id),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}