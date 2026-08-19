/// Batalat — Checkout Screen
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/features/cart/providers/cart_provider.dart';
import 'package:batalat_app/features/checkout/providers/addresses_provider.dart';
import 'package:batalat_app/features/orders/providers/orders_provider.dart';
import 'package:batalat_app/features/wallet/providers/wallet_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';

enum PaymentMethodOption { cod, card, gateway, wallet }

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int? _selectedAddressId;
  PaymentMethodOption _payment = PaymentMethodOption.cod;
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String get _paymentApi => switch (_payment) {
        PaymentMethodOption.cod => 'cod',
        PaymentMethodOption.card => 'card',
        PaymentMethodOption.gateway => 'gateway',
        PaymentMethodOption.wallet => 'wallet',
      };

  Future<void> _submit(DeliveryAddress address, double deliveryFee) async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;

    if (_payment == PaymentMethodOption.cod && !address.supportsCod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذه المنطقة لا تدعم الدفع عند الاستلام'),
        ),
      );
      return;
    }

    final total = cart.subtotal + deliveryFee;
    if (_payment == PaymentMethodOption.wallet) {
      final wallet = await ref.read(walletProvider.future);
      if (wallet.balance < total) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('رصيد المحفظة غير كافٍ'),
            action: SnackBarAction(
              label: 'شحن',
              onPressed: () => context.push(AppRoutes.wallet),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final orderRes = await ApiClient().dio.post('/orders/create/', data: {
        'items': cart.items.map((e) => e.toOrderPayload()).toList(),
        'delivery_address_id': address.id,
        'payment_method': _paymentApi,
        'notes': _notesController.text.trim(),
      });

      final orderId = orderRes.data['id'];
      final orderNumber = orderRes.data['order_number'];

      // بدء الدفع
      final payRes = await ApiClient().dio.post('/payments/initiate/', data: {
        'order_id': orderId,
        'method': _paymentApi,
      });

      ref.read(cartProvider.notifier).clear();
      ref.invalidate(ordersProvider);
      ref.invalidate(walletProvider);
      ref.invalidate(walletTransactionsProvider);

      if (!mounted) return;
      final msg = payRes.data['message']?.toString() ??
          'تم إنشاء الطلب $orderNumber بنجاح';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تم الطلب'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.orders);
              },
              child: const Text('طلباتي'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.fromDioError(e).message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressesProvider);

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: const BatalatAppBar(title: 'إتمام الشراء'),
        body: EmptyState(
          emoji: '🛒',
          title: 'السلة فارغة',
          actionLabel: 'العودة',
          onAction: () => context.go(AppRoutes.cart),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BatalatAppBar(title: 'إتمام الشراء'),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر تحميل العناوين',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(addressesProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyState(
              emoji: '📍',
              title: 'لا يوجد عنوان توصيل',
              subtitle: 'أضف عنواناً من حسابك أولاً',
              actionLabel: 'إضافة عنوان',
              onAction: () => context.push(AppRoutes.addresses),
            );
          }

          final defaults = addresses.where((a) => a.isDefault);
          final effectiveAddressId = _selectedAddressId ??
              (defaults.isNotEmpty ? defaults.first : addresses.first).id;
          if (_selectedAddressId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedAddressId = effectiveAddressId);
            });
          }
          final selected = addresses.firstWhere(
            (a) => a.id == effectiveAddressId,
            orElse: () => addresses.first,
          );
          final deliveryFee = selected.deliveryFee;
          final total = cart.subtotal + deliveryFee;

          // ضبط COD إذا غير مدعوم
          if (_payment == PaymentMethodOption.cod && !selected.supportsCod) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _payment = PaymentMethodOption.card);
              }
            });
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.screenPadding),
                  children: [
                    Text('عنوان التوصيل', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    ...addresses.map((addr) {
                      final selectedAddr = addr.id == effectiveAddressId;
                      return RadioListTile<int>(
                        value: addr.id,
                        groupValue: effectiveAddressId,
                        onChanged: (v) => setState(() {
                          _selectedAddressId = v;
                          if (!addr.supportsCod &&
                              _payment == PaymentMethodOption.cod) {
                            _payment = PaymentMethodOption.card;
                          }
                        }),
                        title: Text(addr.label, style: AppTextStyles.titleSmall),
                        subtitle: Text(
                          '${addr.cityName ?? ''} — ${addr.regionName ?? ''}\n'
                          'التوصيل: ${addr.deliveryFee.toStringAsFixed(0)} ${AppConstants.currency}'
                          '${addr.supportsCod ? '' : ' · لا يدعم الدفع عند الاستلام'}',
                          style: AppTextStyles.bodySmall,
                        ),
                        activeColor: AppColors.primary,
                        selected: selectedAddr,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selectedAddr
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    Text('طريقة الدفع', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    if (selected.supportsCod)
                      _PayTile(
                        title: 'الدفع عند الاستلام',
                        subtitle: 'متاح لهذه المنطقة',
                        icon: Iconsax.money,
                        selected: _payment == PaymentMethodOption.cod,
                        onTap: () =>
                            setState(() => _payment = PaymentMethodOption.cod),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'هذه المنطقة لا تدعم الدفع عند الاستلام',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    _PayTile(
                      title: 'بطاقة ائتمان / مدى',
                      subtitle: 'دفع آمن بالبطاقة',
                      icon: Iconsax.card,
                      selected: _payment == PaymentMethodOption.card,
                      onTap: () =>
                          setState(() => _payment = PaymentMethodOption.card),
                    ),
                    _PayTile(
                      title: 'بوابة دفع إلكترونية',
                      subtitle: 'Moyasar / Tap وغيرها',
                      icon: Iconsax.global,
                      selected: _payment == PaymentMethodOption.gateway,
                      onTap: () => setState(
                          () => _payment = PaymentMethodOption.gateway),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final walletAsync = ref.watch(walletProvider);
                        return walletAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (wallet) {
                            final enough = wallet.balance >= total;
                            return Column(
                              children: [
                                _PayTile(
                                  title: 'المحفظة',
                                  subtitle: enough
                                      ? 'الرصيد: ${wallet.balance.toStringAsFixed(2)} ${AppConstants.currency}'
                                      : 'رصيد غير كافٍ (${wallet.balance.toStringAsFixed(2)})',
                                  icon: Iconsax.wallet_3,
                                  selected:
                                      _payment == PaymentMethodOption.wallet,
                                  onTap: enough
                                      ? () => setState(() =>
                                          _payment = PaymentMethodOption.wallet)
                                      : () => context.push(AppRoutes.wallet),
                                ),
                                if (!enough)
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: TextButton(
                                      onPressed: () =>
                                          context.push(AppRoutes.wallet),
                                      child: const Text('اشحن المحفظة'),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text('ملاحظات', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'ملاحظات للطلب (اختياري)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('ملخص التكلفة', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    _SummaryRow(label: 'المجموع الفرعي', value: cart.subtotal),
                    _SummaryRow(label: 'رسوم التوصيل', value: deliveryFee),
                    const Divider(height: 24),
                    _SummaryRow(label: 'الإجمالي', value: total, bold: true),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                child: SafeArea(
                  child: BatalatButton(
                    label: _submitting
                        ? 'جاري الإرسال...'
                        : 'تأكيد الطلب — ${total.toStringAsFixed(0)} ${AppConstants.currency}',
                    onTap: _submitting
                        ? null
                        : () => _submit(selected, deliveryFee),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PayTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.titleSmall),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: Icon(
          selected ? Iconsax.tick_circle5 : Iconsax.tick_circle,
          color: selected ? AppColors.primary : AppColors.textHint,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium,
          ),
          PriceTag(price: value, large: bold),
        ],
      ),
    );
  }
}
