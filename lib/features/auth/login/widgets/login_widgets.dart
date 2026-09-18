import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────
// Brand Header Widget (الشعار والترحيب)
// ─────────────────────────────────────────────
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('CyberPath Navigator', style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Your journey into cybersecurity starts here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const Text('Welcome Back', style: AppTextStyles.headlineLarge),
        const SizedBox(height: AppSpacing.xs),
        const Text('Sign in to continue your journey.', style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Custom Text Field Widget (حقل إدخال مخصص)
// ─────────────────────────────────────────────
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final void Function(String)? onSubmitted;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: isPassword ? obscureText : false,
          style: AppTextStyles.bodyLarge,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: onToggleVisibility,
            )
                : null,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Divider Widget (الفاصل المرئي)
// ─────────────────────────────────────────────
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('OR', style: AppTextStyles.labelSmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Footer Text Widget (النص السفلي)
// ─────────────────────────────────────────────
class LoginFooterText extends StatelessWidget {
  const LoginFooterText({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Build your skills. Track your progress.\n'
            'Become the cybersecurity professional you want to be.',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption,
      ),
    );
  }
}