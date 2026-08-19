/// Batalat — Locations provider
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class LocationCity {
  final int id;
  final String name;
  final String slug;
  final double totalDeliveryFee;

  const LocationCity({
    required this.id,
    required this.name,
    required this.slug,
    this.totalDeliveryFee = 0,
  });

  factory LocationCity.fromJson(Map<String, dynamic> json) {
    return LocationCity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      totalDeliveryFee: _parseDouble(json['total_delivery_fee']),
    );
  }
}

class LocationRegion {
  final int id;
  final String name;
  final String slug;
  final double deliveryFee;
  final bool supportsCod;
  final List<LocationCity> cities;

  const LocationRegion({
    required this.id,
    required this.name,
    required this.slug,
    this.deliveryFee = 0,
    this.supportsCod = true,
    this.cities = const [],
  });

  factory LocationRegion.fromJson(Map<String, dynamic> json) {
    final cities = (json['cities'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => LocationCity.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return LocationRegion(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      deliveryFee: _parseDouble(json['delivery_fee']),
      supportsCod: json['supports_cod'] as bool? ?? true,
      cities: cities,
    );
  }
}

final regionsProvider =
    FutureProvider.autoDispose<List<LocationRegion>>((ref) async {
  try {
    final response = await ApiClient().dio.get('/locations/regions/');
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map((e) => LocationRegion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
