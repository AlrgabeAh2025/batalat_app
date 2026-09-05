/// Batalat — Main Shell with Bottom Navigation
/// ثابت: الرئيسية / السلة / طلباتي / حسابي
/// ديناميكي: أقسام من Backend (?nav=1)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/constants/category_icons.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/features/auth/utils/auth_gate.dart';
import 'package:batalat_app/features/cart/providers/cart_provider.dart';
import 'package:batalat_app/features/products/models/product_models.dart';
import 'package:batalat_app/features/products/providers/products_provider.dart';
import 'package:batalat_app/shared/widgets/category_icon_view.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RosePatternBackground(density: RoseDecorDensity.rich),
          Theme(
            data: Theme.of(context).copyWith(
              scaffoldBackgroundColor: Colors.transparent,
            ),
            child: child,
          ),
        ],
      ),
      bottomNavigationBar: const _BatalatBottomNav(),
    );
  }
}

class _BatalatBottomNav extends ConsumerWidget {
  const _BatalatBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final cartCount = ref.watch(cartCountProvider);
    final navAsync = ref.watch(navCategoriesProvider);
    final navCats = navAsync.valueOrNull ?? const <ProductCategory>[];

    final items = <Widget>[
      _NavItem(
        icon: Iconsax.home,
        activeIcon: Iconsax.home_25,
        label: 'الرئيسية',
        isActive: location.startsWith('/home'),
        onTap: () => context.go(AppRoutes.home),
      ),
      ...navCats.map((cat) {
        final route = AppRoutes.catalogPath(cat.slug);
        final active = location.startsWith(route);
        return _NavItem(
          icon: CategoryIconMapper.iconData(cat.icon, active: false),
          activeIcon: CategoryIconMapper.iconData(cat.icon, active: true),
          label: cat.name,
          categoryIcon: cat.icon,
          isActive: active,
          onTap: () => context.go(route),
        );
      }),
      _NavItem(
        icon: Iconsax.shopping_cart,
        activeIcon: Iconsax.shopping_cart5,
        label: 'السلة',
        isActive: location.startsWith('/cart'),
        badgeCount: cartCount,
        onTap: () => context.go(AppRoutes.cart),
      ),
      _NavItem(
        icon: Iconsax.receipt,
        activeIcon: Iconsax.receipt_15,
        label: 'طلباتي',
        isActive: location.startsWith('/orders'),
        onTap: () {
          if (!requireAuth(
            context,
            ref,
            returnTo: AppRoutes.orders,
            message: 'سجّل الدخول لمتابعة طلباتك',
          )) {
            return;
          }
          context.go(AppRoutes.orders);
        },
      ),
      _NavItem(
        icon: Iconsax.user,
        activeIcon: Iconsax.user5,
        label: 'حسابي',
        isActive: location.startsWith('/profile'),
        onTap: () => context.go(AppRoutes.profile),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;
  final String? categoryIcon;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
    this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppConstants.shortAnimation,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (categoryIcon != null)
                    CategoryIconView(
                      icon: categoryIcon,
                      size: 22,
                      active: isActive,
                      color: isActive ? AppColors.primary : AppColors.textHint,
                    )
                  else
                    Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.primary : AppColors.textHint,
                      size: 22,
                    ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      left: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isActive ? AppColors.primary : AppColors.textHint,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
