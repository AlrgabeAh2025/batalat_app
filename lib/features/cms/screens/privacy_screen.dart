/// Batalat — Privacy Policy Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/cms/providers/cms_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/pull_to_refresh.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(privacyProvider);
    await awaitRefresh(() async {
      await ref.read(privacyProvider.future);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyAsync = ref.watch(privacyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BatalatAppBar(title: 'سياسة الخصوصية'),
      body: PullToRefresh(
        onRefresh: () => _refresh(ref),
        alwaysScrollable: privacyAsync.hasError || privacyAsync.isLoading,
        child: privacyAsync.when(
          loading: () => const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            emoji: '⚠️',
            title: 'تعذر التحميل',
            subtitle: e.toString(),
            actionLabel: 'إعادة',
            onAction: () => _refresh(ref),
          ),
          data: (page) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}
