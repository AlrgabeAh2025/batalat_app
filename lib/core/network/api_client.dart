/// Batalat — Network Layer (Dio)
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';

/// يُستدعى مرة واحدة عند فشل تجديد الجلسة (refresh منتهٍ / غير صالح).
typedef SessionExpiredCallback = void Function();

class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  /// بدون interceptors — لتجديد التوكن فقط (يمنع الحلقة اللانهائية).
  late final Dio _refreshDio;

  SessionExpiredCallback? onSessionExpired;

  /// يُستدعى بعد تسجيل دخول ناجح لإعادة السماح بإشعار انتهاء الجلسة لاحقاً.
  void resetSessionGuard() {
    _authInterceptor?.resetSessionGuard();
  }

  _AuthInterceptor? _authInterceptor;

  void initialize() {
    final baseOptions = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': 'ar',
      },
    );

    _dio = Dio(baseOptions);
    _refreshDio = Dio(baseOptions);
    _authInterceptor = _AuthInterceptor(this);

    _dio.interceptors.addAll([
      _authInterceptor!,
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    ]);
  }

  Dio get dio => _dio;
  FlutterSecureStorage get storage => _storage;
  Dio get refreshDio => _refreshDio;

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient _client;

  /// طلب تجديد واحد مشترك لكل الطلبات المتزامنة.
  Completer<bool>? _refreshCompleter;
  bool _sessionExpiredNotified = false;

  static const _authSkipPaths = [
    '/auth/login/',
    '/auth/register/',
    '/auth/verify-otp/',
    '/auth/token/refresh/',
    '/auth/logout/',
    '/auth/send-otp/',
  ];

  _AuthInterceptor(this._client);

  void resetSessionGuard() {
    _sessionExpiredNotified = false;
  }

  bool _shouldSkipRefresh(RequestOptions options) {
    final path = options.path;
    return _authSkipPaths.any((p) => path.contains(p));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_shouldSkipRefresh(options)) {
      final token =
          await _client.storage.read(key: AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;

    // لا نحاول التجديد لطلبات المصادقة أو غير 401 أو بعد إعادة محاولة
    if (status != 401 ||
        _shouldSkipRefresh(options) ||
        options.extra['_authRetried'] == true) {
      // فشل refresh نفسه → إنهاء الجلسة مرة واحدة
      if (status == 401 && options.path.contains('/auth/token/refresh/')) {
        await _expireSession();
      }
      return handler.next(err);
    }

    final refreshed = await _refreshTokens();
    if (!refreshed) {
      await _expireSession();
      return handler.next(err);
    }

    try {
      final access =
          await _client.storage.read(key: AppConstants.accessTokenKey);
      options.headers['Authorization'] = 'Bearer $access';
      options.extra['_authRetried'] = true;
      final response = await _client.dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<bool> _refreshTokens() async {
    // إذا كان تجديد جارياً، انتظر نتيجته
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken =
          await _client.storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(false);
        return false;
      }

      // Dio منفصل بدون interceptor — يمنع حلقة 401 على /token/refresh/
      final response = await _client.refreshDio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final data = response.data;
      if (data is! Map) {
        completer.complete(false);
        return false;
      }

      final newAccess = data['access'] as String?;
      if (newAccess == null || newAccess.isEmpty) {
        completer.complete(false);
        return false;
      }

      await _client.storage.write(
        key: AppConstants.accessTokenKey,
        value: newAccess,
      );

      // مهم مع ROTATE_REFRESH_TOKENS: حفظ الـ refresh الجديد
      final newRefresh = data['refresh'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _client.storage.write(
          key: AppConstants.refreshTokenKey,
          value: newRefresh,
        );
      }

      _sessionExpiredNotified = false;
      completer.complete(true);
      return true;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _expireSession() async {
    await _client.clearTokens();
    if (_sessionExpiredNotified) return;
    _sessionExpiredNotified = true;
    _client.onSessionExpired?.call();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    String message = 'حدث خطأ غير متوقع';
    if (error.response?.data is Map) {
      final data = error.response!.data as Map;
      message = data['detail']?.toString() ??
          data['message']?.toString() ??
          data.values.first?.toString() ??
          message;
    }
    return ApiException(message, statusCode: error.response?.statusCode);
  }

  @override
  String toString() => message;
}
