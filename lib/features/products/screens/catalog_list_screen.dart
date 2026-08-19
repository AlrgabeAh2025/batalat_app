/// Batalat — Catalog list for a root category (from Backend nav)
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
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import 'package:batalat_app/core/constants/category_icons.dart';
import '../models/product_models.dart';
import '../providers/products_provider.dart';

class CatalogListScreen extends ConsumerStatefulWidget {
  final String rootSlug;
  final String? title;

  const CatalogListScreen({
    super.key,
    required this.rootSlug,
    this.title,
  });

  @override
  ConsumerState<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends ConsumerState<CatalogListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(catalogFilterProvider(widget.rootSlug));
    final childrenAsync =
        ref.watch(categoryChildrenProvider(widget.rootSlug));
    final productsAsync =
        ref.watch(catalogProductsProvider(widget.rootSlug));
    final selected = filter.categorySlug ?? widget.rootSlug;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: BatalatAppBar(title: widget.title ?? widget.rootSlug),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث...',
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                suffixIcon: filter.search != null
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(
                                  catalogFilterProvider(widget.rootSlug)
                                      .notifier)
                              .setSearch(null);
                        },
                      )
                    : null,
              ),
              onSubmitted: (q) {
                ref
                    .read(catalogFilterProvider(widget.rootSlug).notifier)
                    .setSearch(q);
              },
            ),
          ),
          childrenAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  LoadingShimmer(width: 80, height: 36),
                  SizedBox(width: 8),
                  LoadingShimmer(width: 90, height: 36),
                ],
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (children) {
              final chips = <ProductCategory>[
                ProductCategory(
                  id: 0,
                  name: 'الكل',
                  slug: widget.rootSlug,
                ),
                ...children,
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
                          cat.id != 0 && cat.icon.isNotEmpty
                              ? '${CategoryIconMapper.emoji(cat.icon)} ${cat.name}'
                              : cat.name,
                        ),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            ref
                                .read(catalogFilterProvider(widget.rootSlug)
                                    .notifier)
                                .setCategory(cat.slug);
                          }
                        },
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primarySurface,
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
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
            child: productsAsync.when(
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 4,
                itemBuilder: (_, __) =>
                    const LoadingShimmer(borderRadius: 16),
              ),
              error: (e, _) => Center(
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(catalogProductsProvider(widget.rootSlug)),
                  child: Text(
                    'تعذر التحميل — إعادة',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              data: (page) {
                if (page.results.isEmpty) {
                  return EmptyState(
                    emoji: '📦',
                    title: 'لا توجد عناصر',
                    subtitle: 'لا توجد منتجات في هذا القسم بعد',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(catalogProductsProvider(widget.rootSlug));
                    ref.invalidate(categoryChildrenProvider(widget.rootSlug));
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: page.results.length,
                    itemBuilder: (_, index) {
                      final product = page.results[index];
                      return _CatalogCard(product: product, index: index);
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

class _CatalogCard extends StatelessWidget {
  final ProductItem product;
  final int index;

  const _CatalogCard({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (product.isEquipment) {
          context.push(AppRoutes.equipmentDetailPath(product.slug));
        } else {
          context.push('${AppRoutes.products}/${product.slug}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: AppColors.primarySurface,
                child: product.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: product.thumbnail!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Iconsax.box,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Iconsax.box, color: AppColors.primary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    PriceTag(
                      price: product.price,
                      comparePrice: product.comparePrice,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 40 * index))
          .fadeIn()
          .slideY(begin: 0.05, end: 0),
    );
  }
}
