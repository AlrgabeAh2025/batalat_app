/// Batalat — Splash Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/features/auth/providers/auth_provider.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final onboardingDone = prefs.getBool(AppConstants.onboardingKey) ?? false;

    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
      return;
    }

    final restored =
        await ref.read(authProvider.notifier).restoreSession();

    if (!mounted) return;

    if (restored) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RosePatternBackground(density: RoseDecorDensity.soft),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 16),

                Text(
                  'باتلات للأزهار والمناسبات',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 60),

                SizedBox(
                  width: 40,
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.borderLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
