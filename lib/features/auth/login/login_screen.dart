import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/home_screen.dart';
import '../register/register_screen.dart';
import '../forgot_password/forgot_password_screen.dart';
import 'widgets/login_widgets.dart'; // استدعاء ملف التصميم

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Navigate according to user role
  // ─────────────────────────────────────────────
  Future<void> _navigateAccordingToRole(User user) async {
    final userDocument = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!userDocument.exists) throw Exception('User data was not found in Firestore.');

    final userData = userDocument.data();
    if (userData == null) throw Exception('User data is empty.');

    final role = userData['role']?.toString().trim().toLowerCase();

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
      return;
    }

    if (role == 'student') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const students_dashboard()));
      return;
    }

    throw Exception('Invalid user role. Please contact the administrator.');
  }

  // ─────────────────────────────────────────────
  // Email / Password Login (مع التحقق من كلمة المرور)
  // ─────────────────────────────────────────────
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    // ✅ التحقق من أن كلمة المرور تحتوي على 8 أحرف/أرقام على الأقل
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters long.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Unable to retrieve the signed-in user.');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in successfully.')));

      await _navigateAccordingToRole(user);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Unable to sign in. Please try again.';
      switch (e.code) {
        case 'user-not-found': message = 'No account found with this email.'; break;
        case 'wrong-password':
        case 'invalid-credential': message = 'Incorrect email or password.'; break;
        case 'invalid-email': message = 'Please enter a valid email address.'; break;
        case 'user-disabled': message = 'This account has been disabled.'; break;
        case 'too-many-requests': message = 'Too many attempts. Please try again later.'; break;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────
  // Google Sign-In
  // ─────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '835106243722-huo8til5lojocko7p04fl5o2hnvb3580.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) throw Exception('Google sign-in was canceled.');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) throw Exception('Unable to retrieve the signed-in user.');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in with Google successfully.')));

      await _navigateAccordingToRole(user);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              const SizedBox(height: AppSpacing.lg),

              const LoginBrandHeader(),

              const SizedBox(height: AppSpacing.xxl),

              // حقل الإيميل
              AuthTextField(
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: AppSpacing.lg),

              // حقل الباسورد
              AuthTextField(
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                controller: _passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                onSubmitted: (_) => _login(),
              ),

              const SizedBox(height: AppSpacing.sm),

              // زر نسيت كلمة المرور
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // زر تسجيل الدخول
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sign In', style: AppTextStyles.button),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
              const AuthDivider(),
              const SizedBox(height: AppSpacing.xxl),

              // تسجيل الدخول بجوجل
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata_rounded, size: 28),
                      SizedBox(width: AppSpacing.sm),
                      Text('Continue with Google'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // إنشاء حساب جديد
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  child: const Text('Create Account'),
                ),
              ),

              const SizedBox(height: AppSpacing.section),
              const LoginFooterText(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
