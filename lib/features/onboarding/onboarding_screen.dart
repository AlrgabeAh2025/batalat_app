/// Batalat — Onboarding Screen
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      emoji: '🌹',
      title: 'باقات ورد فاخرة',
      subtitle: 'اختر من مجموعتنا الواسعة من باقات الورد المصممة لكل مناسبة — أفراح، أعياد ميلاد، وأكثر',
      bgColor: Color(0xFFFCEEEE),
    ),
    _OnboardingPage(
      emoji: '🎪',
      title: 'أجّر معدات حفلتك',
      subtitle: 'كل ما تحتاجه لحفلة لا تُنسى — من الطاولات والكراسي إلى الإضاءة والديكور',
      bgColor: Color(0xFFF5EDE8),
    ),
    _OnboardingPage(
      emoji: '🚀',
      title: 'توصيل لكل ليبيا',
      subtitle: 'نوصل طلباتك إلى جميع مناطق ليبيا بسرعة وأمان حتى يصلك كل شيء في موعده',
      bgColor: Color(0xFFFAF5F0),
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'تخطي',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageWidget(page: page);
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.borderLight,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _controller.nextPage(
                          duration: AppConstants.mediumAnimation,
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    child: Text(
                      _currentPage < _pages.length - 1
                          ? 'التالي'
                          : 'ابدأ الآن',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji Container
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: page.bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          )
          .animate()
          .scale(
            begin: const Offset(0.8, 0.8),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 400.ms),

          const SizedBox(height: 40),

          Text(
            page.title,
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          )
          .animate(delay: 200.ms)
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          )
          .animate(delay: 350.ms)
          .fadeIn(duration: 500.ms),
        ],
      ),
    );
  }
}

