import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'choose_job_role_screen.dart';

class SelfAssessmentScreen extends StatefulWidget {
  const SelfAssessmentScreen({super.key});

  @override
  State<SelfAssessmentScreen> createState() => _SelfAssessmentScreenState();
}

class _SelfAssessmentScreenState extends State<SelfAssessmentScreen> {
  int? _selectedLevel;

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  final List<String> _descriptions = [
    'I am new to cybersecurity and want to learn the fundamentals.',
    'I have some cybersecurity knowledge and practical experience.',
    'I have strong cybersecurity knowledge and hands-on experience.',
  ];

  final List<IconData> _icons = [
    Icons.school_outlined,
    Icons.trending_up_outlined,
    Icons.workspace_premium_outlined,
  ];

  void _continue() {
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your current level.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChooseJobRoleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.section),

              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.assessment_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title
              Text('Self Assessment', style: AppTextStyles.displayMedium),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Let’s find out where you are in your cybersecurity journey.',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: AppSpacing.section),

              // Question
              Text(
                'What is your current cybersecurity level?',
                style: AppTextStyles.headlineSmall,
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'Choose the option that best describes your experience.',
                style: AppTextStyles.bodySmall,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Options
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _levels.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final selected = _selectedLevel == index;

                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () {
                      setState(() {
                        _selectedLevel = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              _icons[index],
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(width: AppSpacing.lg),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _levels[index],
                                  style: AppTextStyles.headlineSmall,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _descriptions[index],
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: AppSpacing.sm),

                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.section),

              // Continue
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Continue'),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Center(child: Text('Step 1 of 3', style: AppTextStyles.caption)),
            ],
          ),
        ),
      ),
    );
  }
}
