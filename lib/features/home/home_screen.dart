/// Batalat — Home Screen (بيانات ديناميكية من /products/home/)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/features/auth/providers/auth_provider.dart';
import 'package:batalat_app/features/notifications/providers/notifications_provider.dart';
import 'package:batalat_app/features/products/models/product_models.dart';
import 'package:batalat_app/features/products/providers/products_provider.dart';
import 'package:batalat_app/shared/widgets/category_icon_view.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import 'package:batalat_app/shared/widgets/batalat_logo.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?['full_name'] ?? 'عزيزنا';
    final homeAsync = ref.watch(homeFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(homeFeedProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.warmGradient,
                      ),
                    ),
                    const RosePatternBackground(
                      density: RoseDecorDensity.soft,
                    ),
                    SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.screenPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const BatalatLogo(size: 48),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'مرحباً، 👋',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                      Text(
                                        userName,
                                        style: AppTextStyles.headlineMedium.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () =>
                                    context.push(AppRoutes.notifications),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Builder(
                                      builder: (_) {
                                        final unread = ref
                                                .watch(
                                                  unreadNotificationsCountProvider,
                                                )
                                                .valueOrNull ??
                                            0;
                                        const icon = Icon(
                                          Iconsax.notification,
                                          color: AppColors.primary,
                                          size: 22,
                                        );
                                        if (unread <= 0) return icon;
                                        return badges.Badge(
                                          badgeContent: Text(
                                            unread > 9 ? '9+' : '$unread',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                          child: icon,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.products),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Iconsax.search_normal,
                                    color: AppColors.textHint,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'ابحث في الكتالوج...',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  homeAsync.when(
                    loading: () => const Column(
                      children: [
                        LoadingShimmer(height: 160, borderRadius: 16),
                        SizedBox(height: 24),
                        LoadingShimmer(height: 100, borderRadius: 12),
                      ],
                    ),
                    error: (e, _) => Center(
                      child: TextButton(
                        onPressed: () => ref.invalidate(homeFeedProvider),
                        child: Text(
                          'تعذر تحميل الرئيسية — إعادة',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                    data: (feed) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BannerCarousel(banners: feed.banners),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'الأقسام',
                          onSeeAll: () => context.push(AppRoutes.products),
                        ),
                        const SizedBox(height: 16),
                        _CategoriesRow(categories: feed.categories),
                        const SizedBox(height: 28),
                        for (final section in feed.sections) ...[
                          _SectionHeader(
                            title: section.category.name,
                            onSeeAll: () => context.go(
                              AppRoutes.catalogPath(section.category.slug),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ProductsRow(
                            products: section.products,
                            emptyMessage:
                                'لا توجد عناصر في «${section.category.name}» بعد',
                          ),
                          const SizedBox(height: 28),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  final List<ProductCategory> banners;
  const _BannerCarousel({required this.banners});

  static const _colors = [
    AppColors.primarySurface,
    AppColors.surfaceWarm,
    Color(0xFFF0EEF8),
  ];

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        child: Text(
          'فعّل «مميز» على التصنيفات من لوحة التحكم',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: PageView.builder(
        itemCount: banners.length,
        itemBuilder: (_, index) {
          final cat = banners[index];
          final color = _colors[index % _colors.length];
          return Container(
            margin: const EdgeInsets.only(left: 4, right: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(color: AppColors.borderLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (cat.image != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.25,
                      child: CachedNetworkImage(
                        imageUrl: cat.image!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                          if (cat.image != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: cat.image!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => CategoryIconView(
                                  icon: cat.icon,
                                  size: 48,
                                  preferEmoji: true,
                                ),
                              ),
                            )
                          else
                            CategoryIconView(
                              icon: cat.icon,
                              size: 56,
                              preferEmoji: true,
                            ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cat.name,
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => context.go(
                                AppRoutes.catalogPath(cat.slug),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 36),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('اكتشف'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _CategoriesRow extends StatelessWidget {
  final List<ProductCategory> categories;
  const _CategoriesRow({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text(
        'لا توجد أقسام — أضفها من لوحة التحكم',
        style: AppTextStyles.bodyMedium,
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => context.go(AppRoutes.catalogPath(category.slug)),
            child: Container(
              width: 88,
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (category.image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: category.image!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => CategoryIconView(
                          icon: category.icon,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    CategoryIconView(
                      icon: category.icon,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: AppTextStyles.labelSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 60 * index))
                .fadeIn()
                .slideX(begin: 0.1, end: 0),
          );
        },
      ),
    );
  }
}

class _ProductsRow extends StatelessWidget {
  final List<ProductItem> products;
  final String emptyMessage;

  const _ProductsRow({
    required this.products,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(emptyMessage, style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (_, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {
              if (product.isEquipment) {
                context.push(AppRoutes.equipmentDetailPath(product.slug));
              } else {
                context.push('${AppRoutes.products}/${product.slug}');
              }
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(left: 12, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppConstants.radiusLarge),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.thumbnail != null
                        ? CachedNetworkImage(
                            imageUrl: product.thumbnail!,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child:
                                  Icon(Iconsax.box, color: AppColors.primary),
                            ),
                          )
                        : const Center(
                            child: Icon(Iconsax.box,
                                size: 40, color: AppColors.primary),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        PriceTag(
                          price: product.price,
                          comparePrice: product.comparePrice,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 80 * index))
                .fadeIn()
                .slideX(begin: 0.15, end: 0),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'عرض الكل',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
