/// Batalat — Notifications models + providers
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/features/auth/providers/auth_provider.dart';

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String notificationType;
  final String typeDisplay;
  final String imageUrl;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.notificationType = 'general',
    this.typeDisplay = '',
    this.imageUrl = '',
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  int? get orderId {
    final raw = data['order_id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? 'general',
      typeDisplay: json['type_display'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  if (!ref.watch(isAuthenticatedProvider)) return [];
  try {
    final res = await ApiClient().dio.get('/notifications/');
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final unreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(isAuthenticatedProvider)) return 0;
  try {
    final res = await ApiClient().dio.get('/notifications/unread-count/');
    final data = res.data;
    if (data is Map) {
      return data['unread_count'] as int? ?? 0;
    }
    return 0;
  } on DioException {
    return 0;
  }
});

Future<void> markNotificationRead(int id) async {
  await ApiClient().dio.post('/notifications/$id/mark-read/');
}

Future<void> markAllNotificationsRead() async {
  await ApiClient().dio.post('/notifications/mark-all-read/');
}

Future<void> registerFcmDevice({
  required String token,
  required String platform,
  String deviceName = '',
}) async {
  await ApiClient().dio.post('/notifications/devices/register/', data: {
    'token': token,
    'platform': platform,
    'device_name': deviceName,
  });
}

Future<void> unregisterFcmDevice(String token) async {
  await ApiClient().dio.delete(
    '/notifications/devices/unregister/',
    data: {'token': token},
  );
}
