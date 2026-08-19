/// Batalat — Terms Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/cms/providers/cms_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(termsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BatalatAppBar(title: 'الشروط والأحكام'),
      body: termsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(termsProvider),
        ),
        data: (page) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(page.title, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                Text(
                  page.body,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
