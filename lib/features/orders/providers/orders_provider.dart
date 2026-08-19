/// Batalat — Orders provider
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/features/orders/models/order_models.dart';

final ordersProvider =
    FutureProvider.autoDispose<List<OrderSummary>>((ref) async {
  try {
    final response = await ApiClient().dio.get('/orders/');
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map((e) => OrderSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderDetail, int>((ref, orderId) async {
  try {
    final response = await ApiClient().dio.get('/orders/$orderId/');
    final data = response.data;
    if (data is! Map) {
      throw ApiException('استجابة غير متوقعة من السيرفر');
    }
    return OrderDetail.fromJson(Map<String, dynamic>.from(data));
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
