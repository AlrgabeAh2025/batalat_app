/// Batalat — Saved payment methods (card reference)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/wallet/providers/wallet_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(savedCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BatalatAppBar(title: 'طرق الدفع'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text('إضافة بطاقة', style: TextStyle(color: Colors.white)),
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(savedCardsProvider),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return EmptyState(
              emoji: '💳',
              title: 'لا توجد بطاقات محفوظة',
              subtitle: 'أضف بطاقة كمرجع (آخر 4 أرقام فقط)',
              actionLabel: 'إضافة',
              onAction: () => _openAdd(context, ref),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.screenPadding,
              AppConstants.screenPadding,
              AppConstants.screenPadding,
              100,
            ),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = cards[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: c.isDefault ? AppColors.primary : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.card, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.label.isNotEmpty
                                ? c.label
                                : '•••• ${c.last4}',
                            style: AppTextStyles.titleMedium,
                          ),
                          Text(
                            '${c.holderName} · ${c.expiryMonth.toString().padLeft(2, '0')}/${c.expiryYear}',
                            style: AppTextStyles.bodySmall,
                          ),
                          if (c.isDefault)
                            Text(
                              'افتراضي',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!c.isDefault)
                      IconButton(
                        tooltip: 'تعيين افتراضي',
                        icon: const Icon(Iconsax.tick_circle),
                        onPressed: () async {
                          await ApiClient()
                              .dio
                              .post('/payments/methods/${c.id}/set-default/');
                          ref.invalidate(savedCardsProvider);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Iconsax.trash, color: AppColors.error),
                      onPressed: () async {
                        await ApiClient().dio.delete('/payments/methods/${c.id}/');
                        ref.invalidate(savedCardsProvider);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAdd(BuildContext context, WidgetRef ref) async {
    final label = TextEditingController();
    final holder = TextEditingController();
    final last4 = TextEditingController();
    final month = TextEditingController();
    final year = TextEditingController();
    final brand = TextEditingController();
    var isDefault = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('بطاقة مرجعية', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'لا نطلب الرقم الكامل أو CVV — مرجع فقط.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: holder,
                      decoration: const InputDecoration(labelText: 'اسم الحامل'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: last4,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'آخر 4 أرقام'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: month,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'الشهر'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: year,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'السنة'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: label,
                      decoration: const InputDecoration(labelText: 'تسمية (اختياري)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: brand,
                      decoration: const InputDecoration(
                        labelText: 'العلامة (Visa/MC اختياري)',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تعيين كافتراضي'),
                      value: isDefault,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setModal(() => isDefault = v),
                    ),
                    BatalatButton(
                      label: 'حفظ',
                      onTap: () async {
                        try {
                          await ApiClient().dio.post('/payments/methods/', data: {
                            'holder_name': holder.text.trim(),
                            'last4': last4.text.trim(),
                            'expiry_month': int.tryParse(month.text.trim()),
                            'expiry_year': int.tryParse(year.text.trim()),
                            'label': label.text.trim(),
                            'brand': brand.text.trim(),
                            'is_default': isDefault,
                          });
                          ref.invalidate(savedCardsProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } on DioException catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ApiException.fromDioError(e).message,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
