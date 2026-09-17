import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class CertificateRequestScreen extends StatefulWidget {
  // متغيرات ابتدائية اختيارية (لو أردت تمريرها وتعبئتها تلقائياً)
  final String? initialFullName;
  final String? initialPhone;
  final String? initialPathway;
  final String? initialStage;
  final String? initialCertificate;
  final String? initialPlatform;
  final String? initialLink;

  const CertificateRequestScreen({
    super.key,
    this.initialFullName,
    this.initialPhone,
    this.initialPathway,
    this.initialStage,
    this.initialCertificate,
    this.initialPlatform,
    this.initialLink,
  });

  @override
  State<CertificateRequestScreen> createState() => _CertificateRequestScreenState();
}

class _CertificateRequestScreenState extends State<CertificateRequestScreen> {
  // مفتاح النموذج للتحقق من صحة الحقول
  final _formKey = GlobalKey<FormState>();

  // متحكمات حقول الإدخال
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _pathwayController;
  late TextEditingController _stageController;
  late TextEditingController _certificateController;
  late TextEditingController _platformController;
  late TextEditingController _linkController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // تهيئة المتحكمات بالقيم الابتدائية إن وجدت
    _fullNameController = TextEditingController(text: widget.initialFullName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _pathwayController = TextEditingController(text: widget.initialPathway ?? '');
    _stageController = TextEditingController(text: widget.initialStage ?? '');
    _certificateController = TextEditingController(text: widget.initialCertificate ?? '');
    _platformController = TextEditingController(text: widget.initialPlatform ?? '');
    _linkController = TextEditingController(text: widget.initialLink ?? '');
  }

  @override
  void dispose() {
    // تنظيف الذاكرة
    _fullNameController.dispose();
    _phoneController.dispose();
    _pathwayController.dispose();
    _stageController.dispose();
    _certificateController.dispose();
    _platformController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ✅ التعديل تم هنا لربط الإرسال بقاعدة البيانات
  void _submitRequest() async {
    // التحقق من أن جميع الحقول تمت تعبئتها بشكل صحيح
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // حفظ الطلب في كولكشن جديد خاص بطلبات الشهادات
        await FirebaseFirestore.instance.collection('certificate_requests').add({
          'userId': user.uid,
          'fullName': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'pathway': _pathwayController.text.trim(),
          'stage': _stageController.text.trim(),
          'certificate': _certificateController.text.trim(),
          'platform': _platformController.text.trim(),
          'link': _linkController.text.trim(),
          'status': 'قيد المراجعة', // الحالة الافتراضية
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب الشهادة بنجاح! ستتم مراجعته قريباً.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); // العودة للصفحة السابقة بعد النجاح

    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال الطلب: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // دالة مساعدة لإنشاء حقول الإدخال بشكل موحد وجميل
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color textSecondaryColor,
    required Color borderColor,
    bool isUrl = false,
    bool isPhone = false,
  }) {
    // تحديد نوع لوحة المفاتيح بناءً على نوع الحقل
    TextInputType keyboardType = TextInputType.text;
    if (isUrl) keyboardType = TextInputType.url;
    if (isPhone) keyboardType = TextInputType.phone;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w600),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'يرجى تعبئة هذا الحقل';
          }
          if (isUrl && !Uri.parse(value).isAbsolute) {
            return 'يرجى إدخال رابط صحيح (يبدأ بـ http أو https)';
          }
          if (isPhone && value.length < 9) {
            return 'يرجى إدخال رقم هاتف صحيح';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // قراءة حالة الثيم (ليلي أو نهاري) من التطبيق
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // تحديد الألوان لتتناسب مع وضع التطبيق الحالي
    final bgColor = isDark ? AppColors.background : const Color(0xFFF4F7F9);
    final surfaceColor = isDark ? AppColors.surface : Colors.white;
    final textColor = isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final textSecondaryColor = isDark ? AppColors.textSecondary : const Color(0xFF64748B);
    final borderColor = isDark ? AppColors.border : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "طلب شهادة إتمام",
          style: AppTextStyles.headlineMedium.copyWith(color: textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Form(
          key: _formKey, // ربط النموذج
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 1. بطاقة البيانات الشخصية
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          "البيانات الشخصية",
                          style: AppTextStyles.headlineSmall.copyWith(color: textColor),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(),
                    ),

                    // حقول إدخال البيانات الشخصية
                    _buildTextField(
                      controller: _fullNameController,
                      label: "الاسم الكامل (كما سيُطبع في الشهادة)",
                      icon: Icons.badge_outlined,
                      textColor: textColor,
                      textSecondaryColor: textSecondaryColor,
                      borderColor: borderColor,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: "رقم الهاتف (للتواصل)",
                      icon: Icons.phone_outlined,
                      textColor: textColor,
                      textSecondaryColor: textSecondaryColor,
                      borderColor: borderColor,
                      isPhone: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. بطاقة حقول إدخال تفاصيل الشهادة والمسار
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_document, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          "بيانات الإنجاز",
                          style: AppTextStyles.headlineSmall.copyWith(color: textColor),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(),
                    ),

                    // حقول إدخال بيانات المسار
                    _buildTextField(
                      controller: _pathwayController,
                      label: "اسم المسار المكتمل",
                      icon: Icons.route_outlined,
                      textColor: textColor,
                      textSecondaryColor: textSecondaryColor,
                      borderColor: borderColor,
                    ),
                    _buildTextField(
                      controller: _stageController,
                      label: "اسم المرحلة المكتملة",
                      icon: Icons.layers_outlined,
                      textColor: textColor,
                      textSecondaryColor: textSecondaryColor,
                      borderColor: borderColor,
                    ),
                    _buildTextField(
                      controller: _certificateController,
                      label: "اسم الشهادة المطلوبة",
                      icon: Icons.workspace_premium_outlined,
                      textColor: textColor,
                      textSecondaryColor: textSecondaryColor,
                      borderColor: borderColor,
                    ),
                    _buildTextField(
                      controller: _platformController,
                      label: "منصة التدريب",
                      icon: Icons.laptop_chromebook_outlined,
                      textColor: textColor,
                      textSecondaryColor: textSecondaryColor,
                      borderColor: borderColor,
                    ),
                    _buildTextField(
                      controller: _linkController,
                      label: "رابط الإنجاز / حساب المنصة",
                      icon: Icons.link_rounded,
                      textColor: textColor,
                      textSecondaryColor: textSecondaryColor,
                      borderColor: borderColor,
                      isUrl: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. بطاقة الشروط والمعلومات
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          "شروط المراجعة",
                          style: AppTextStyles.headlineSmall.copyWith(color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "• يجب كتابة الاسم الكامل بدقة حيث سيتم طباعته على الشهادة.\n"
                          "• يجب تعبئة جميع حقول بيانات الإنجاز بشكل صحيح.\n"
                          "• سيتم التحقق من إنجازك من خلال الرابط المرفق.\n"
                          "• في حال وجود بيانات غير صحيحة سيتم رفض الطلب تلقائياً.",
                      style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // زر التقديم
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _submitRequest,
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    "تأكيد وتقديم الطلب",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}