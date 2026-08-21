/// Batalat — My customization requests + quote accept/decline
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/cart/providers/cart_provider.dart';
import 'package:batalat_app/features/products/providers/customization_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';
import 'package:batalat_app/shared/widgets/status_badge.dart';

class CustomRequestsScreen extends ConsumerWidget {
  const CustomRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCustomRequestsProvider);

    return RoseDecorScaffold(
      density: RoseDecorDensity.rich,
      appBar: BatalatAppBar(
        title: 'طلباتي المخصصة',
        actions: [
          IconButton(
            tooltip: 'طلب جديد',
            onPressed: () => context.push(AppRoutes.customRequestNew),
            icon: const Icon(Iconsax.add, color: AppColors.primary),
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
          onAction: () => ref.invalidate(myCustomRequestsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              emoji: '✏️',
              title: 'لا توجد طلبات مخصصة',
              subtitle: 'أرسل وصفاً وصورة لما تحتاجه وسنرد بعرض سعر',
              actionLabel: 'طلب مخصص جديد',
              onAction: () => context.push(AppRoutes.customRequestNew),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(myCustomRequestsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final r = items[i];
                return InkWell(
                  onTap: () => context.push('/custom-requests/${r.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.imageUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: r.imageUrls.first,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.edit,
                              color: AppColors.primary,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.displayTitle,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                  ),
                                  Text(
                                    r.statusDisplay.isNotEmpty
                                        ? r.statusDisplay
                                        : r.status,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium,
                              ),
                              if (r.latestQuote != null) ...[
                                const SizedBox(height: 8),
                                PriceTag(price: r.latestQuote!.amount),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.customRequestNew),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: const Text('طلب جديد'),
      ),
    );
  }
}

class CustomRequestDetailScreen extends ConsumerWidget {
  final int requestId;

  const CustomRequestDetailScreen({super.key, required this.requestId});

  Future<void> _accept(BuildContext context, WidgetRef ref, int quoteId) async {
    try {
      final res = await ApiClient()
          .dio
          .post('/products/custom-quotes/$quoteId/accept/');
      final cart = res.data['cart_item'] as Map?;
      if (cart != null) {
        final typeStr = cart['type']?.toString() ?? 'product';
        final type = switch (typeStr) {
          'package' => CartItemType.package,
          'equipment' => CartItemType.equipment,
          'custom' => CartItemType.custom,
          _ => CartItemType.product,
        };
        final unit = double.tryParse('${cart['unit_price']}') ?? 0;
        ref.read(cartProvider.notifier).addItem(
              type: type,
              itemId: cart['item_id'] as int? ?? 0,
              slug: cart['slug']?.toString() ?? '',
              name: cart['name']?.toString() ?? '',
              unitPrice: unit,
              thumbnail: cart['thumbnail']?.toString(),
              extra: Map<String, dynamic>.from(
                (cart['extra'] as Map?) ?? {},
              ),
            );
      }
      ref.invalidate(customRequestDetailProvider(requestId));
      ref.invalidate(myCustomRequestsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة العرض إلى السلة')),
      );
      context.push('/cart');
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.fromDioError(e).message)),
      );
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, int quoteId) async {
    try {
      await ApiClient().dio.post('/products/custom-quotes/$quoteId/decline/');
      ref.invalidate(customRequestDetailProvider(requestId));
      ref.invalidate(myCustomRequestsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض العرض')),
      );
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.fromDioError(e).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customRequestDetailProvider(requestId));

    return RoseDecorScaffold(
      density: RoseDecorDensity.rich,
      appBar: const BatalatAppBar(title: 'تفاصيل الطلب المخصص'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () =>
              ref.invalidate(customRequestDetailProvider(requestId)),
        ),
        data: (r) {
          final quote = r.latestQuote;
          return ListView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            children: [
              Text(r.displayTitle, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 10),
              StatusBadge.fromCustomRequestStatus(
                r.status,
                statusDisplay: r.statusDisplay,
              ),
              const SizedBox(height: 8),
              Text(
                r.trackingHint,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (r.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: r.imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: r.imageUrls[i],
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('الوصف', style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              Text(r.description, style: AppTextStyles.bodyLarge),
              if (quote != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Iconsax.money, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('عرض السعر', style: AppTextStyles.titleMedium),
                          const Spacer(),
                          PriceTag(price: quote.amount, large: true),
                        ],
                      ),
                      if (quote.adminNote.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(quote.adminNote, style: AppTextStyles.bodyMedium),
                      ],
                      Text(
                        quote.statusDisplay,
                        style: AppTextStyles.labelSmall,
                      ),
                      if (quote.status == 'sent' && !quote.isExpired) ...[
                        const SizedBox(height: 16),
                        BatalatButton(
                          label: 'قبول وإضافة للسلة',
                          onTap: () => _accept(context, ref, quote.id),
                        ),
                        const SizedBox(height: 8),
                        BatalatButton(
                          label: 'رفض العرض',
                          style: BatalatButtonStyle.outline,
                          onTap: () => _decline(context, ref, quote.id),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
