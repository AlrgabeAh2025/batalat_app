/// Batalat — Login Screen
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import '../providers/auth_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_logo.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final phone = '+218${_phoneController.text.trim()}';
      await ref.read(authProvider.notifier).login(
        phone: phone,
        password: _passwordController.text,
      );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo & Title
                Center(
                  child: Column(
                    children: [
                      const BatalatLogo(size: 120)
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 16),

                      Text(
                        'مرحباً بك',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                          .animate(delay: 200.ms)
                          .fadeIn()
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        'سجّل الدخول برقم هاتفك وكلمة المرور',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      )
                          .animate(delay: 300.ms)
                          .fadeIn(),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Phone Field
                Text('رقم الهاتف', style: AppTextStyles.labelLarge)
                    .animate(delay: 400.ms)
                    .fadeIn(),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أدخل رقم الهاتف';
                    if (v.length < 9) return 'رقم الهاتف غير صحيح';
                    return null;
                  },
                )
                    .animate(delay: 450.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),

                // Password Field
                Text('كلمة المرور', style: AppTextStyles.labelLarge)
                    .animate(delay: 500.ms)
                    .fadeIn(),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(
                      Iconsax.lock,
                      color: AppColors.primary,
                    ),
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
                    if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                    return null;
                  },
                )
                    .animate(delay: 550.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 32),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('تسجيل الدخول'),
                )
                    .animate(delay: 600.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Register Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ليس لديك حساب؟ ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: Text(
                          'إنشاء حساب',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(delay: 650.ms)
                    .fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
