/// Batalat — Register Screen
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/shared/widgets/batalat_logo.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';
import '../providers/auth_provider.dart';
import '../utils/phone_utils.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final phone = toLibyanE164(_phoneController.text);
      if (phone == null) {
        throw ApiException('رقم الهاتف غير صحيح');
      }
      await ref.read(authProvider.notifier).register(
            phone: phone,
            fullName: _nameController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        context.push(AppRoutes.otp, extra: {
          'phone': phone,
          'purpose': 'register',
          'full_name': _nameController.text.trim(),
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? e.message
            : e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoseDecorScaffold(
      density: RoseDecorDensity.soft,
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Center(
                  child: Column(
                    children: [
                      const BatalatLogo(size: 88)
                          .animate()
                          .fadeIn()
                          .scale(duration: 500.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 16),
                      Text(
                        'أنشئ حسابك مجاناً',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'اشترك وابدأ تجربتك مع Batalat',
                    style: AppTextStyles.bodyMedium,
                  ).animate(delay: 150.ms).fadeIn(),
                ),

                const SizedBox(height: 40),

                // Name Field
                _FieldLabel('الاسم الكامل'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'محمد أحمد العربي',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل اسمك الكامل';
                    if (v.trim().length < 3) return 'الاسم قصير جداً';
                    return null;
                  },
                ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),

                // Phone Field
                _FieldLabel('رقم الهاتف'),
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
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),

                // Password Field
                _FieldLabel('كلمة المرور'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Iconsax.lock, color: AppColors.primary),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                    if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    return null;
                  },
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),

                // Confirm Password Field
                _FieldLabel('تأكيد كلمة المرور'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Iconsax.lock_1, color: AppColors.primary),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                      icon: Icon(
                        _obscureConfirm ? Iconsax.eye_slash : Iconsax.eye,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أكد كلمة المرور';
                    if (v != _passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 36),

                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('إنشاء الحساب'),
                ).animate(delay: 500.ms).fadeIn(),

                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('لديك حساب بالفعل؟ ', style: AppTextStyles.bodyMedium),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'تسجيل الدخول',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 550.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.labelLarge);
  }
}

