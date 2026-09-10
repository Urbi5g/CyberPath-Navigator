import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class QuizQuestionsManagementScreen extends StatefulWidget {
  final String pathId;
  final String stageId;
  final String quizId;
  final String quizTitle;

  const QuizQuestionsManagementScreen({
    super.key,
    required this.pathId,
    required this.stageId,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizQuestionsManagementScreen> createState() =>
      _QuizQuestionsManagementScreenState();
}

class _QuizQuestionsManagementScreenState
    extends State<QuizQuestionsManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _questionsRef => _firestore
      .collection('learning_paths')
      .doc(widget.pathId)
      .collection('stages')
      .doc(widget.stageId)
      .collection('quizzes')
      .doc(widget.quizId)
      .collection('questions');

  DocumentReference<Map<String, dynamic>> get _quizRef => _firestore
      .collection('learning_paths')
      .doc(widget.pathId)
      .collection('stages')
      .doc(widget.stageId)
      .collection('quizzes')
      .doc(widget.quizId);

  Future<void> _updateTotalQuestions(int count) async {
    await _quizRef.update({
      'totalQuestions': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showQuestionDialog({
    String? questionId,
    Map<String, dynamic>? existingData,
  }) async {
    final questionController = TextEditingController(
      text: existingData?['question']?.toString() ?? '',
    );

    final existingOptions = existingData?['options'] is List
        ? List<dynamic>.from(existingData!['options'] as List)
        : <dynamic>[];

    final optionControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: index < existingOptions.length
            ? existingOptions[index].toString()
            : '',
      ),
    );

    final pointsController = TextEditingController(
      text: existingData?['points']?.toString() ?? '10',
    );

    int correctAnswer = existingData?['correctAnswer'] is int
        ? existingData!['correctAnswer'] as int
        : 0;

    String? errorMessage;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveQuestion() async {
              final question = questionController.text.trim();

              final optionValues = optionControllers
                  .map((controller) => controller.text.trim())
                  .toList();

              final points = int.tryParse(pointsController.text.trim());

              if (question.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Please enter the question.';
                });
                return;
              }

              if (optionValues.length != 4 ||
                  optionValues.any((option) => option.isEmpty)) {
                setDialogState(() {
                  errorMessage = 'Please fill in all 4 options.';
                });
                return;
              }

              if (points == null || points <= 0) {
                setDialogState(() {
                  errorMessage = 'Points must be greater than 0.';
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                errorMessage = null;
              });

              try {
                final questionData = <String, dynamic>{
                  'question': question,
                  'options': optionValues,
                  'correctAnswer': correctAnswer,
                  'points': points,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (questionId == null) {
                  questionData['createdAt'] = FieldValue.serverTimestamp();

                  await _questionsRef.add(questionData);
                } else {
                  await _questionsRef.doc(questionId).update(questionData);
                }

                final questionsSnapshot = await _questionsRef.get();

                await _updateTotalQuestions(questionsSnapshot.docs.length);

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  isSaving = false;
                  errorMessage = 'Failed to save question: $e';
                });
              }
            }

            return AlertDialog(
              title: Text(
                questionId == null ? 'Add Question' : 'Edit Question',
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question', style: AppTextStyles.labelLarge),
                      const SizedBox(height: AppSpacing.xs),

                      TextField(
                        controller: questionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter the question',
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text('Answer Options', style: AppTextStyles.labelLarge),

                      const SizedBox(height: AppSpacing.sm),

                      for (int i = 0; i < 4; i++) ...[
                        Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: correctAnswer,
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value == null) return;

                                      setDialogState(() {
                                        correctAnswer = value;
                                      });
                                    },
                            ),

                            Expanded(
                              child: TextField(
                                controller: optionControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Option ${i + 1}',
                                  suffixIcon: correctAnswer == i
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        'Select the radio button beside the correct answer.',
                        style: AppTextStyles.bodySmall,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text('Question Points', style: AppTextStyles.labelLarge),

                      const SizedBox(height: AppSpacing.xs),

                      TextField(
                        controller: pointsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Example: 10',
                          prefixIcon: Icon(Icons.star_outline),
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Text(
                            errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: isSaving ? null : saveQuestion,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          questionId == null ? 'Add Question' : 'Save Changes',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    // مهم:
    // لا نعمل dispose للـ controllers هنا.
    // Flutter/Dialog قد يكون ما زال يستخدمها أثناء
    // تحديث الـ widget tree.
  }

  Future<void> _deleteQuestion(String questionId, String questionText) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Question'),
          content: Text(
            'Are you sure you want to delete this question?\n\n'
            '"$questionText"',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _questionsRef.doc(questionId).delete();

      final questionsSnapshot = await _questionsRef.get();

      await _updateTotalQuestions(questionsSnapshot.docs.length);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete question: $e')));
    }
  }

  Widget _buildQuestionCard(
    BuildContext context,
    int index,
    String questionId,
    Map<String, dynamic> data,
  ) {
    final question = data['question']?.toString() ?? '';

    final options = data['options'] is List
        ? List<String>.from(
            (data['options'] as List).map((item) => item.toString()),
          )
        : <String>[];

    final correctAnswer = data['correctAnswer'] is int
        ? data['correctAnswer'] as int
        : 0;

    final points = data['points'] is num ? (data['points'] as num).toInt() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Text(question, style: AppTextStyles.headlineSmall),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showQuestionDialog(
                      questionId: questionId,
                      existingData: data,
                    );
                  }

                  if (value == 'delete') {
                    _deleteQuestion(questionId, question);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Question')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Question'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          ...List.generate(4, (optionIndex) {
            final optionText = optionIndex < options.length
                ? options[optionIndex]
                : '';

            final isCorrect = optionIndex == correctAnswer;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withValues(alpha: 0.08)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isCorrect
                      ? Colors.green.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: isCorrect ? Colors.green : AppColors.textMuted,
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: Text(optionText, style: AppTextStyles.bodyMedium),
                  ),

                  if (isCorrect)
                    Text(
                      'Correct',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              const Icon(
                Icons.star_outline,
                size: 18,
                color: AppColors.primary,
              ),

              const SizedBox(width: AppSpacing.xs),

              Text(
                '$points XP',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(widget.quizTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ElevatedButton.icon(
              onPressed: () {
                _showQuestionDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _questionsRef.orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Failed to load questions:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data?.docs ?? [];

          if (questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No questions yet',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add the first question to this quiz.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showQuestionDialog();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final document = questions[index];

              return _buildQuestionCard(
                context,
                index,
                document.id,
                document.data(),
              );
            },
          );
        },
      ),
    );
  }
}
