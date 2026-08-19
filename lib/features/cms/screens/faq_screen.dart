/// Batalat — FAQ Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/cms/providers/cms_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqsAsync = ref.watch(faqsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BatalatAppBar(title: 'الأسئلة الشائعة'),
      body: faqsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(faqsProvider),
        ),
        data: (faqs) {
          if (faqs.isEmpty) {
            return const EmptyState(
              emoji: '❔',
              title: 'لا توجد أسئلة حالياً',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            itemCount: faqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = faqs[i];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(item.question, style: AppTextStyles.titleSmall),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(item.answer, style: AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
