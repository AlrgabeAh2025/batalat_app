/// Batalat — Cart Screen
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/features/auth/utils/auth_gate.dart';
import 'package:batalat_app/features/cart/providers/cart_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BatalatAppBar(title: 'السلة', showBackButton: false),
        body: EmptyState(
          emoji: '🛒',
          title: 'سلتك فارغة',
          subtitle: 'تصفح المنتجات والمعدات وأضفها إلى السلة',
          actionLabel: 'تسوق الآن',
          onAction: () => context.go(AppRoutes.home),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: BatalatAppBar(
        title: 'السلة (${cart.count})',
        showBackButton: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusLarge),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: item.thumbnail != null
                              ? CachedNetworkImage(
                                  imageUrl: item.thumbnail!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: AppColors.primarySurface,
                                  child: const Icon(Iconsax.box,
                                      color: AppColors.primary),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.optionLabels.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.optionLabels.join(' · '),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            PriceTag(price: item.unitPrice),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _QtyBtn(
                                  icon: Icons.remove,
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(
                                          item.key, item.quantity - 1),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '${item.quantity}',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                ),
                                _QtyBtn(
                                  icon: Icons.add,
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(
                                          item.key, item.quantity + 1),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => ref
                                      .read(cartProvider.notifier)
                                      .removeItem(item.key),
                                  icon: const Icon(Iconsax.trash,
                                      color: AppColors.error, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المجموع الفرعي', style: AppTextStyles.bodyMedium),
                      PriceTag(price: cart.subtotal),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'رسوم التوصيل تُحسب حسب العنوان عند إتمام الشراء',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  BatalatButton(
                    label: 'إتمام الشراء',
                    onTap: () {
                      if (!requireAuth(
                        context,
                        ref,
                        returnTo: AppRoutes.checkout,
                        message: 'سجّل الدخول لإتمام الشراء',
                      )) {
                        return;
                      }
                      context.push(AppRoutes.checkout);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
