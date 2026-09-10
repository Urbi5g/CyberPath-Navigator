import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'quiz_management_screen.dart';

class StageManagementScreen extends StatefulWidget {
  final String pathId;
  final String pathTitle;

  const StageManagementScreen({
    super.key,
    required this.pathId,
    required this.pathTitle,
  });

  @override
  State<StageManagementScreen> createState() => _StageManagementScreenState();
}

class _StageManagementScreenState extends State<StageManagementScreen> {
  CollectionReference<Map<String, dynamic>> get _stagesRef => FirebaseFirestore
      .instance
      .collection('learning_paths')
      .doc(widget.pathId)
      .collection('stages');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.pathTitle),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stagesRef.orderBy('order').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(
                theme,
                'Unable to load stages.\n${snapshot.error}',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stages = snapshot.data?.docs ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 24),
                      if (stages.isEmpty)
                        _buildEmptyState(theme)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final document = stages[index];

                            return _buildStageCard(
                              theme,
                              document.data(),
                              document.id,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stages',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage the learning stages inside this path.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.pathTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _showAddStageDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Stage'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStageCard(
    ThemeData theme,
    Map<String, dynamic> data,
    String stageId,
  ) {
    final title = data['title']?.toString() ?? 'Untitled Stage';
    final description = data['description']?.toString() ?? '';

    final order = data['order'] is num ? (data['order'] as num).toInt() : 0;

    final xp = data['xp'] is num ? (data['xp'] as num).toInt() : 0;

    final duration = data['duration']?.toString() ?? '';

    final estimatedMinutes = data['estimatedMinutes'] is num
        ? (data['estimatedMinutes'] as num).toInt()
        : 0;

    final difficulty = data['difficulty']?.toString() ?? '';

    final topics = _readStringList(data['topics']);
    final resources = _readMapList(data['resources']);
    final courses = _readMapList(data['courses']);
    final platforms = _readMapList(data['platforms']);
    final additionalLinks = _readMapList(data['additionalLinks']);

    return _buildSectionCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$order',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          theme,
                          Icons.numbers_outlined,
                          'Order $order',
                        ),
                        _buildInfoChip(theme, Icons.star_outline, '$xp XP'),
                        if (duration.isNotEmpty)
                          _buildInfoChip(
                            theme,
                            Icons.schedule_outlined,
                            duration,
                          ),
                        if (estimatedMinutes > 0)
                          _buildInfoChip(
                            theme,
                            Icons.timer_outlined,
                            '$estimatedMinutes min',
                          ),
                        if (difficulty.isNotEmpty)
                          _buildInfoChip(
                            theme,
                            Icons.signal_cellular_alt_outlined,
                            difficulty,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'More options',
                onPressed: () {
                  _showStageOptions(theme, stageId, title, data);
                },
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          if (topics.isNotEmpty ||
              resources.isNotEmpty ||
              courses.isNotEmpty ||
              platforms.isNotEmpty ||
              additionalLinks.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: theme.dividerColor.withValues(alpha: 0.20)),
            const SizedBox(height: 16),
            _buildDetailsSection(
              theme,
              topics: topics,
              resources: resources,
              courses: courses,
              platforms: platforms,
              additionalLinks: additionalLinks,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
    ThemeData theme, {
    required List<String> topics,
    required List<Map<String, dynamic>> resources,
    required List<Map<String, dynamic>> courses,
    required List<Map<String, dynamic>> platforms,
    required List<Map<String, dynamic>> additionalLinks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topics.isNotEmpty) ...[
          _buildDetailTitle(theme, Icons.topic_outlined, 'Topics'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topics.map((topic) {
              return _buildSmallChip(theme, topic);
            }).toList(),
          ),
          const SizedBox(height: 18),
        ],
        if (resources.isNotEmpty) ...[
          _buildDetailTitle(theme, Icons.menu_book_outlined, 'Resources'),
          const SizedBox(height: 8),
          ...resources.map(
            (item) => _buildLinkItem(theme, item, Icons.article_outlined),
          ),
          const SizedBox(height: 18),
        ],
        if (courses.isNotEmpty) ...[
          _buildDetailTitle(theme, Icons.school_outlined, 'Courses'),
          const SizedBox(height: 8),
          ...courses.map(
            (item) => _buildLinkItem(theme, item, Icons.school_outlined),
          ),
          const SizedBox(height: 18),
        ],
        if (platforms.isNotEmpty) ...[
          _buildDetailTitle(theme, Icons.computer_outlined, 'Platforms & Labs'),
          const SizedBox(height: 8),
          ...platforms.map(
            (item) => _buildLinkItem(theme, item, Icons.computer_outlined),
          ),
          const SizedBox(height: 18),
        ],
        if (additionalLinks.isNotEmpty) ...[
          _buildDetailTitle(theme, Icons.link_outlined, 'Additional Links'),
          const SizedBox(height: 8),
          ...additionalLinks.map(
            (item) => _buildLinkItem(theme, item, Icons.link_outlined),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailTitle(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildSmallChip(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }

  Widget _buildLinkItem(
    ThemeData theme,
    Map<String, dynamic> item,
    IconData icon,
  ) {
    final title = item['title']?.toString() ?? 'Link';
    final platform = item['platform']?.toString() ?? '';
    final url = item['url']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (platform.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    platform,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(description, style: theme.textTheme.bodySmall),
                ],
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddStageDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _StageEditorDialog(stagesRef: _stagesRef, pathId: widget.pathId);
      },
    );
  }

  Future<void> _showEditStageDialog(
    Map<String, dynamic> data,
    String stageId,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _StageEditorDialog(
          stagesRef: _stagesRef,
          pathId: widget.pathId,
          stageId: stageId,
          initialData: data,
        );
      },
    );
  }

  Future<void> _showStageOptions(
    ThemeData theme,
    String stageId,
    String title,
    Map<String, dynamic> data,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardColor,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Stage'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditStageDialog(data, stageId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz_outlined),
                title: const Text('Manage Quiz'),
                onTap: () {
                  Navigator.of(context).pop();

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizManagementScreen(
                        pathId: widget.pathId,
                        stageId: stageId,
                        stageTitle: title,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Delete Stage',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteStage(stageId, title);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteStage(String stageId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Stage'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _stagesRef.doc(stageId).delete();
      await _updateTotalStages();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stage deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete stage: $e')));
    }
  }

  Future<void> _updateTotalStages() async {
    final snapshot = await _stagesRef.get();

    await FirebaseFirestore.instance
        .collection('learning_paths')
        .doc(widget.pathId)
        .update({
          'totalStages': snapshot.size,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Widget _buildEmptyState(ThemeData theme) {
    return _buildSectionCard(
      theme,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 55,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'No stages yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add the first stage to this learning path.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.20)),
      ),
      child: child,
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildSectionCard(
          theme,
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageEditorDialog extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> stagesRef;
  final String pathId;
  final String? stageId;
  final Map<String, dynamic>? initialData;

  const _StageEditorDialog({
    required this.stagesRef,
    required this.pathId,
    this.stageId,
    this.initialData,
  });

  bool get isEditing => stageId != null;

  @override
  State<_StageEditorDialog> createState() => _StageEditorDialogState();
}

class _StageEditorDialogState extends State<_StageEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _orderController;
  late final TextEditingController _xpController;
  late final TextEditingController _durationController;
  late final TextEditingController _estimatedMinutesController;
  late final TextEditingController _topicsController;

  String _difficulty = 'Beginner';

  final List<_LinkEntry> _resources = [];
  final List<_LinkEntry> _courses = [];
  final List<_LinkEntry> _platforms = [];
  final List<_LinkEntry> _additionalLinks = [];

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;

    _titleController = TextEditingController(
      text: data?['title']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: data?['description']?.toString() ?? '',
    );

    _orderController = TextEditingController(
      text: data?['order']?.toString() ?? '',
    );

    _xpController = TextEditingController(text: data?['xp']?.toString() ?? '');

    _durationController = TextEditingController(
      text: data?['duration']?.toString() ?? '',
    );

    _estimatedMinutesController = TextEditingController(
      text: data?['estimatedMinutes']?.toString() ?? '',
    );

    _topicsController = TextEditingController(
      text: _readTopics(data?['topics']),
    );

    final storedDifficulty = data?['difficulty']?.toString();

    if (storedDifficulty != null &&
        ['Beginner', 'Intermediate', 'Advanced'].contains(storedDifficulty)) {
      _difficulty = storedDifficulty;
    }

    _loadLinks(_resources, data?['resources']);

    _loadLinks(_courses, data?['courses']);

    _loadLinks(_platforms, data?['platforms']);

    _loadLinks(_additionalLinks, data?['additionalLinks']);
  }

  String _readTopics(dynamic value) {
    if (value is! List) {
      return '';
    }

    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .join(', ');
  }

  void _loadLinks(List<_LinkEntry> target, dynamic value) {
    if (value is! List) {
      return;
    }

    for (final item in value) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);

        target.add(
          _LinkEntry(
            title: map['title']?.toString() ?? '',
            url: map['url']?.toString() ?? '',
            platform: map['platform']?.toString() ?? '',
            description: map['description']?.toString() ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    _xpController.dispose();
    _durationController.dispose();
    _estimatedMinutesController.dispose();
    _topicsController.dispose();

    super.dispose();
  }

  Future<void> _saveStage() async {
    if (_isSaving) {
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final order = int.tryParse(_orderController.text.trim());

    final xp = int.tryParse(_xpController.text.trim());

    final duration = _durationController.text.trim();

    final estimatedMinutes = int.tryParse(
      _estimatedMinutesController.text.trim(),
    );

    if (title.isEmpty) {
      _showError('Please enter a stage title.');
      return;
    }

    if (order == null || order < 1) {
      _showError('Please enter a valid stage order.');
      return;
    }

    if (xp == null || xp < 0) {
      _showError('Please enter a valid XP value.');
      return;
    }

    if (estimatedMinutes == null || estimatedMinutes < 1) {
      _showError('Please enter a valid estimated time.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final topics = _topicsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final stageData = <String, dynamic>{
        'title': title,
        'description': description,
        'order': order,
        'xp': xp,
        'duration': duration,
        'estimatedMinutes': estimatedMinutes,
        'difficulty': _difficulty,
        'topics': topics,
        'resources': _serializeLinks(_resources),
        'courses': _serializeLinks(_courses),
        'platforms': _serializeLinks(_platforms),
        'additionalLinks': _serializeLinks(_additionalLinks),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.isEditing) {
        await widget.stagesRef.doc(widget.stageId).update(stageData);
      } else {
        stageData['createdAt'] = FieldValue.serverTimestamp();

        await widget.stagesRef.add(stageData);
      }

      final stagesSnapshot = await widget.stagesRef.get();

      await FirebaseFirestore.instance
          .collection('learning_paths')
          .doc(widget.pathId)
          .update({
            'totalStages': stagesSnapshot.size,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Stage updated successfully.'
                : 'Stage created successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveError = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _serializeLinks(List<_LinkEntry> links) {
    return links
        .where(
          (item) => item.title.trim().isNotEmpty || item.url.trim().isNotEmpty,
        )
        .map(
          (item) => {
            'title': item.title.trim(),
            'url': item.url.trim(),
            'platform': item.platform.trim(),
            'description': item.description.trim(),
          },
        )
        .toList();
  }

  void _showError(String message) {
    setState(() {
      _saveError = message;
    });
  }

  Future<void> _addLink(List<_LinkEntry> target, String sectionTitle) async {
    if (_isSaving) {
      return;
    }

    final result = await showDialog<_LinkEntry>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _LinkEditorDialog(sectionTitle: sectionTitle);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      target.add(result);
    });
  }

  Future<void> _editLink(
    List<_LinkEntry> target,
    int index,
    String sectionTitle,
  ) async {
    if (_isSaving) {
      return;
    }

    final result = await showDialog<_LinkEntry>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _LinkEditorDialog(
          sectionTitle: sectionTitle,
          initialValue: target[index],
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      target[index] = result;
    });
  }

  void _removeLink(List<_LinkEntry> target, int index) {
    if (_isSaving) {
      return;
    }

    setState(() {
      target.removeAt(index);
    });
  }

  Widget _buildLinkEditorSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<_LinkEntry> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      await _addLink(items, title);
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              'No $title added yet.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          ...List.generate(items.length, (index) {
            final item = items[index];

            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.trim().isEmpty ? 'Untitled' : item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.platform.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.platform,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                        if (item.url.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: _isSaving
                        ? null
                        : () async {
                            await _editLink(items, index, title);
                          },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: _isSaving
                        ? null
                        : () {
                            _removeLink(items, index);
                          },
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Stage' : 'Add Stage'),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_saveError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _saveError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Stage title',
                  hintText: 'Example: Introduction to SIEM',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                enabled: !_isSaving,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what the student will learn.',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _orderController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Order',
                        hintText: '1',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _xpController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'XP',
                        hintText: '100',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _durationController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: '45 minutes',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _estimatedMinutesController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Minutes',
                        hintText: '45',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _difficulty,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: const [
                  DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                  DropdownMenuItem(
                    value: 'Intermediate',
                    child: Text('Intermediate'),
                  ),
                  DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _difficulty = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topicsController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Topics',
                  hintText: 'SIEM, Logs, Detection, Splunk',
                  helperText: 'Separate topics with commas.',
                ),
              ),
              const SizedBox(height: 24),
              _buildLinkEditorSection(
                Theme.of(context),
                title: 'Resources',
                icon: Icons.menu_book_outlined,
                items: _resources,
              ),
              const SizedBox(height: 20),
              _buildLinkEditorSection(
                Theme.of(context),
                title: 'Courses',
                icon: Icons.school_outlined,
                items: _courses,
              ),
              const SizedBox(height: 20),
              _buildLinkEditorSection(
                Theme.of(context),
                title: 'Platforms & Labs',
                icon: Icons.computer_outlined,
                items: _platforms,
              ),
              const SizedBox(height: 20),
              _buildLinkEditorSection(
                Theme.of(context),
                title: 'Additional Links',
                icon: Icons.link_outlined,
                items: _additionalLinks,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  await _saveStage();
                },
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditing ? 'Save Changes' : 'Create Stage'),
        ),
      ],
    );
  }
}

class _LinkEditorDialog extends StatefulWidget {
  final String sectionTitle;
  final _LinkEntry? initialValue;

  const _LinkEditorDialog({required this.sectionTitle, this.initialValue});

  @override
  State<_LinkEditorDialog> createState() => _LinkEditorDialogState();
}

class _LinkEditorDialogState extends State<_LinkEditorDialog> {
  late final TextEditingController _titleController;

  late final TextEditingController _urlController;

  late final TextEditingController _platformController;

  late final TextEditingController _descriptionController;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialValue;

    _titleController = TextEditingController(text: initial?.title ?? '');

    _urlController = TextEditingController(text: initial?.url ?? '');

    _platformController = TextEditingController(text: initial?.platform ?? '');

    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _platformController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();

    final url = _urlController.text.trim();

    final platform = _platformController.text.trim();

    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a title.';
      });
      return;
    }

    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a URL.';
      });
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _errorMessage = 'URL must start with http:// or https://';
      });
      return;
    }

    Navigator.of(context).pop(
      _LinkEntry(
        title: title,
        url: url,
        platform: platform,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.initialValue == null
            ? 'Add ${widget.sectionTitle}'
            : 'Edit ${widget.sectionTitle}',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Example: Splunk Fundamentals',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _platformController,
                decoration: const InputDecoration(
                  labelText: 'Platform',
                  hintText: 'TryHackMe / Hack The Box / Coursera',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _LinkEntry {
  String title;
  String url;
  String platform;
  String description;

  _LinkEntry({
    required this.title,
    required this.url,
    required this.platform,
    required this.description,
  });
}
