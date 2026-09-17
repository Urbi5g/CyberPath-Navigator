import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class AdminCertificateRequestsScreen extends StatefulWidget {
  const AdminCertificateRequestsScreen({super.key});

  @override
  State<AdminCertificateRequestsScreen> createState() => _AdminCertificateRequestsScreenState();
}

class _AdminCertificateRequestsScreenState extends State<AdminCertificateRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedFilter = 'الكل';
  final List<String> _filters = ['الكل', 'قيد المراجعة', 'مقبولة', 'مرفوضة'];

  // دالة تحديث حالة الطلب في قاعدة البيانات مع الرد
  Future<void> _updateRequestStatus(String docId, String newStatus, String replyMessage) async {
    try {
      await _firestore.collection('certificate_requests').doc(docId).update({
        'status': newStatus,
        'adminReply': replyMessage, // حفظ رابط الشهادة أو سبب الرفض
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث الطلب بنجاح!'),
            backgroundColor: newStatus == 'مقبولة' ? AppColors.success : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // نافذة تأكيد القبول (لإدخال رابط الشهادة)
  void _showAcceptDialog(String docId, ThemeData theme, bool isDark) {
    final TextEditingController linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text("قبول الطلب", style: AppTextStyles.headlineSmall.copyWith(color: isDark ? AppColors.textPrimary : Colors.black)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("يرجى إدخال رابط الشهادة المعتمدة لإرساله للطالب:", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: linkController,
                style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textPrimary : Colors.black),
                decoration: InputDecoration(
                  labelText: "رابط الشهادة (URL)",
                  prefixIcon: const Icon(Icons.link, color: AppColors.success),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.success), borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () {
                if (linkController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال الرابط أولاً')));
                  return;
                }
                Navigator.pop(context);
                _updateRequestStatus(docId, 'مقبولة', linkController.text.trim());
              },
              child: const Text("تأكيد القبول", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // نافذة تأكيد الرفض (لإدخال سبب الرفض)
  void _showRejectDialog(String docId, ThemeData theme, bool isDark) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.redAccent),
              const SizedBox(width: AppSpacing.sm),
              Text("رفض الطلب", style: AppTextStyles.headlineSmall.copyWith(color: isDark ? AppColors.textPrimary : Colors.black)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("يرجى توضيح سبب الرفض (سيتم إرساله للطالب):", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textPrimary : Colors.black),
                decoration: InputDecoration(
                  hintText: "مثال: لم يتم اجتياز الاختبار النهائي بنجاح...",
                  prefixIcon: const Icon(Icons.feedback_outlined, color: Colors.redAccent),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى كتابة سبب الرفض')));
                  return;
                }
                Navigator.pop(context);
                _updateRequestStatus(docId, 'مرفوضة', reasonController.text.trim());
              },
              child: const Text("تأكيد الرفض", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // تحديد لون حالة الطلب
  Color _getStatusColor(String status) {
    if (status == 'مقبولة') return AppColors.success;
    if (status == 'مرفوضة') return Colors.redAccent;
    return AppColors.warning; // قيد المراجعة
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.background : const Color(0xFFF4F7F9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "إدارة طلبات الشهادات",
          style: AppTextStyles.headlineMedium.copyWith(color: textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('certificate_requests')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ في جلب البيانات', style: AppTextStyles.bodyMedium));
                }

                final requests = snapshot.data?.docs ?? [];

                // فلترة البيانات
                final filteredRequests = requests.where((doc) {
                  if (_selectedFilter == 'الكل') return true;
                  return doc['status'] == _selectedFilter;
                }).toList();

                if (filteredRequests.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(filteredRequests[index], theme, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.12) : theme.cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : theme.dividerColor.withOpacity(0.45),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRequestCard(QueryDocumentSnapshot doc, ThemeData theme, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'قيد المراجعة';
    final statusColor = _getStatusColor(status);
    final adminReply = data['adminReply'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة: الاسم والحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(data['fullName'] ?? 'بدون اسم', style: AppTextStyles.headlineSmall.copyWith(color: isDark ? AppColors.textPrimary : Colors.black))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(status, style: AppTextStyles.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),

          // تفاصيل الطلب
          _buildInfoRow(Icons.phone, "الهاتف:", data['phone']),
          _buildInfoRow(Icons.route, "المسار:", data['pathway']),
          _buildInfoRow(Icons.layers, "المرحلة:", data['stage']),
          _buildInfoRow(Icons.workspace_premium, "الشهادة:", data['certificate']),
          _buildInfoRow(Icons.laptop_chromebook, "المنصة:", data['platform']),
          _buildInfoRow(Icons.link, "الرابط المُرفق:", data['link']),

          // عرض رد الإدارة إذا كان الطلب منتهياً
          if (status != 'قيد المراجعة' && adminReply != null && adminReply.toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status == 'مقبولة' ? "رابط الشهادة المرسل:" : "سبب الرفض:", style: AppTextStyles.bodySmall.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(adminReply.toString(), style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textPrimary : Colors.black)),
                ],
              ),
            ),
          ],

          // أزرار اتخاذ القرار (تظهر فقط إذا كان قيد المراجعة)
          if (status == 'قيد المراجعة') ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    onPressed: () => _showRejectDialog(doc.id, theme, isDark),
                    icon: const Icon(Icons.close),
                    label: const Text("رفض", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    onPressed: () => _showAcceptDialog(doc.id, theme, isDark),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("قبول وإرسال", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text("$label ", style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'غير متوفر', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.md),
          Text('لا توجد طلبات', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text('لا يوجد أي طلبات تطابق الفلتر المحدد.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}