/// Batalat — Package Detail Screen
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import 'package:batalat_app/shared/widgets/pull_to_refresh.dart';
import '../models/package_models.dart';
import '../providers/packages_provider.dart';

class PackageDetailScreen extends ConsumerWidget {
  final String? slug;

  const PackageDetailScreen({super.key, this.slug});

  static const _optionTypeLabels = {
    'size': 'الحجم',
    'color': 'اللون',
    'addon': 'إضافات',
  };

  Future<void> _refresh(WidgetRef ref, String packageSlug) async {
    ref.invalidate(packageDetailProvider(packageSlug));
    await awaitRefresh(() async {
      await ref.read(packageDetailProvider(packageSlug).future);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageSlug = slug ?? '';
    if (packageSlug.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          emoji: '🌹',
          title: 'باقة غير محددة',
          subtitle: 'تعذر فتح تفاصيل الباقة',
        ),
      );
    }

    final detailAsync = ref.watch(packageDetailProvider(packageSlug));

    return detailAsync.when(
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
        ),
        body: PullToRefresh(
          onRefresh: () => _refresh(ref, packageSlug),
          alwaysScrollable: true,
          child: const Padding(
            padding: EdgeInsets.all(AppConstants.screenPadding),
            child: Column(
              children: [
                LoadingShimmer(height: 280),
                SizedBox(height: 24),
                LoadingShimmer(height: 28),
                SizedBox(height: 12),
                LoadingShimmer(height: 80),
              ],
            ),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
        ),
        body: PullToRefresh(
          onRefresh: () => _refresh(ref, packageSlug),
          alwaysScrollable: true,
          child: EmptyState(
            emoji: '⚠️',
            title: 'تعذر تحميل الباقة',
            subtitle: e.toString(),
            actionLabel: 'إعادة المحاولة',
            onAction: () => _refresh(ref, packageSlug),
          ),
        ),
      ),
      data: (pkg) => _PackageDetailBody(
        package: pkg,
        onRefresh: () => _refresh(ref, packageSlug),
      ),
    );
  }
}

class _PackageDetailBody extends StatelessWidget {
  final FlowerPackageDetail package;
  final Future<void> Function() onRefresh;

  const _PackageDetailBody({
    required this.package,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.occasionIcons[package.occasion] ?? '🌹';
    final imageUrls = <String>[
      if (package.thumbnail != null) package.thumbnail!,
      ...package.images
          .where((i) => i.image != null)
          .map((i) => i.image!),
    ];
    // Deduplicate while keeping order
    final uniqueImages = <String>[];
    for (final url in imageUrls) {
      if (!uniqueImages.contains(url)) uniqueImages.add(url);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PullToRefresh(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.arrow_right_3,
                    color: AppColors.primary,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: uniqueImages.isEmpty
                  ? Container(
                      color: AppColors.primarySurface,
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 120)),
                      ),
                    )
                  : PageView.builder(
                      itemCount: uniqueImages.length,
                      itemBuilder: (_, i) {
                        return CachedNetworkImage(
                          imageUrl: uniqueImages[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.primarySurface,
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 80),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primarySurface,
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 80),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          package.name,
                          style: AppTextStyles.displaySmall,
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: PriceTag(
                          price: package.basePrice,
                          large: true,
                        ),
                      ).animate(delay: 100.ms).fadeIn().scale(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        emoji: emoji,
                        label: package.occasionDisplay ??
                            'مناسبة: ${package.occasion}',
                      ),
                      if (package.isFeatured)
                        const _Badge(emoji: '⭐', label: 'مميزة'),
                      _Badge(
                        emoji: '⏱️',
                        label: 'تحضير ${package.preparationHours} ساعة',
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 24),

                  Text('الوصف', style: AppTextStyles.titleLarge)
                      .animate(delay: 300.ms)
                      .fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    package.description.isEmpty
                        ? 'لا يوجد وصف متاح حالياً.'
                        : package.description,
                    style: AppTextStyles.bodyLarge,
                  ).animate(delay: 350.ms).fadeIn(),

                  if (package.optionsByType.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text('خيارات التخصيص', style: AppTextStyles.titleLarge)
                        .animate(delay: 400.ms)
                        .fadeIn(),
                    const SizedBox(height: 12),
                    ...package.optionsByType.entries.map((entry) {
                      final typeLabel =
                          PackageDetailScreen._optionTypeLabels[entry.key] ??
                              entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(typeLabel, style: AppTextStyles.labelLarge),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: entry.value.map((opt) {
                                final extra = opt.additionalPrice > 0
                                    ? ' (+${opt.additionalPrice.toStringAsFixed(0)} ${AppConstants.currency})'
                                    : '';
                                return Chip(
                                  label: Text('${opt.name}$extra'),
                                  backgroundColor: AppColors.primarySurface,
                                  side: BorderSide.none,
                                  labelStyle: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else if (package.options.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text('خيارات التخصيص', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    ...package.options.map((opt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.tick_circle,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                opt.additionalPrice > 0
                                    ? '${opt.name} (+${opt.additionalPrice.toStringAsFixed(0)} ${AppConstants.currency})'
                                    : opt.name,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BatalatButton(
            label: 'اطلب من المتجر',
            onTap: () => context.go(
              '${AppRoutes.catalogPath('packages')}?title=${Uri.encodeComponent('الباقات')}',
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String emoji;
  final String label;

  const _Badge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
