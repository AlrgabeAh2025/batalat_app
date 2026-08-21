/// Batalat — OTP Verification Screen
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/network/api_client.dart';
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
  bool _isResending = false;
  bool _canResend = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
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

  String _errorText(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length < 6) return;
    setState(() => _isLoading = true);

    try {
      if (widget.purpose == 'reset') {
        if (!mounted) return;
        context.push(AppRoutes.resetPassword, extra: {
          'phone': widget.phone,
          'code': _otpController.text,
        });
        return;
      }

      await ref.read(authProvider.notifier).verifyOTP(
            phone: widget.phone,
            code: _otpController.text,
            purpose: widget.purpose,
          );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorText(e))),
        );
        _otpController.clear();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authProvider.notifier).resendOTP(
            phone: widget.phone,
            purpose: widget.purpose,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة إرسال رمز التحقق')),
      );
      _startCountdown();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorText(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'أدخل رمز التحقق',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'تم إرسال رمز مكون من 6 أرقام إلى\n${widget.phone}',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 40),
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
                    : Text(
                        widget.purpose == 'reset' ? 'متابعة' : 'تحقق',
                      ),
              ).animate(delay: 500.ms).fadeIn(),
              const SizedBox(height: 24),
              if (_canResend)
                TextButton(
                  onPressed: _isResending ? null : _resendOTP,
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
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
