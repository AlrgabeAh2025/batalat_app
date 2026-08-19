/// Batalat — Wallet + saved payment methods
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class WalletInfo {
  final double balance;
  final String currency;

  const WalletInfo({this.balance = 0, this.currency = 'LYD'});

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      balance: _parseDouble(json['balance']),
      currency: json['currency'] as String? ?? 'LYD',
    );
  }
}

class WalletTx {
  final int id;
  final String type;
  final String typeDisplay;
  final double amount;
  final double balanceAfter;
  final String reference;
  final String note;
  final String? proofUrl;
  final int? orderId;
  final DateTime createdAt;

  const WalletTx({
    required this.id,
    required this.type,
    required this.typeDisplay,
    required this.amount,
    required this.balanceAfter,
    this.reference = '',
    this.note = '',
    this.proofUrl,
    this.orderId,
    required this.createdAt,
  });

  factory WalletTx.fromJson(Map<String, dynamic> json) {
    return WalletTx(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      typeDisplay: json['type_display'] as String? ?? '',
      amount: _parseDouble(json['amount']),
      balanceAfter: _parseDouble(json['balance_after']),
      reference: json['reference'] as String? ?? '',
      note: json['note'] as String? ?? '',
      proofUrl: json['proof_url'] as String?,
      orderId: json['order'] as int?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SavedCard {
  final int id;
  final String label;
  final String holderName;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final String brand;
  final bool isDefault;

  const SavedCard({
    required this.id,
    this.label = '',
    required this.holderName,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    this.brand = '',
    this.isDefault = false,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] as int,
      label: json['label'] as String? ?? '',
      holderName: json['holder_name'] as String? ?? '',
      last4: json['last4'] as String? ?? '',
      expiryMonth: json['expiry_month'] as int? ?? 1,
      expiryYear: json['expiry_year'] as int? ?? 2030,
      brand: json['brand'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

final walletProvider = FutureProvider.autoDispose<WalletInfo>((ref) async {
  try {
    final res = await ApiClient().dio.get('/payments/wallet/');
    return WalletInfo.fromJson(Map<String, dynamic>.from(res.data as Map));
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTx>>((ref) async {
  try {
    final res = await ApiClient().dio.get('/payments/wallet/transactions/');
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map((e) => WalletTx.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final savedCardsProvider =
    FutureProvider.autoDispose<List<SavedCard>>((ref) async {
  try {
    final res = await ApiClient().dio.get('/payments/methods/');
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map((e) => SavedCard.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
