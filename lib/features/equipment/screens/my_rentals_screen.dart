/// Batalat — My rental bookings
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import '../models/equipment_models.dart';
import '../providers/equipment_provider.dart';

class MyRentalsScreen extends ConsumerWidget {
  const MyRentalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRentalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('حجوزات الإيجار', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => ref.invalidate(myRentalsProvider),
            icon: const Icon(Iconsax.refresh, color: AppColors.primary),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(myRentalsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(myRentalsProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    emoji: '📦',
                    title: 'لا توجد حجوزات',
                    subtitle: 'عند حجز معدة ستظهر هنا',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(myRentalsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _RentalCard(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final RentalBookingItem item;

  const _RentalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy/MM/dd HH:mm');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnail!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: AppColors.primarySurface,
                        child: const Icon(Iconsax.box, color: AppColors.primary),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.equipmentName, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '#${item.bookingNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fmt.format(item.startDate.toLocal())} → ${fmt.format(item.endDate.toLocal())}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(label: item.statusDisplay),
                        const Spacer(),
                        PriceTag(price: item.totalPrice),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final fmt = DateFormat('yyyy/MM/dd HH:mm');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.equipmentName, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text('الحجز #${item.bookingNumber}'),
              const SizedBox(height: 12),
              Text('الحالة: ${item.statusDisplay}'),
              Text(
                'الوضع: ${item.pricingModeDisplay.isNotEmpty ? item.pricingModeDisplay : item.pricingMode}',
              ),
              Text('الكمية: ${item.quantity}'),
              Text('من: ${fmt.format(item.startDate.toLocal())}'),
              Text('إلى: ${fmt.format(item.endDate.toLocal())}'),
              const SizedBox(height: 12),
              Text(
                'إيجار: ${item.rentalPrice.toStringAsFixed(0)} ${AppConstants.currency}',
              ),
              Text(
                'عربون: ${item.depositAmount.toStringAsFixed(0)} ${AppConstants.currency}',
              ),
              Text(
                'توصيل: ${item.deliveryFee.toStringAsFixed(0)} ${AppConstants.currency}',
              ),
              Text(
                'الإجمالي: ${item.totalPrice.toStringAsFixed(0)} ${AppConstants.currency}',
                style: AppTextStyles.titleMedium,
              ),
              if (item.returnCondition.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'حالة الإرجاع: ${item.returnConditionDisplay}',
                ),
                if (item.damageCharge > 0)
                  Text(
                    'رسوم إضافية: ${item.damageCharge.toStringAsFixed(0)} ${AppConstants.currency}',
                  ),
                if (item.depositRefunded > 0)
                  Text(
                    'عربون مُسترجع: ${item.depositRefunded.toStringAsFixed(0)} ${AppConstants.currency}',
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}
