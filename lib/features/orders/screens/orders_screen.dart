/// Batalat — Orders Screen (sales + custom requests tracking)
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
import 'package:batalat_app/features/orders/models/order_models.dart';
import 'package:batalat_app/features/orders/providers/orders_provider.dart';
import 'package:batalat_app/features/products/providers/customization_provider.dart';
import 'package:batalat_app/shared/widgets/status_badge.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(ordersProvider);
    ref.invalidate(myCustomRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final customAsync = ref.watch(myCustomRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('طلباتي', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            tooltip: 'طلب مخصص جديد',
            onPressed: () => context.push(AppRoutes.customRequestNew),
            icon: const Icon(Iconsax.edit, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _refreshAll,
            icon: const Icon(Iconsax.refresh, color: AppColors.primary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const [
            Tab(text: 'الحالية'),
            Tab(text: 'المخصصة'),
            Tab(text: 'السابقة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              emoji: '⚠️',
              title: 'تعذر تحميل الطلبات',
              subtitle: e.toString(),
              actionLabel: 'إعادة المحاولة',
              onAction: () => ref.invalidate(ordersProvider),
            ),
            data: (orders) {
              final current = orders.where((o) => o.isCurrent).toList();
              return _OrdersList(
                orders: current,
                emptyMessage: 'لا توجد طلبات حالية',
                onRefresh: () async => ref.invalidate(ordersProvider),
              );
            },
          ),
          customAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              emoji: '⚠️',
              title: 'تعذر تحميل الطلبات المخصصة',
              subtitle: e.toString(),
              actionLabel: 'إعادة المحاولة',
              onAction: () => ref.invalidate(myCustomRequestsProvider),
            ),
            data: (items) => _CustomRequestsList(
              items: items,
              onRefresh: () async =>
                  ref.invalidate(myCustomRequestsProvider),
            ),
          ),
          ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              emoji: '⚠️',
              title: 'تعذر تحميل الطلبات',
              subtitle: e.toString(),
              actionLabel: 'إعادة المحاولة',
              onAction: () => ref.invalidate(ordersProvider),
            ),
            data: (orders) {
              final past = orders.where((o) => !o.isCurrent).toList();
              return _OrdersList(
                orders: past,
                emptyMessage: 'سجل الطلبات فارغ',
                onRefresh: () async => ref.invalidate(ordersProvider),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.customRequestNew),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: const Text('طلب مخصص'),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderSummary> orders;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const _OrdersList({
    required this.orders,
    required this.emptyMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(emoji: '📦', title: emptyMessage),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final order = orders[index];
          return GestureDetector(
            onTap: () => context.push('/orders/${order.id}'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'رقم الطلب: ${order.orderNumber}',
                          style: AppTextStyles.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge.fromOrderStatus(order.status),
                    ],
                  ),
                  if (order.statusDisplay.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        order.statusDisplay,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Iconsax.calendar,
                            size: 16,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.dateLabel,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.box,
                            size: 16,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${order.itemsCount} منتجات',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الإجمالي:', style: AppTextStyles.titleSmall),
                      PriceTag(price: order.total, large: true),
                    ],
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn()
                .slideX(begin: 0.1, end: 0),
          );
        },
      ),
    );
  }
}

class _CustomRequestsList extends StatelessWidget {
  final List<CustomRequestInfo> items;
  final Future<void> Function() onRefresh;

  const _CustomRequestsList({
    required this.items,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(
                emoji: '✏️',
                title: 'لا توجد طلبات مخصصة',
                subtitle: 'أرسل وصفاً وصورة لما تحتاجه وسنرد بعرض سعر',
                actionLabel: 'طلب مخصص جديد',
                onAction: () => context.push(AppRoutes.customRequestNew),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.screenPadding,
          AppConstants.screenPadding,
          AppConstants.screenPadding,
          88,
        ),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final r = items[index];
          return GestureDetector(
            onTap: () => context.push('/custom-requests/${r.id}'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(
                  color: r.hasActionableQuote
                      ? AppColors.primary
                      : AppColors.borderLight,
                  width: r.hasActionableQuote ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _thumb(r),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge.fromCustomRequestStatus(
                                  r.status,
                                  statusDisplay: r.statusDisplay,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Text(
                    r.trackingHint,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: r.hasActionableQuote
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.calendar,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Text(r.dateLabel, style: AppTextStyles.bodyMedium),
                      const Spacer(),
                      if (r.latestQuote != null)
                        PriceTag(price: r.latestQuote!.amount)
                      else
                        Text(
                          '#${r.id}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                  if (r.hasActionableQuote) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.arrow_left_2,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'اضغط لقبول أو رفض العرض',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 50 * index))
                .fadeIn()
                .slideX(begin: 0.1, end: 0),
          );
        },
      ),
    );
  }

  Widget _thumb(CustomRequestInfo r) {
    if (r.imageUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: r.imageUrls.first,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Iconsax.edit, color: AppColors.primary),
    );
  }
}
