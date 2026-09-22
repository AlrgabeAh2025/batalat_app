/// Batalat — شاشة الطلبات الموحّدة (بيع + إيجار + مخصصة)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/features/equipment/models/equipment_models.dart';
import 'package:batalat_app/features/equipment/providers/equipment_provider.dart';
import 'package:batalat_app/features/orders/models/order_models.dart';
import 'package:batalat_app/features/orders/providers/orders_provider.dart';
import 'package:batalat_app/features/products/providers/customization_provider.dart';
import 'package:batalat_app/shared/widgets/status_badge.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/batalat_drawer.dart';
import 'package:batalat_app/shared/widgets/pull_to_refresh.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  /// إن وُجد يفتح تبويب معيّن: current | custom | past
  final String? initialTab;

  const OrdersScreen({super.key, this.initialTab});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static int _tabIndex(String? tab) {
    switch (tab) {
      case 'custom':
        return 1;
      case 'past':
        return 2;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _tabIndex(widget.initialTab),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(ordersProvider);
    ref.invalidate(myCustomRequestsProvider);
    ref.invalidate(myRentalsProvider);
    await awaitRefresh(() async {
      await ref.read(ordersProvider.future);
      await ref.read(myCustomRequestsProvider.future);
      await ref.read(myRentalsProvider.future);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final customAsync = ref.watch(myCustomRequestsProvider);
    final rentalsAsync = ref.watch(myRentalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: const DrawerMenuButton(),
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
          _CombinedTab(
            ordersAsync: ordersAsync,
            rentalsAsync: rentalsAsync,
            currentOnly: true,
            emptyMessage: 'لا توجد طلبات أو حجوزات حالية',
            onRefresh: _refreshAll,
          ),
          customAsync.when(
            loading: () => PullToRefresh(
              onRefresh: _refreshAll,
              alwaysScrollable: true,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => PullToRefresh(
              onRefresh: _refreshAll,
              alwaysScrollable: true,
              child: EmptyState(
                emoji: '⚠️',
                title: 'تعذر تحميل الطلبات المخصصة',
                subtitle: e.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: _refreshAll,
              ),
            ),
            data: (items) => _CustomRequestsList(
              items: items,
              onRefresh: _refreshAll,
            ),
          ),
          _CombinedTab(
            ordersAsync: ordersAsync,
            rentalsAsync: rentalsAsync,
            currentOnly: false,
            emptyMessage: 'سجل الطلبات فارغ',
            onRefresh: _refreshAll,
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

class _CombinedTab extends StatelessWidget {
  final AsyncValue<List<OrderSummary>> ordersAsync;
  final AsyncValue<List<RentalBookingItem>> rentalsAsync;
  final bool currentOnly;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const _CombinedTab({
    required this.ordersAsync,
    required this.rentalsAsync,
    required this.currentOnly,
    required this.emptyMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (ordersAsync.isLoading || rentalsAsync.isLoading) {
      return PullToRefresh(
        onRefresh: onRefresh,
        alwaysScrollable: true,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (ordersAsync.hasError && rentalsAsync.hasError) {
      return PullToRefresh(
        onRefresh: onRefresh,
        alwaysScrollable: true,
        child: EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: ordersAsync.error.toString(),
          actionLabel: 'إعادة المحاولة',
          onAction: onRefresh,
        ),
      );
    }

    final orders = (ordersAsync.valueOrNull ?? [])
        .where((o) => currentOnly ? o.isCurrent : !o.isCurrent)
        .toList();
    final rentals = (rentalsAsync.valueOrNull ?? [])
        .where((r) => currentOnly ? r.isCurrent : !r.isCurrent)
        .toList();

    final dueSoon = rentals.where((r) => r.isReturnDueSoon || r.isReturnOverdue).toList();

    if (orders.isEmpty && rentals.isEmpty) {
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
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.screenPadding,
          AppConstants.screenPadding,
          AppConstants.screenPadding,
          88,
        ),
        children: [
          if (currentOnly && dueSoon.isNotEmpty) ...[
            _ReturnReminderBanner(items: dueSoon),
            const SizedBox(height: 16),
          ],
          if (rentals.isNotEmpty) ...[
            _SectionHeader(
              title: 'حجوزات الإيجار',
              icon: Iconsax.box,
              count: rentals.length,
            ),
            const SizedBox(height: 10),
            ...rentals.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RentalOrderCard(item: r),
                )),
            if (orders.isNotEmpty) const SizedBox(height: 8),
          ],
          if (orders.isNotEmpty) ...[
            _SectionHeader(
              title: 'طلبات الشراء',
              icon: Iconsax.shopping_cart,
              count: orders.length,
            ),
            const SizedBox(height: 10),
            ...orders.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SaleOrderCard(order: e.value, index: e.key),
                )),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$count', style: AppTextStyles.labelSmall),
        ),
      ],
    );
  }
}

class _ReturnReminderBanner extends StatelessWidget {
  final List<RentalBookingItem> items;

  const _ReturnReminderBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    final overdue = items.where((e) => e.isReturnOverdue).length;
    final soon = items.length - overdue;
    final msg = overdue > 0
        ? 'لديك $overdue حجز${overdue > 1 ? 'ات' : ''} متأخر${overdue > 1 ? 'ة' : ''} عن موعد الإرجاع'
        : 'لديك $soon حجز${soon > 1 ? 'ات' : ''} يقترب موعد إرجاعها خلال 24 ساعة';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: overdue > 0
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdue > 0
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.info_circle,
            color: overdue > 0 ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: AppTextStyles.bodyMedium.copyWith(
                color: overdue > 0 ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleOrderCard extends StatelessWidget {
  final OrderSummary order;
  final int index;

  const _SaleOrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'شراء',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'طلب ${order.orderNumber}',
                    style: AppTextStyles.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(Iconsax.calendar, size: 16, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(order.dateLabel, style: AppTextStyles.bodyMedium),
                const Spacer(),
                Text(
                  '${order.itemsCount} منتجات',
                  style: AppTextStyles.bodyMedium,
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
          .animate(delay: Duration(milliseconds: 40 * index))
          .fadeIn()
          .slideX(begin: 0.08, end: 0),
    );
  }
}

class _RentalOrderCard extends StatelessWidget {
  final RentalBookingItem item;

  const _RentalOrderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy/MM/dd HH:mm');
    final alertColor = item.isReturnOverdue
        ? AppColors.error
        : item.isReturnDueSoon
            ? AppColors.primary
            : null;

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
            border: Border.all(
              color: alertColor?.withValues(alpha: 0.45) ?? AppColors.borderLight,
              width: alertColor != null ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item.thumbnail != null
                        ? CachedNetworkImage(
                            imageUrl: item.thumbnail!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            color: AppColors.primarySurface,
                            child: const Icon(
                              Iconsax.box,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'إيجار',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            StatusBadge(
                              label: item.statusDisplay.isNotEmpty
                                  ? item.statusDisplay
                                  : item.status,
                              color: AppColors.primary,
                              bgColor: AppColors.primarySurface,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item.equipmentName, style: AppTextStyles.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '#${item.bookingNumber}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'الإرجاع: ${fmt.format(item.endDate.toLocal())}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: alertColor ?? AppColors.textPrimary,
                  fontWeight:
                      alertColor != null ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (item.isReturnOverdue || item.isReturnDueSoon) ...[
                const SizedBox(height: 6),
                Text(
                  item.isReturnOverdue
                      ? 'متأخر عن موعد الإرجاع — يرجى الإرجاع فوراً'
                      : 'موعد الإرجاع خلال 24 ساعة',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: alertColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${fmt.format(item.startDate.toLocal())} →',
                    style: AppTextStyles.bodySmall,
                  ),
                  const Spacer(),
                  PriceTag(price: item.totalPrice),
                ],
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
              Text('الكمية: ${item.quantity}'),
              Text('من: ${fmt.format(item.startDate.toLocal())}'),
              Text(
                'إلى (موعد الإرجاع): ${fmt.format(item.endDate.toLocal())}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: item.isReturnOverdue
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
              if (item.isReturnOverdue || item.isReturnDueSoon) ...[
                const SizedBox(height: 10),
                Text(
                  item.isReturnOverdue
                      ? 'تنبيه: تأخر موعد الإرجاع'
                      : 'تذكير: اقترب موعد الإرجاع',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: item.isReturnOverdue
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'الإجمالي: ${item.totalPrice.toStringAsFixed(0)} ${AppConstants.currency}',
                style: AppTextStyles.titleMedium,
              ),
              if (item.productSlug.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(
                        AppRoutes.equipmentDetailPath(item.productSlug),
                      );
                    },
                    child: const Text('عرض المعدة'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
              ),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(r.dateLabel, style: AppTextStyles.bodyMedium),
                      const Spacer(),
                      if (r.latestQuote != null)
                        PriceTag(price: r.latestQuote!.amount),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
