import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'quiz_questions_management_screen.dart';

class QuizManagementScreen extends StatefulWidget {
  final String pathId;
  final String stageId;
  final String stageTitle;

  const QuizManagementScreen({
    super.key,
    required this.pathId,
    required this.stageId,
    required this.stageTitle,
  });

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  CollectionReference<Map<String, dynamic>> get _quizzesRef => FirebaseFirestore
      .instance
      .collection('learning_paths')
      .doc(widget.pathId)
      .collection('stages')
      .doc(widget.stageId)
      .collection('quizzes');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quiz Management'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _quizzesRef.orderBy('createdAt').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(
                theme,
                'Unable to load quizzes.\n${snapshot.error}',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final quizzes = snapshot.data?.docs ?? [];

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
                      if (quizzes.isEmpty)
                        _buildEmptyState(theme)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: quizzes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final document = quizzes[index];

                            return _buildQuizCard(
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
                'Quiz',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage quizzes for this learning stage.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.stageTitle,
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
          onPressed: _showAddQuizDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Quiz'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(
    ThemeData theme,
    Map<String, dynamic> data,
    String quizId,
  ) {
    final title = data['title']?.toString() ?? 'Untitled Quiz';
    final description = data['description']?.toString() ?? '';

    final totalQuestions = data['totalQuestions'] is num
        ? (data['totalQuestions'] as num).toInt()
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: theme.colorScheme.primary,
              size: 26,
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
                _buildInfoChip(
                  theme,
                  Icons.help_outline,
                  '$totalQuestions Questions',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditQuizDialog(quizId, data);
              } else if (value == 'delete') {
                _deleteQuiz(quizId, title);
              }
              if (value == 'questions') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizQuestionsManagementScreen(
                      pathId: widget.pathId,
                      stageId: widget.stageId,
                      quizId: quizId,
                      quizTitle: title,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit Quiz')),
              PopupMenuItem(value: 'delete', child: Text('Delete Quiz')),
              PopupMenuItem(
                value: 'questions',
                child: Text('Manage Questions'),
              ),
            ],
          ),
        ],
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

  Future<void> _showAddQuizDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _QuizEditorDialog(quizzesRef: _quizzesRef);
      },
    );
  }

  Future<void> _showEditQuizDialog(
    String quizId,
    Map<String, dynamic> data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _QuizEditorDialog(
          quizzesRef: _quizzesRef,
          quizId: quizId,
          initialData: data,
        );
      },
    );
  }

  Future<void> _deleteQuiz(String quizId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Quiz'),
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
      await _quizzesRef.doc(quizId).delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete quiz: $e')));
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 55, color: theme.disabledColor),
          const SizedBox(height: 16),
          const Text(
            'No quizzes yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add the first quiz to this stage.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.20),
            ),
          ),
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

class _QuizEditorDialog extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> quizzesRef;
  final String? quizId;
  final Map<String, dynamic>? initialData;

  const _QuizEditorDialog({
    required this.quizzesRef,
    this.quizId,
    this.initialData,
  });

  bool get isEditing => quizId != null;

  @override
  State<_QuizEditorDialog> createState() => _QuizEditorDialogState();
}

class _QuizEditorDialogState extends State<_QuizEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _saveQuiz() async {
    if (_isSaving) {
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      _showError('Please enter a quiz title.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final quizData = <String, dynamic>{
        'title': title,
        'description': description,
        'totalQuestions': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.isEditing) {
        await widget.quizzesRef.doc(widget.quizId).update(quizData);
      } else {
        quizData['createdAt'] = FieldValue.serverTimestamp();

        await widget.quizzesRef.add(quizData);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Quiz updated successfully.'
                : 'Quiz created successfully.',
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

  void _showError(String message) {
    setState(() {
      _saveError = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Quiz' : 'Add Quiz'),
      content: SizedBox(
        width: 600,
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
                  labelText: 'Quiz title',
                  hintText: 'Example: SIEM Fundamentals Quiz',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                enabled: !_isSaving,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what this quiz tests.',
                ),
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
                  await _saveQuiz();
                },
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditing ? 'Save Changes' : 'Create Quiz'),
        ),
      ],
    );
  }
}
