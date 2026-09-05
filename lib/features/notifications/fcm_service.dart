/// Batalat — FCM registration helper
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/features/notifications/providers/notifications_provider.dart';

class FcmService {
  FcmService._();

  static final _storage = FlutterSecureStorage();

  static Future<void> registerIfPossible() async {
    try {
      final access = await _storage.read(key: AppConstants.accessTokenKey);
      if (access == null || access.isEmpty) return;

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _storage.write(key: AppConstants.fcmTokenKey, value: token);
      final platform = Platform.isIOS ? 'ios' : 'android';
      await registerFcmDevice(token: token, platform: platform);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _storage.write(key: AppConstants.fcmTokenKey, value: newToken);
        await registerFcmDevice(token: newToken, platform: platform);
      });
    } catch (e) {
      debugPrint('FCM register skipped: $e');
    }
  }

  static Future<void> unregisterIfPossible() async {
    try {
      final token = await _storage.read(key: AppConstants.fcmTokenKey);
      if (token == null || token.isEmpty) return;
      await unregisterFcmDevice(token);
      await _storage.delete(key: AppConstants.fcmTokenKey);
    } catch (e) {
      debugPrint('FCM unregister skipped: $e');
    }
  }
}
