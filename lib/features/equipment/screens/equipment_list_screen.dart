/// Batalat — Equipment List (from API)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/constants/category_icons.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import '../models/equipment_models.dart';
import '../providers/equipment_provider.dart';

class EquipmentListScreen extends ConsumerWidget {
  const EquipmentListScreen({super.key});

  static const _grid = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.72,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(equipmentFilterProvider);
    final categoriesAsync = ref.watch(equipmentCategoriesProvider);
    final listAsync = ref.watch(equipmentListProvider);
    final selected = filter.categorySlug ?? 'all';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const BatalatAppBar(title: 'المعدات', showBackButton: false),
      body: Column(
        children: [
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingShimmer(height: 36),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'تعذر تحميل التصنيفات: $e',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
            data: (cats) {
              final chips = [
                const EquipmentCategory(id: 0, name: 'الكل', slug: 'all'),
                ...cats,
              ];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPadding,
                  vertical: 12,
                ),
                child: Row(
                  children: chips.map((cat) {
                    final isSelected = selected == cat.slug;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat.icon.isNotEmpty && cat.slug != 'all'
                              ? '${CategoryIconMapper.emoji(cat.icon)} ${cat.name}'
                              : cat.name,
                        ),
                        selected: isSelected,
                        onSelected: (v) {
                          if (v) {
                            ref
                                .read(equipmentFilterProvider.notifier)
                                .setCategory(cat.slug);
                          }
                        },
                        selectedColor: AppColors.primarySurface,
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
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
              );
            },
          ),
          Expanded(
            child: listAsync.when(
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                gridDelegate: _grid,
                itemCount: 6,
                itemBuilder: (_, __) => const LoadingShimmer(
                  height: double.infinity,
                  borderRadius: AppConstants.radiusLarge,
                ),
              ),
              error: (e, _) => EmptyState(
                emoji: '⚠️',
                title: 'تعذر تحميل المعدات',
                subtitle: e.toString(),
                actionLabel: 'إعادة',
                onAction: () => ref.invalidate(equipmentListProvider),
              ),
              data: (page) {
                if (page.results.isEmpty) {
                  return const EmptyState(
                    emoji: '🎪',
                    title: 'لا توجد معدات',
                    subtitle: 'أضف معدات من لوحة التحكم',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(equipmentListProvider);
                    ref.invalidate(equipmentCategoriesProvider);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    gridDelegate: _grid,
                    itemCount: page.results.length,
                    itemBuilder: (_, i) => _EquipCard(
                      item: page.results[i],
                      index: i,
                    ),
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

class _EquipCard extends StatelessWidget {
  final EquipmentItem item;
  final int index;

  const _EquipCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/equipment/${item.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(color: AppColors.borderLight),
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
                child: item.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnail!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (_, __, ___) =>
                            const Icon(Iconsax.box, color: AppColors.primary),
                      )
                    : const Center(
                        child: Icon(Iconsax.box, size: 40, color: AppColors.primary),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(child: PriceTag(price: item.displayPrice)),
                      Text(item.priceLabel, style: AppTextStyles.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 40 * index)).fadeIn(),
    );
  }
}
