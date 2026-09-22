/// Batalat — Main Shell with Bottom Navigation
/// الرئيسية / الأقسام / السلة / طلباتي / حسابي
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/auth/utils/auth_gate.dart';
import 'package:batalat_app/features/cart/providers/cart_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_drawer.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: mainShellScaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const BatalatDrawer(),
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

    final items = <Widget>[
      _NavItem(
        icon: Iconsax.home,
        activeIcon: Iconsax.home_25,
        label: 'الرئيسية',
        isActive: location.startsWith('/home'),
        onTap: () => context.go(AppRoutes.home),
      ),
      _NavItem(
        icon: Iconsax.category,
        activeIcon: Iconsax.category5,
        label: 'الأقسام',
        isActive: location.startsWith('/categories') ||
            location.startsWith('/catalog'),
        onTap: () => context.go(AppRoutes.categories),
      ),
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
        top: false,
        maintainBottomViewPadding: true,
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

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
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
