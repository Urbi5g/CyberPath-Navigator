import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../home/home_screen.dart';

class ChooseJobRoleScreen extends StatefulWidget {
  final String level;

  const ChooseJobRoleScreen({super.key, required this.level});

  @override
  State<ChooseJobRoleScreen> createState() => _ChooseJobRoleScreenState();
}

class _ChooseJobRoleScreenState extends State<ChooseJobRoleScreen> {
  int? _selectedRole;
  bool _isSaving = false;

  final List<String> _roles = [
    'SOC Analyst',
    'Penetration Tester',
    'Digital Forensics',
    'Security Engineer',
    'Cloud Security',
    'Incident Responder',
  ];

  final List<String> _descriptions = [
    'Monitor, detect, and respond to security threats.',
    'Find and exploit vulnerabilities to improve security.',
    'Investigate digital evidence and security incidents.',
    'Design and maintain secure systems and infrastructure.',
    'Protect cloud environments, services, and data.',
    'Investigate and respond to cybersecurity incidents.',
  ];

  final List<IconData> _icons = [
    Icons.monitor_heart_outlined,
    Icons.bug_report_outlined,
    Icons.find_in_page_outlined,
    Icons.security_outlined,
    Icons.cloud_outlined,
    Icons.warning_amber_outlined,
  ];

  Future<void> _continue() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job role.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please log in again.'),
        ),
      );
      return;
    }

    final selectedInterest = _roles[_selectedRole!];

    setState(() {
      _isSaving = true;
    });

    try {
      // Save the user's level and selected interest.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'level': widget.level,
        'interest': selectedInterest,
      }, SetOptions(merge: true));

      // Create the user's progress document only if it does not exist.
      // This prevents existing progress from being overwritten.
      final progressRef = FirebaseFirestore.instance
          .collection('user_progress')
          .doc(user.uid);

      final progressDocument = await progressRef.get();

      if (!progressDocument.exists) {
        await progressRef.set({
          'xp': 0,
          'badges': [],
          'certificates': [],
          'activePathways': [],
          'recentActivities': [],
          'completedStages': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const students_dashboard()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save your information: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
                  Icons.work_outline,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title
              Text('Choose Your Path', style: AppTextStyles.displayMedium),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Choose the cybersecurity role you want to prepare for.',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: AppSpacing.section),

              // Question
              Text(
                'What role are you interested in?',
                style: AppTextStyles.headlineSmall,
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'You can change your path later.',
                style: AppTextStyles.bodySmall,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Roles
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _roles.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final selected = _selectedRole == index;

                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () {
                      setState(() {
                        _selectedRole = index;
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
                                  _roles[index],
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
                  onPressed: _isSaving ? null : _continue,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
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

              Center(child: Text('Step 2 of 3', style: AppTextStyles.caption)),
            ],
          ),
        ),
      ),
    );
  }
}
