import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset link sent successfully.'),
      ),
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
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                color: AppColors.textSecondary,
              ),

              const SizedBox(height: AppSpacing.section),

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_reset_outlined,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'CyberPath Navigator',
                      style: AppTextStyles.headlineLarge,
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      'Secure your account and get back on track.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.section),

              Text(
                'Forgot Password?',
                style: AppTextStyles.displayMedium,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Enter your email address and we’ll send you a link to reset your password.',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Email',
                style: AppTextStyles.labelLarge,
              ),

              const SizedBox(height: AppSpacing.sm),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendResetLink,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Send Reset Link'),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}