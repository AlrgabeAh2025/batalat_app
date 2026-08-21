/// Batalat — Forgot password (request OTP)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../utils/phone_utils.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = toLibyanE164(_phoneController.text);
    if (phone == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).forgotPassword(phone: phone);
      if (!mounted) return;
      context.push(AppRoutes.otp, extra: {
        'phone': phone,
        'purpose': 'reset',
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('نسيت كلمة المرور'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أدخل رقم هاتفك وسنرسل رمز تحقق لإعادة تعيين كلمة المرور',
                  style: AppTextStyles.bodyMedium,
                ).animate().fadeIn(),
                const SizedBox(height: 28),
                Text('رقم الهاتف', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '91XXXXXXX',
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🇱🇾 +218',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  validator: validateLibyanPhoneInput,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('إرسال رمز التحقق'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
