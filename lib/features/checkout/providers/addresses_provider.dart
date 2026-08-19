/// Batalat — Addresses provider
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class DeliveryAddress {
  final int id;
  final String label;
  final String recipientName;
  final String? regionName;
  final String? cityName;
  final String area;
  final String street;
  final bool isDefault;
  final bool supportsCod;
  final double deliveryFee;
  final int? regionId;
  final int? cityId;

  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    this.regionName,
    this.cityName,
    this.area = '',
    this.street = '',
    this.isDefault = false,
    this.supportsCod = true,
    this.deliveryFee = 0,
    this.regionId,
    this.cityId,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] as int,
      label: json['label'] as String? ?? '',
      recipientName: json['recipient_name'] as String? ?? '',
      regionName: json['region_name'] as String?,
      cityName: json['city_name'] as String?,
      area: json['area'] as String? ?? '',
      street: json['street'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      supportsCod: json['supports_cod'] as bool? ?? true,
      deliveryFee: _parseDouble(json['delivery_fee']),
      regionId: json['region'] is int ? json['region'] as int : null,
      cityId: json['city'] is int ? json['city'] as int : null,
    );
  }

  String get fullText =>
      '$label — $recipientName\n${cityName ?? ''}، ${regionName ?? ''}\n$area، $street';
}

final addressesProvider =
    FutureProvider.autoDispose<List<DeliveryAddress>>((ref) async {
  try {
    final response = await ApiClient().dio.get('/users/addresses/');
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .map((e) => DeliveryAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
