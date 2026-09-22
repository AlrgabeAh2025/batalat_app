/// Batalat — Equipment Detail
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/features/auth/utils/auth_gate.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import 'package:batalat_app/shared/widgets/pull_to_refresh.dart';
import '../models/equipment_models.dart';
import '../providers/equipment_provider.dart';

class EquipmentDetailScreen extends ConsumerWidget {
  final String slug;

  const EquipmentDetailScreen({super.key, required this.slug});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(equipmentDetailProvider(slug));
    await awaitRefresh(() async {
      await ref.read(equipmentDetailProvider(slug).future);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(equipmentDetailProvider(slug));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: PullToRefresh(
          onRefresh: () => _refresh(ref),
          alwaysScrollable: true,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: LoadingShimmer(height: 280),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: PullToRefresh(
          onRefresh: () => _refresh(ref),
          alwaysScrollable: true,
          child: EmptyState(
            emoji: '⚠️',
            title: 'تعذر التحميل',
            subtitle: e.toString(),
            actionLabel: 'إعادة',
            onAction: () => _refresh(ref),
          ),
        ),
      ),
      data: (item) => _Body(item: item, onRefresh: () => _refresh(ref)),
    );
  }
}

class _Body extends ConsumerWidget {
  final EquipmentDetail item;
  final Future<void> Function() onRefresh;

  const _Body({required this.item, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = <String>[
      if (item.thumbnail != null) item.thumbnail!,
      ...item.images,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PullToRefresh(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_right_3, color: AppColors.primary),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(
                      color: AppColors.primarySurface,
                      child: const Icon(Iconsax.box, size: 64, color: AppColors.primary),
                    )
                  : PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.displaySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      PriceTag(price: item.displayPrice, large: true),
                      Text(item.priceLabel, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  if (item.category != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      item.category!.name,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('الوصف', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    item.description.isEmpty ? 'لا يوجد وصف' : item.description,
                    style: AppTextStyles.bodyLarge,
                  ),
                  if (item.specifications.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('المواصفات', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    Text(item.specifications, style: AppTextStyles.bodyMedium),
                  ],
                  if (item.returnPolicyText.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('سياسة الإرجاع', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    Text(item.returnPolicyText, style: AppTextStyles.bodyMedium),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'المتاح: ${item.availableQuantity} | تأمين: ${item.depositAmount.toStringAsFixed(0)} ${AppConstants.currency}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: BatalatButton(
            label: 'احجز الإيجار',
            onTap: () {
              final rentPath = '/equipment/${item.slug}/rent';
              if (!requireAuth(
                context,
                ref,
                returnTo: rentPath,
                message: 'سجّل الدخول لحجز الإيجار',
              )) {
                return;
              }
              context.push(rentPath);
            },
          ),
        ),
      ),
    );
  }
}
