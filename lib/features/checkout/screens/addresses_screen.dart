/// Batalat — Addresses Screen (list + add)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/features/checkout/providers/addresses_provider.dart';
import 'package:batalat_app/features/checkout/providers/locations_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BatalatAppBar(title: 'عناويني'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text('عنوان جديد', style: TextStyle(color: Colors.white)),
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(addressesProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyState(
              emoji: '📍',
              title: 'لا توجد عناوين',
              subtitle: 'أضف عنوان توصيل للمتابعة مع الطلبات',
              actionLabel: 'إضافة عنوان',
              onAction: () => _openAddSheet(context, ref),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.screenPadding,
              AppConstants.screenPadding,
              AppConstants.screenPadding,
              100,
            ),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final a = addresses[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: a.isDefault
                        ? AppColors.primary
                        : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(a.label, style: AppTextStyles.titleMedium),
                        if (a.isDefault) ...[
                          const SizedBox(width: 8),
                          Text(
                            'افتراضي',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Iconsax.trash, color: AppColors.error),
                          onPressed: () async {
                            await ApiClient()
                                .dio
                                .delete('/users/addresses/${a.id}/');
                            ref.invalidate(addressesProvider);
                          },
                        ),
                      ],
                    ),
                    Text(a.recipientName, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${a.cityName ?? ''} — ${a.regionName ?? ''}\n'
                      '${a.area}، ${a.street}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'التوصيل: ${a.deliveryFee.toStringAsFixed(0)} ${AppConstants.currency}'
                      '${a.supportsCod ? ' · يدعم الدفع عند الاستلام' : ' · لا يدعم الدفع عند الاستلام'}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: a.supportsCod
                            ? AppColors.primary
                            : AppColors.error,
                      ),
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

  void _openAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddAddressSheet(),
    ).then((_) => ref.invalidate(addressesProvider));
  }
}

class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet();

  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  final _label = TextEditingController(text: 'المنزل');
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _street = TextEditingController();
  int? _regionId;
  int? _cityId;
  bool _isDefault = true;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _name.dispose();
    _phone.dispose();
    _area.dispose();
    _street.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_regionId == null || _cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر المنطقة والمدينة')),
      );
      return;
    }
    if (_name.text.trim().isEmpty || _street.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل الاسم والشارع')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiClient().dio.post('/users/addresses/', data: {
        'label': _label.text.trim(),
        'recipient_name': _name.text.trim(),
        'recipient_phone': _phone.text.trim().isEmpty
            ? '+218910000000'
            : _phone.text.trim(),
        'region': _regionId,
        'city': _cityId,
        'area': _area.text.trim(),
        'street': _street.text.trim(),
        'is_default': _isDefault,
      });
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.fromDioError(e).message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(regionsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إضافة عنوان', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'التسمية'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم المستلم'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'هاتف المستلم',
                hintText: '+2189XXXXXXXX',
              ),
            ),
            const SizedBox(height: 8),
            regionsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e', style: AppTextStyles.bodySmall),
              data: (regions) {
                final matches = regions.where((r) => r.id == _regionId);
                final selectedRegion =
                    matches.isEmpty ? null : matches.first;
                final cities = selectedRegion?.cities ?? const <LocationCity>[];

                return Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _regionId,
                      decoration: const InputDecoration(labelText: 'المنطقة'),
                      items: regions
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                '${r.name}${r.supportsCod ? '' : ' (بدون COD)'}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _regionId = v;
                        _cityId = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _cityId,
                      decoration: const InputDecoration(labelText: 'المدينة'),
                      items: cities
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: cities.isEmpty
                          ? null
                          : (v) => setState(() => _cityId = v),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _area,
              decoration: const InputDecoration(labelText: 'الحي'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _street,
              decoration: const InputDecoration(labelText: 'الشارع والتفاصيل'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تعيين كعنوان افتراضي'),
              value: _isDefault,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            const SizedBox(height: 12),
            BatalatButton(
              label: _saving ? 'جاري الحفظ...' : 'حفظ العنوان',
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
