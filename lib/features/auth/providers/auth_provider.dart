/// Batalat — Auth Provider (Riverpod)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/features/notifications/fcm_service.dart';

// ============================================================
// Auth State
// ============================================================
class AuthState {
  final bool isAuthenticated;
  final bool isRestored;
  final bool sessionExpired;
  final Map<String, dynamic>? user;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.isRestored = false,
    this.sessionExpired = false,
    this.user,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isRestored,
    bool? sessionExpired,
    Map<String, dynamic>? user,
    bool? isLoading,
    bool clearUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isRestored: isRestored ?? this.isRestored,
      sessionExpired: sessionExpired ?? this.sessionExpired,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ============================================================
// Auth Notifier
// ============================================================
class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._dio, this._storage) : super(const AuthState());

  Future<void> _persistSession(Map<String, dynamic> data) async {
    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: data['access'],
    );
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: data['refresh'],
    );

    ApiClient().resetSessionGuard();

    state = state.copyWith(
      isAuthenticated: true,
      isRestored: true,
      sessionExpired: false,
      user: data['user'] as Map<String, dynamic>?,
    );
    FcmService.registerIfPossible();
  }

  /// استعادة الجلسة من التخزين عند تشغيل التطبيق
  Future<bool> restoreSession() async {
    final access = await _storage.read(key: AppConstants.accessTokenKey);
    final refresh = await _storage.read(key: AppConstants.refreshTokenKey);

    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      state = state.copyWith(isAuthenticated: false, isRestored: true);
      return false;
    }

    state = state.copyWith(isAuthenticated: true, isRestored: true);

    try {
      await fetchProfile();
      FcmService.registerIfPossible();
      return true;
    } catch (_) {
      // إن فشل الملف الشخصي وانتهت الجلسة سيُستدعى markSessionExpired من الـ interceptor
      final stillHasAccess =
          await _storage.read(key: AppConstants.accessTokenKey);
      if (stillHasAccess == null || stillHasAccess.isEmpty) {
        state = state.copyWith(
          isAuthenticated: false,
          isRestored: true,
          clearUser: true,
        );
        return false;
      }
      return true;
    }
  }

  /// يُستدعى من ApiClient عند فشل تجديد التوكن
  void markSessionExpired() {
    state = const AuthState(
      isRestored: true,
      isAuthenticated: false,
      sessionExpired: true,
    );
  }

  /// تسجيل الدخول برقم الهاتف وكلمة المرور
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login/', data: {
        'phone': phone,
        'password': password,
      });
      await _persistSession(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// تسجيل مستخدم جديد
  Future<void> register({
    required String phone,
    required String fullName,
    required String password,
  }) async {
    try {
      await _dio.post('/auth/register/', data: {
        'phone': phone,
        'full_name': fullName,
        'password': password,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// التحقق من OTP وحفظ Token (للتسجيل)
  Future<void> verifyOTP({
    required String phone,
    required String code,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post('/auth/verify-otp/', data: {
        'phone': phone,
        'code': code,
        'purpose': purpose,
      });

      await _persistSession(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// إعادة إرسال رمز OTP
  Future<void> resendOTP({
    required String phone,
    required String purpose,
  }) async {
    try {
      await _dio.post('/auth/resend-otp/', data: {
        'phone': phone,
        'purpose': purpose,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// طلب OTP لإعادة تعيين كلمة المرور
  Future<void> forgotPassword({required String phone}) async {
    try {
      await _dio.post('/auth/forgot-password/', data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// تعيين كلمة مرور جديدة بعد OTP
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/reset-password/', data: {
        'phone': phone,
        'code': code,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
    await FcmService.unregisterIfPossible();
    try {
      if (refresh != null) {
        await _dio.post('/auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {}

    await ApiClient().clearTokens();
    await _storage.delete(key: AppConstants.userDataKey);
    state = const AuthState(isRestored: true, sessionExpired: false);
  }

  /// حذف الحساب نهائياً (إخفاء هوية على الخادم)
  Future<void> deleteAccount({required String password}) async {
    final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
    try {
      await _dio.delete(
        '/users/account/',
        data: {
          'password': password,
          if (refresh != null) 'refresh': refresh,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
    await logout();
  }

  /// تحديث بيانات المستخدم
  Future<void> fetchProfile() async {
    final response = await _dio.get('/users/profile/');
    state = state.copyWith(
      isAuthenticated: true,
      user: response.data as Map<String, dynamic>?,
    );
  }
}

// ============================================================
// Providers
// ============================================================
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ApiClient().dio,
    const FlutterSecureStorage(),
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authProvider).user;
});
