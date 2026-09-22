/// شاشة توجيه — حجز الباقات يتم عبر الكتالوج والسلة
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';

class PackageBookingScreen extends StatelessWidget {
  final String? slug;
  final int? orderId;

  const PackageBookingScreen({super.key, this.slug, this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('طلب الباقة', style: AppTextStyles.headlineSmall),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(Iconsax.shop, size: 56, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'اطلب الباقة من المتجر',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'يتم طلب الباقات عبر صفحة المنتج وإضافتها إلى السلة ثم إتمام الدفع من خلال طرق الدفع المتاحة.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            BatalatButton(
              label: 'تصفح الباقات',
              onTap: () => context.go(
                '${AppRoutes.catalogPath('packages')}?title=${Uri.encodeComponent('الباقات')}',
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('العودة للرئيسية'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
