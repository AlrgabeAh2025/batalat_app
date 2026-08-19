/// Batalat — Orders Screen (from API)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/features/orders/models/order_models.dart';
import 'package:batalat_app/features/orders/providers/orders_provider.dart';
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('طلباتي', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => ref.invalidate(ordersProvider),
            icon: const Icon(Iconsax.refresh, color: AppColors.primary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الحالية'),
            Tab(text: 'السابقة'),
          ],
        ),
      ),
      body: ordersAsync.when(
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
          final past = orders.where((o) => !o.isCurrent).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrdersList(
                orders: current,
                emptyMessage: 'لا توجد طلبات حالية',
                onRefresh: () async => ref.invalidate(ordersProvider),
              ),
              _OrdersList(
                orders: past,
                emptyMessage: 'سجل الطلبات فارغ',
                onRefresh: () async => ref.invalidate(ordersProvider),
              ),
            ],
          );
        },
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
