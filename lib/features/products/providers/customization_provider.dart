/// Batalat — Customization requests provider
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class CustomQuoteInfo {
  final int id;
  final double amount;
  final String adminNote;
  final String status;
  final String statusDisplay;
  final bool isExpired;
  final DateTime? validUntil;

  const CustomQuoteInfo({
    required this.id,
    required this.amount,
    this.adminNote = '',
    required this.status,
    this.statusDisplay = '',
    this.isExpired = false,
    this.validUntil,
  });

  factory CustomQuoteInfo.fromJson(Map<String, dynamic> json) {
    return CustomQuoteInfo(
      id: json['id'] as int,
      amount: _parseDouble(json['amount']),
      adminNote: json['admin_note'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusDisplay: json['status_display'] as String? ?? '',
      isExpired: json['is_expired'] as bool? ?? false,
      validUntil: DateTime.tryParse(json['valid_until']?.toString() ?? ''),
    );
  }
}

class CustomRequestInfo {
  final int id;
  final int productId;
  final String productName;
  final String productSlug;
  final String description;
  final String status;
  final String statusDisplay;
  final List<String> imageUrls;
  final CustomQuoteInfo? latestQuote;
  final DateTime createdAt;

  const CustomRequestInfo({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.description,
    required this.status,
    this.statusDisplay = '',
    this.imageUrls = const [],
    this.latestQuote,
    required this.createdAt,
  });

  factory CustomRequestInfo.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => e['image']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    final quoteRaw = json['latest_quote'];
    return CustomRequestInfo(
      id: json['id'] as int,
      productId: json['product'] as int? ?? 0,
      productName: json['product_name'] as String? ?? '',
      productSlug: json['product_slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusDisplay: json['status_display'] as String? ?? '',
      imageUrls: images,
      latestQuote: quoteRaw is Map
          ? CustomQuoteInfo.fromJson(Map<String, dynamic>.from(quoteRaw))
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

final myCustomRequestsProvider =
    FutureProvider.autoDispose<List<CustomRequestInfo>>((ref) async {
  try {
    final res = await ApiClient().dio.get('/products/custom-requests/my/');
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map((e) => CustomRequestInfo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final customRequestDetailProvider =
    FutureProvider.autoDispose.family<CustomRequestInfo, int>((ref, id) async {
  try {
    final res = await ApiClient().dio.get('/products/custom-requests/$id/');
    return CustomRequestInfo.fromJson(Map<String, dynamic>.from(res.data as Map));
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
