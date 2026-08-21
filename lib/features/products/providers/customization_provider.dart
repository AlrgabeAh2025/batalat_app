/// Batalat — Customization requests provider
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  final int? productId;
  final String productName;
  final String productSlug;
  final String title;
  final String displayTitle;
  final String description;
  final String status;
  final String statusDisplay;
  final List<String> imageUrls;
  final CustomQuoteInfo? latestQuote;
  final DateTime createdAt;

  const CustomRequestInfo({
    required this.id,
    this.productId,
    this.productName = '',
    this.productSlug = '',
    this.title = '',
    this.displayTitle = '',
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
    final title = json['title'] as String? ?? '';
    final display = json['display_title'] as String? ?? '';
    final productName = json['product_name'] as String? ?? '';
    return CustomRequestInfo(
      id: json['id'] as int,
      productId: json['product'] as int?,
      productName: productName,
      productSlug: json['product_slug'] as String? ?? '',
      title: title,
      displayTitle: display.isNotEmpty
          ? display
          : (productName.isNotEmpty ? productName : (title.isNotEmpty ? title : 'طلب مخصص')),
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

  bool get isActive =>
      status == 'pending_quote' || status == 'quoted';

  bool get hasActionableQuote =>
      status == 'quoted' &&
      latestQuote != null &&
      latestQuote!.status == 'sent' &&
      !latestQuote!.isExpired;

  String get trackingHint {
    if (hasActionableQuote) {
      return 'عرض سعر بانتظار قبولك — اضغط للمتابعة';
    }
    return switch (status) {
      'pending_quote' => 'طلبك قيد المراجعة — سنرسل عرض سعر قريباً',
      'quoted' => 'تم إرسال عرض سعر — راجع التفاصيل',
      'accepted' => 'قبلت العرض — أكمل الطلب من السلة إن لزم',
      'rejected' => 'تم رفض العرض',
      'cancelled' => 'تم إلغاء الطلب',
      _ => statusDisplay.isNotEmpty ? statusDisplay : 'طلب مخصص',
    };
  }

  String get dateLabel {
    final d = createdAt;
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }
}

Future<CustomRequestInfo> createCustomRequest({
  required String description,
  String title = '',
  int? productId,
  List<XFile> images = const [],
}) async {
  try {
    final Response res;
    if (images.isEmpty) {
      final body = <String, dynamic>{
        'description': description,
        if (title.trim().isNotEmpty) 'title': title.trim(),
        if (productId != null) 'product_id': productId,
      };
      res = await ApiClient().dio.post(
        '/products/custom-requests/',
        data: body,
      );
    } else {
      final form = FormData();
      form.fields.add(MapEntry('description', description));
      if (title.trim().isNotEmpty) {
        form.fields.add(MapEntry('title', title.trim()));
      }
      if (productId != null) {
        form.fields.add(MapEntry('product_id', '$productId'));
      }
      for (final file in images.take(5)) {
        final bytes = await file.readAsBytes();
        final name = file.name.isNotEmpty ? file.name : 'image.jpg';
        form.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(bytes, filename: name),
          ),
        );
      }
      res = await ApiClient().dio.post(
        '/products/custom-requests/',
        data: form,
      );
    }
    return CustomRequestInfo.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
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
