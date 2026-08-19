/// Batalat — Wallet Screen
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/wallet/providers/wallet_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BatalatAppBar(title: 'محفظتي'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(walletProvider);
          ref.invalidate(walletTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          children: [
            walletAsync.when(
              loading: () => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
              data: (wallet) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B1A1A), Color(0xFF5C1010)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.wallet_3, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          'الرصيد المتاح',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${wallet.balance.toStringAsFixed(2)} ${AppConstants.currency}',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        onPressed: () => _openTopup(context, ref),
                        child: const Text('شحن المحفظة'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('سجل الحركات', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                emoji: '⚠️',
                title: 'تعذر التحميل',
                subtitle: e.toString(),
                actionLabel: 'إعادة',
                onAction: () => ref.invalidate(walletTransactionsProvider),
              ),
              data: (txs) {
                if (txs.isEmpty) {
                  return const EmptyState(
                    emoji: '💳',
                    title: 'لا توجد حركات بعد',
                    subtitle: 'اشحن محفظتك للبدء',
                  );
                }
                return Column(
                  children: txs.map((tx) {
                    final positive = tx.amount >= 0;
                    final color =
                        positive ? AppColors.success : AppColors.error;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              positive ? Iconsax.arrow_down_1 : Iconsax.arrow_up_1,
                              color: color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.typeDisplay.isNotEmpty
                                      ? tx.typeDisplay
                                      : tx.type,
                                  style: AppTextStyles.titleSmall,
                                ),
                                if (tx.note.isNotEmpty || tx.reference.isNotEmpty)
                                  Text(
                                    tx.note.isNotEmpty ? tx.note : tx.reference,
                                    style: AppTextStyles.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${positive ? '+' : ''}${tx.amount.toStringAsFixed(2)}',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: color,
                                ),
                              ),
                              Text(
                                'رصيد: ${tx.balanceAfter.toStringAsFixed(0)}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTopup(BuildContext context, WidgetRef ref) async {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    XFile? proof;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('شحن المحفظة', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'المبلغ'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'مرجع التحويل (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 75,
                      );
                      if (picked != null) setModal(() => proof = picked);
                    },
                    icon: const Icon(Iconsax.gallery),
                    label: Text(
                      proof == null ? 'إثبات التحويل (اختياري)' : proof!.name,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BatalatButton(
                    label: 'تأكيد الشحن',
                    onTap: () async {
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (amount == null || amount < 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('أدخل مبلغاً صالحاً')),
                        );
                        return;
                      }
                      try {
                        final form = FormData.fromMap({
                          'amount': amount.toStringAsFixed(2),
                          'transfer_reference': refCtrl.text.trim(),
                          if (proof != null)
                            'proof': await MultipartFile.fromFile(
                              proof!.path,
                              filename: proof!.name,
                            ),
                        });
                        await ApiClient().dio.post(
                          '/payments/wallet/topup/',
                          data: form,
                        );
                        ref.invalidate(walletProvider);
                        ref.invalidate(walletTransactionsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم شحن المحفظة')),
                          );
                        }
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
            );
          },
        );
      },
    );
  }
}
