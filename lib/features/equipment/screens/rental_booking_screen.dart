/// Batalat — Rental booking (calendar range + quote)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/checkout/providers/addresses_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import '../models/equipment_models.dart';
import '../providers/equipment_provider.dart';

class RentalBookingScreen extends ConsumerStatefulWidget {
  final String slug;

  const RentalBookingScreen({super.key, required this.slug});

  @override
  ConsumerState<RentalBookingScreen> createState() =>
      _RentalBookingScreenState();
}

class _RentalBookingScreenState extends ConsumerState<RentalBookingScreen> {
  String? _pricingMode;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  int _quantity = 1;
  DeliveryAddress? _address;
  RentalQuote? _quote;
  String? _quoteError;
  bool _quoting = false;
  bool _submitting = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  DateTime get _focusedDay => _rangeStart ?? DateTime.now();

  DateTime _combine(DateTime day, TimeOfDay time) => DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );

  String _resolveMode(EquipmentDetail item) {
    if (_pricingMode != null) return _pricingMode!;
    if (item.pricingType == 'hourly') return 'hourly';
    if (item.pricingType == 'both') return 'daily';
    return 'daily';
  }

  bool _regionBlocked(EquipmentDetail item) {
    final rid = _address?.regionId;
    if (rid == null) return false;
    return item.blockedRegionIds.contains(rid) ||
        (_quote?.blockedRegionIds.contains(rid) ?? false);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
      _quote = null;
    });
    _refreshQuote();
  }

  Future<void> _refreshQuote() async {
    final detail = ref.read(equipmentDetailProvider(widget.slug)).valueOrNull;
    if (detail == null || _rangeStart == null || _rangeEnd == null) return;

    final start = _combine(_rangeStart!, _startTime);
    final end = _combine(_rangeEnd!, _endTime);
    if (!end.isAfter(start)) {
      setState(() {
        _quote = null;
        _quoteError = 'يجب أن يكون وقت النهاية بعد البداية';
      });
      return;
    }

    if (_regionBlocked(detail)) {
      setState(() {
        _quote = null;
        _quoteError = 'هذه المنطقة غير متاحة لتأجير هذه المعدة';
      });
      return;
    }

    setState(() {
      _quoting = true;
      _quoteError = null;
    });

    try {
      final quote = await fetchRentalQuote(
        productId: detail.id,
        start: start,
        end: end,
        quantity: _quantity,
        pricingMode: _resolveMode(detail),
        deliveryAddressId: _address?.id,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _quoting = false;
        if (!quote.isAvailable) {
          _quoteError =
              'الكمية غير متاحة لهذه الفترة (المتاح: ${quote.availableQuantity})';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quoting = false;
        _quote = null;
        _quoteError = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _submit(EquipmentDetail item) async {
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر فترة الإيجار')),
      );
      return;
    }
    if (item.requiresDelivery && _address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر عنوان التوصيل')),
      );
      return;
    }
    if (_regionBlocked(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المنطقة محظورة لهذه المعدة')),
      );
      return;
    }
    if (_quote == null || !_quote!.isAvailable) {
      await _refreshQuote();
      if (_quote == null || !_quote!.isAvailable) return;
    }

    setState(() => _submitting = true);
    try {
      final booking = await createRentalBooking(
        productId: item.id,
        start: _combine(_rangeStart!, _startTime),
        end: _combine(_rangeEnd!, _endTime),
        quantity: _quantity,
        pricingMode: _resolveMode(item),
        deliveryAddressId: _address?.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تم الحجز'),
          content: Text(
            'رقم الحجز: ${booking.bookingNumber}\n'
            'الإجمالي: ${booking.totalPrice.toStringAsFixed(0)} ${AppConstants.currency}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.myRentals);
              },
              child: const Text('حجوزاتي'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : (e is DioException
              ? ApiException.fromDioError(e).message
              : e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(equipmentDetailProvider(widget.slug));
    final addressesAsync = ref.watch(addressesProvider);

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text('حجز إيجار', style: AppTextStyles.headlineSmall),
          backgroundColor: Colors.transparent,
        ),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 280),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () =>
              ref.invalidate(equipmentDetailProvider(widget.slug)),
        ),
      ),
      data: (item) {
        final mode = _resolveMode(item);
        final blocked = _regionBlocked(item);
        final fmt = DateFormat('yyyy/MM/dd');

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text('حجز — ${item.name}', style: AppTextStyles.headlineSmall),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            children: [
              if (item.pricingType == 'both') ...[
                Text('نوع التسعير', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'daily', label: Text('يومي')),
                    ButtonSegment(value: 'hourly', label: Text('ساعي')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) {
                    setState(() {
                      _pricingMode = s.first;
                      _quote = null;
                    });
                    _refreshQuote();
                  },
                ),
                const SizedBox(height: 20),
              ],
              Text('فترة الإيجار', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 0)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                rangeSelectionMode: RangeSelectionMode.enforced,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                startingDayOfWeek: StartingDayOfWeek.saturday,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: AppColors.primarySurface,
                  rangeStartDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
                onFormatChanged: (f) => setState(() => _calendarFormat = f),
                onRangeSelected: (start, end, focused) {
                  setState(() {
                    _rangeStart = start;
                    _rangeEnd = end ?? start;
                    _quote = null;
                  });
                  if (_rangeStart != null && _rangeEnd != null) {
                    _refreshQuote();
                  }
                },
              ),
              if (_rangeStart != null && _rangeEnd != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${fmt.format(_rangeStart!)} → ${fmt.format(_rangeEnd!)}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: true),
                      icon: const Icon(Iconsax.clock),
                      label: Text(
                        'بداية ${_startTime.format(context)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Iconsax.clock),
                      label: Text('نهاية ${_endTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('الكمية', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () {
                            setState(() {
                              _quantity--;
                              _quote = null;
                            });
                            _refreshQuote();
                          }
                        : null,
                    icon: const Icon(Iconsax.minus),
                  ),
                  Text('$_quantity', style: AppTextStyles.titleLarge),
                  IconButton(
                    onPressed: _quantity < item.availableQuantity
                        ? () {
                            setState(() {
                              _quantity++;
                              _quote = null;
                            });
                            _refreshQuote();
                          }
                        : null,
                    icon: const Icon(Iconsax.add),
                  ),
                  const Spacer(),
                  Text(
                    'المتاح: ${item.availableQuantity}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              if (mode == 'hourly') ...[
                const SizedBox(height: 4),
                Text(
                  'الحد الأدنى: ${item.minRentalHours} ساعة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                item.requiresDelivery ? 'عنوان التوصيل' : 'عنوان (اختياري)',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 8),
              addressesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return OutlinedButton(
                      onPressed: () => context.push(AppRoutes.addresses),
                      child: const Text('أضف عنواناً أولاً'),
                    );
                  }
                  return Column(
                    children: [
                      for (final a in addresses)
                        ListTile(
                          selected: _address?.id == a.id,
                          leading: Icon(
                            _address?.id == a.id
                                ? Iconsax.tick_circle5
                                : Iconsax.tick_circle,
                            color: AppColors.primary,
                          ),
                          title: Text(a.label),
                          subtitle: Text(
                            '${a.cityName ?? ''} — ${a.regionName ?? ''}',
                            style: AppTextStyles.bodySmall,
                          ),
                          onTap: () {
                            setState(() {
                              _address = a;
                              _quote = null;
                            });
                            _refreshQuote();
                          },
                        ),
                    ],
                  );
                },
              ),
              if (blocked) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'هذه المنطقة غير متاحة لتأجير هذه المعدة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('ملخص السعر', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              if (_quoting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_quoteError != null && _quote == null)
                Text(
                  _quoteError!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                )
              else if (_quote != null) ...[
                _PriceRow(label: 'المدة', value: _quote!.durationLabel),
                _PriceRow(
                  label: 'الإيجار',
                  value:
                      '${_quote!.rentalPrice.toStringAsFixed(0)} ${AppConstants.currency}',
                ),
                _PriceRow(
                  label: 'العربون',
                  value:
                      '${_quote!.depositAmount.toStringAsFixed(0)} ${AppConstants.currency}',
                ),
                _PriceRow(
                  label: 'التوصيل',
                  value:
                      '${_quote!.deliveryFee.toStringAsFixed(0)} ${AppConstants.currency}',
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي', style: AppTextStyles.titleLarge),
                    PriceTag(price: _quote!.totalPrice, large: true),
                  ],
                ),
                if (_quoteError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _quoteError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ] else
                Text(
                  'اختر الفترة لعرض السعر',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              const SizedBox(height: 24),
              Text('سياسة الإرجاع', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Text(
                (item.returnPolicyText.isNotEmpty
                        ? item.returnPolicyText
                        : _quote?.returnPolicyText) ??
                    'يُرجى إعادة المعدة بحالة سليمة في الموعد المحدد.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              if (item.damageFee > 0 || (_quote?.damageFee ?? 0) > 0)
                Text(
                  'رسوم التلف: ${(item.damageFee > 0 ? item.damageFee : _quote!.damageFee).toStringAsFixed(0)} ${AppConstants.currency}',
                  style: AppTextStyles.bodySmall,
                ),
              if (item.lossFee > 0 || (_quote?.lossFee ?? 0) > 0)
                Text(
                  'رسوم الضياع: ${(item.lossFee > 0 ? item.lossFee : _quote!.lossFee).toStringAsFixed(0)} ${AppConstants.currency}',
                  style: AppTextStyles.bodySmall,
                ),
              const SizedBox(height: 100),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: BatalatButton(
                label: 'تأكيد الحجز',
                isLoading: _submitting,
                onTap: blocked || _submitting ? null : () => _submit(item),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          Text(value, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
