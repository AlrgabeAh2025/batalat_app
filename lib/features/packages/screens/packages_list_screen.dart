/// Batalat — Packages List Screen
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import '../models/package_models.dart';
import '../providers/packages_provider.dart';

class PackagesListScreen extends ConsumerWidget {
  const PackagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(packagesFilterProvider);
    final occasionsAsync = ref.watch(occasionsProvider);
    final packagesAsync = ref.watch(packagesListProvider);
    final selectedOccasion = filter.occasion ?? 'all';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const BatalatAppBar(
        title: 'باقات الورد',
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Filter Chips
          occasionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  LoadingShimmer(width: 80, height: 36),
                  SizedBox(width: 8),
                  LoadingShimmer(width: 90, height: 36),
                  SizedBox(width: 8),
                  LoadingShimmer(width: 100, height: 36),
                ],
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'تعذر تحميل الفلاتر: $e',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
            data: (occasions) {
              final chips = [
                const PackageOccasion(id: 'all', label: 'الكل'),
                ...occasions,
              ];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPadding,
                  vertical: 12,
                ),
                child: Row(
                  children: chips.map((occ) {
                    final isSelected = selectedOccasion == occ.id;
                    final emoji = occ.id == 'all'
                        ? '✨'
                        : (AppConstants.occasionIcons[occ.id] ?? '🌸');
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji),
                            const SizedBox(width: 6),
                            Text(occ.label),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            ref
                                .read(packagesFilterProvider.notifier)
                                .setOccasion(occ.id);
                          }
                        },
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primarySurface,
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(duration: 400.ms);
            },
          ),

          // Packages Grid
          Expanded(
            child: packagesAsync.when(
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const _GridCardShimmer(),
              ),
              error: (e, _) => EmptyState(
                emoji: '⚠️',
                title: 'تعذر تحميل الباقات',
                subtitle: e.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => ref.invalidate(packagesListProvider),
              ),
              data: (page) {
                if (page.results.isEmpty) {
                  return const EmptyState(
                    emoji: '🌹',
                    title: 'لا توجد باقات',
                    subtitle: 'جرّب تغيير الفلتر أو عد لاحقاً',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(packagesListProvider);
                    ref.invalidate(occasionsProvider);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: page.results.length,
                    itemBuilder: (context, index) {
                      return _PackageGridCard(
                        package: page.results[index],
                        index: index,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCardShimmer extends StatelessWidget {
  const _GridCardShimmer();

  @override
  Widget build(BuildContext context) {
    return const LoadingShimmer(
      height: double.infinity,
      borderRadius: AppConstants.radiusLarge,
    );
  }
}

class _PackageGridCard extends StatelessWidget {
  final FlowerPackage package;
  final int index;

  const _PackageGridCard({required this.package, required this.index});

  @override
  Widget build(BuildContext context) {
    final emoji = AppConstants.occasionIcons[package.occasion] ?? '🌹';

    return GestureDetector(
      onTap: () => context.push('/packages/${package.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusLarge),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (package.thumbnail != null)
                      CachedNetworkImage(
                        imageUrl: package.thumbnail!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 48)),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 48)),
                        ),
                      )
                    else
                      Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 60)),
                      ),
                    if (package.isFeatured)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('مميز', style: AppTextStyles.badge),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: PriceTag(price: package.basePrice)),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.shopping_cart,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn()
          .scale(begin: const Offset(0.95, 0.95)),
    );
  }
}
