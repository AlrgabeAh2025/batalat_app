/// Batalat — Order detail (from API)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/orders/models/order_models.dart';
import 'package:batalat_app/features/orders/providers/orders_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import 'package:batalat_app/shared/widgets/status_badge.dart';
import 'package:batalat_app/core/network/api_client.dart';
import 'package:dio/dio.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String? slug;
  final int? orderId;

  const OrderDetailScreen({super.key, this.slug, this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = orderId;
    if (id == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BatalatAppBar(title: 'تفاصيل الطلب'),
        body: EmptyState(emoji: '??', title: 'طلب غير موجود'),
      );
    }

    final detailAsync = ref.watch(orderDetailProvider(id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const BatalatAppBar(title: 'تفاصيل الطلب'),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '??',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(orderDetailProvider(id)),
        ),
        data: (order) => _OrderDetailBody(order: order, orderId: id),
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  final OrderDetail order;
  final int orderId;

  const _OrderDetailBody({required this.order, required this.orderId});

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  bool _cancelling = false;

  OrderDetail get order => widget.order;

  String get _paymentLabel {
    switch (order.paymentMethod) {
      case 'cod':
        return 'الدفع عند الاستلام';
      case 'card':
        return 'بطاقة';
      case 'gateway':
        return 'بوابة دفع';
      case 'transfer':
        return 'تحويل بنكي';
      case 'wallet':
        return 'المحفظة';
      default:
        return order.paymentMethod;
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('هل تريد إلغاء هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _cancelling = true);
    try {
      await ApiClient().dio.post('/orders/${widget.orderId}/cancel/');
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(ordersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء الطلب')),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.fromDioError(e).message)),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.orderNumber,
                style: AppTextStyles.headlineSmall,
              ),
            ),
            StatusBadge.fromOrderStatus(order.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          order.statusDisplay,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (order.status == 'pending') ...[
          const SizedBox(height: 16),
          BatalatButton(
            label: _cancelling ? 'جاري الإلغاء...' : 'إلغاء الطلب',
            style: BatalatButtonStyle.danger,
            onTap: _cancelling ? null : _cancel,
          ),
        ],
        const SizedBox(height: 20),
        _sectionTitle('العناصر'),
        const SizedBox(height: 8),
        ...order.items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.box, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName, style: AppTextStyles.titleSmall),
                      Text(
                        'الكمية: ${item.quantity}',
                        style: AppTextStyles.bodySmall,
                      ),
                      if (item.optionLines.isNotEmpty)
                        Text(
                          item.optionLines.join('\n'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (item.extraDetails['custom_description'] != null)
                        Text(
                          'تخصيص: ${item.extraDetails['custom_description']}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                PriceTag(price: item.totalPrice),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('التوصيل'),
        const SizedBox(height: 8),
        _infoCard([
          _infoRow('المنطقة', order.deliveryRegion),
          _infoRow('المدينة', order.deliveryCity),
          _infoRow('العنوان', order.deliveryAddressText),
          _infoRow('الدفع', _paymentLabel),
          if (order.notes.isNotEmpty) _infoRow('ملاحظات', order.notes),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('المبالغ'),
        const SizedBox(height: 8),
        _infoCard([
          _amountRow('المجموع الفرعي', order.subtotal),
          _amountRow('التوصيل', order.deliveryFee),
          if (order.discountAmount > 0)
            _amountRow('الخصم', -order.discountAmount),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي', style: AppTextStyles.titleMedium),
              PriceTag(price: order.total, large: true),
            ],
          ),
        ]),
        if (order.statusHistory.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('تتبع الحالة'),
          const SizedBox(height: 8),
          ...order.statusHistory.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.statusDisplay.isNotEmpty
                              ? event.statusDisplay
                              : event.status,
                          style: AppTextStyles.titleSmall,
                        ),
                        if (event.note.isNotEmpty)
                          Text(event.note, style: AppTextStyles.bodySmall),
                        Text(
                          _formatDate(event.createdAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: AppTextStyles.titleMedium);

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          PriceTag(price: amount.abs(), showCurrency: true),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
