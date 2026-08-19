/// Batalat — OTP Verification Screen
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import '../providers/auth_provider.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String phone;
  final String purpose;
  final String? fullName;

  const OTPScreen({
    super.key,
    required this.phone,
    required this.purpose,
    this.fullName,
  });

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length < 6) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).verifyOTP(
        phone: widget.phone,
        code: _otpController.text,
        purpose: widget.purpose,
      );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        _otpController.clear();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pinput Theme
    final pinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = pinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التحقق من الهاتف'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              )
              .animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text(
                'أدخل رمز التحقق',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              Text(
                'تم إرسال رمز مكون من 6 أرقام إلى\\n${widget.phone}',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 40),

              // OTP Input
              Directionality(
                textDirection: TextDirection.ltr,
                child: Pinput(
                  length: 6,
                  controller: _otpController,
                  defaultPinTheme: pinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (_) => _verifyOTP(),
                  keyboardType: TextInputType.number,
                  hapticFeedbackType: HapticFeedbackType.mediumImpact,
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3, end: 0),

              const SizedBox(height: 40),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('طھط­ظ‚ظ‚'),
              ).animate(delay: 500.ms).fadeIn(),

              const SizedBox(height: 24),

              // Resend
              if (_canResend)
                TextButton(
                  onPressed: () {
                    // ref.read(authProvider.notifier).resendOTP(...)
                    _startCountdown();
                  },
                  child: Text(
                    'إعادة إرسال الرمز',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                Text(
                  'يمكن إعادة الإرسال بعد $_countdown ثانية',
                  style: AppTextStyles.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

