/// Batalat — شاشة الأقسام: شبكة الأقسام الرئيسية ثم الكتالوج مع فلاتر فرعية
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/products/models/product_models.dart';
import 'package:batalat_app/features/products/providers/products_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/category_icon_view.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/pull_to_refresh.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _openCategory(BuildContext context, ProductCategory category) {
    context.push(
      '${AppRoutes.catalogPath(category.slug)}?title=${Uri.encodeComponent(category.name)}',
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(productCategoriesProvider);
    await awaitRefresh(() async {
      await ref.read(productCategoriesProvider.future);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootsAsync = ref.watch(productCategoriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const BatalatAppBar(
        title: 'الأقسام',
        showBackButton: false,
        showMenuButton: true,
      ),
      body: PullToRefresh(
        onRefresh: () => _refresh(ref),
        child: rootsAsync.when(
          loading: () => GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppConstants.screenPadding,
              8,
              AppConstants.screenPadding,
              100,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => const LoadingShimmer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: AppConstants.radiusLarge,
            ),
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.5,
                child: EmptyState(
                  emoji: '📂',
                  title: 'تعذر تحميل الأقسام',
                  subtitle: e.toString(),
                  actionLabel: 'إعادة المحاولة',
                  onAction: () => _refresh(ref),
                ),
              ),
            ],
          ),
          data: (roots) {
            if (roots.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    emoji: '📂',
                    title: 'لا توجد أقسام بعد',
                    subtitle: 'أضف أقساماً من لوحة التحكم',
                  ),
                ],
              );
            }
            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPadding,
                8,
                AppConstants.screenPadding,
                100,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: roots.length,
              itemBuilder: (context, index) {
                final cat = roots[index];
                return _CategoryGridTile(
                  category: cat,
                  onTap: () => _openCategory(context, cat),
                )
                    .animate(delay: Duration(milliseconds: 40 * index))
                    .fadeIn()
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1, 1),
                    );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryGridTile extends StatelessWidget {
  final ProductCategory category;
  final VoidCallback onTap;

  const _CategoryGridTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        category.image != null && category.image!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: category.image!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primarySurface,
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.primarySurface,
                        AppColors.surfaceWarm,
                      ],
                    ),
                  ),
                ),
              // تدرج لقراءة النص فوق الصورة
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: hasImage ? 0.15 : 0.05),
                      Colors.black.withValues(alpha: hasImage ? 0.55 : 0.25),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CategoryIconView(
                          icon: category.icon,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      category.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.productsCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${category.productsCount} عنصر',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
