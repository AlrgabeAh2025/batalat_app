/// Batalat — Equipment providers
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';
import '../models/equipment_models.dart';

class EquipmentFilter {
  final String? categorySlug;
  final String? search;

  const EquipmentFilter({this.categorySlug, this.search});

  EquipmentFilter copyWith({
    String? categorySlug,
    String? search,
    bool clearCategory = false,
    bool clearSearch = false,
  }) {
    return EquipmentFilter(
      categorySlug:
          clearCategory ? null : (categorySlug ?? this.categorySlug),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentFilter &&
          categorySlug == other.categorySlug &&
          search == other.search;

  @override
  int get hashCode => Object.hash(categorySlug, search);
}

class EquipmentFilterNotifier extends StateNotifier<EquipmentFilter> {
  EquipmentFilterNotifier() : super(const EquipmentFilter());

  void setCategory(String? slug) {
    if (slug == null || slug == 'all') {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categorySlug: slug);
    }
  }

  void setSearch(String? q) {
    final t = q?.trim();
    if (t == null || t.isEmpty) {
      state = state.copyWith(clearSearch: true);
    } else {
      state = state.copyWith(search: t);
    }
  }
}

final equipmentFilterProvider =
    StateNotifierProvider<EquipmentFilterNotifier, EquipmentFilter>((ref) {
  return EquipmentFilterNotifier();
});

final equipmentCategoriesProvider =
    FutureProvider<List<EquipmentCategory>>((ref) async {
  try {
    final response = await ApiClient().dio.get('/equipment/categories/');
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .map((e) => EquipmentCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final equipmentListProvider =
    FutureProvider.autoDispose<PaginatedEquipment>((ref) async {
  final filter = ref.watch(equipmentFilterProvider);
  try {
    final query = <String, dynamic>{
      if (filter.categorySlug != null) 'category': filter.categorySlug,
      if (filter.search != null) 'search': filter.search,
    };
    final response = await ApiClient().dio.get(
      '/equipment/',
      queryParameters: query.isEmpty ? null : query,
    );
    return PaginatedEquipment.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final equipmentDetailProvider = FutureProvider.autoDispose
    .family<EquipmentDetail, String>((ref, slug) async {
  try {
    final response = await ApiClient().dio.get('/equipment/$slug/');
    return EquipmentDetail.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

Future<RentalQuote> fetchRentalQuote({
  required int productId,
  required DateTime start,
  required DateTime end,
  required int quantity,
  required String pricingMode,
  int? deliveryAddressId,
}) async {
  try {
    final response = await ApiClient().dio.post(
      '/equipment/check-availability/',
      data: {
        'product_id': productId,
        'start_date': start.toUtc().toIso8601String(),
        'end_date': end.toUtc().toIso8601String(),
        'quantity': quantity,
        'pricing_mode': pricingMode,
        if (deliveryAddressId != null) 'delivery_address_id': deliveryAddressId,
      },
    );
    return RentalQuote.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
}

Future<RentalBookingItem> createRentalBooking({
  required int productId,
  required DateTime start,
  required DateTime end,
  required int quantity,
  required String pricingMode,
  int? deliveryAddressId,
  String notes = '',
}) async {
  try {
    final response = await ApiClient().dio.post(
      '/equipment/rentals/',
      data: {
        'product_id': productId,
        'start_date': start.toUtc().toIso8601String(),
        'end_date': end.toUtc().toIso8601String(),
        'quantity': quantity,
        'pricing_mode': pricingMode,
        if (deliveryAddressId != null) 'delivery_address': deliveryAddressId,
        'notes': notes,
      },
    );
    return RentalBookingItem.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
}

final myRentalsProvider =
    FutureProvider.autoDispose<List<RentalBookingItem>>((ref) async {
  try {
    final response = await ApiClient().dio.get('/equipment/rentals/my/');
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .map((e) => RentalBookingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
