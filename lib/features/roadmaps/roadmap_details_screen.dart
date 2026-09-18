import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import 'models/roadmap_model.dart';
import 'widgets/roadmap_details_widgets.dart';

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

  RoadmapModel? _roadmap;
  List<StageModel> _stages = [];

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 1. Fetch Roadmap Details
      final pathDocument = await _firestore.collection('learning_paths').doc(widget.pathId).get();

      if (!pathDocument.exists || pathDocument.data() == null) {
        throw Exception('Learning path was not found.');
      }

      final parsedRoadmap = RoadmapModel.fromFirestore(pathDocument.id, pathDocument.data()!);

      // 2. Fetch Stages
      final stagesSnapshot = await _firestore
          .collection('learning_paths')
          .doc(widget.pathId)
          .collection('stages')
          .orderBy('order')
          .get();

      final parsedStages = stagesSnapshot.docs.map((doc) => StageModel.fromFirestore(doc)).toList();

      if (!mounted) return;

      setState(() {
        _roadmap = parsedRoadmap;
        _stages = parsedStages;
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
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Roadmap Details',
          style: AppTextStyles.headlineMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return RoadmapErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadRoadmap,
      );
    }

    if (_roadmap == null) {
      return const Center(child: Text('No roadmap data available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadRoadmap,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          RoadmapHeaderWidget(roadmap: _roadmap!),
          const SizedBox(height: AppSpacing.xl),
          StagesSectionWidget(pathId: widget.pathId, stages: _stages),
        ],
      ),
    );
  }
}