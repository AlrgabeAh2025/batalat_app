/// Batalat — Empty State Widget
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'batalat_button.dart';

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 70))
            .animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 20),

            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(),
            ],

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 30),
              BatalatButton(
                label: actionLabel!,
                onTap: onAction,
                isFullWidth: false,
              ).animate(delay: 400.ms).fadeIn(),
            ],
          ],
        ),
      ),
    );
  }
}

