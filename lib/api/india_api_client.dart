/// HTTP client for the Lumin India engine API.
///
/// Auth: Firebase ID token as Bearer header. The token is fetched fresh
/// from FirebaseAuth on each request (1-hour TTL, auto-refreshed by
/// FlutterFire). On 401: force-refreshes the token, retries once, then
/// gives up (the auth gate catches the signed-out state).
///
/// Falls back to the static INDIA_API_TOKEN for owner testing when no
/// Firebase user is signed in.
library;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config.dart';
import '../features/signals/models.dart';

class IndiaApiClient {
  IndiaApiClient({Dio? dio}) : _dio = dio ?? _buildDio();

  static bool isAuthError(Object? error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      return code == 401 || code == 403;
    }
    return false;
  }

  final Dio _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    dio.interceptors.add(_FirebaseAuthInterceptor());
    dio.interceptors.add(_RetryOnceInterceptor(dio));
    return dio;
  }

  Future<EnginePulse> pulse() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/pulse');
    return EnginePulse.fromJson(resp.data ?? const {});
  }

  Future<List<IndiaSignal>> signals({int limit = 50}) async {
    final resp = await _dio.get<List<dynamic>>(
      '/api/signals',
      queryParameters: {'limit': limit},
    );
    return (resp.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(IndiaSignal.fromJson)
        .toList();
  }

  Future<IndiaSignal> signalById(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/signals/$id');
    return IndiaSignal.fromJson(resp.data ?? const {});
  }

  Future<List<SignalOutcome>> outcomes({String? date, int limit = 100}) async {
    final resp = await _dio.get<List<dynamic>>(
      '/api/outcomes',
      queryParameters: {
        if (date != null) 'date': date,
        'limit': limit,
      },
    );
    return (resp.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SignalOutcome.fromJson)
        .toList();
  }

  Future<List<SessionSummary>> sessionSummaries({int limit = 30}) async {
    final resp = await _dio.get<List<dynamic>>(
      '/api/session-summary',
      queryParameters: {'limit': limit},
    );
    return (resp.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SessionSummary.fromJson)
        .toList();
  }

  Future<void> registerFcmToken(String token, {String uid = ''}) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/fcm-token',
      data: {'token': token, 'uid': uid},
    );
  }
}

/// Injects the Firebase ID token (or static fallback) as a Bearer header.
class _FirebaseAuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final forceRefresh = options.extra['_force_refresh_token'] == true;
      try {
        final idToken = await user.getIdToken(forceRefresh);
        if (idToken != null) {
          options.headers['Authorization'] = 'Bearer $idToken';
          return handler.next(options);
        }
      } catch (_) {
        // Fall through to static token
      }
    }

    if (AppConfig.apiToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${AppConfig.apiToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['_auth_retried'] != true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        err.requestOptions.extra['_auth_retried'] = true;
        err.requestOptions.extra['_force_refresh_token'] = true;
        try {
          final idToken = await user.getIdToken(true);
          if (idToken != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $idToken';
            final resp = await Dio().fetch<dynamic>(err.requestOptions);
            return handler.resolve(resp);
          }
        } catch (_) {
          // Fall through to original error
        }
      }
    }
    handler.next(err);
  }
}

/// Retries a request exactly once on connection-level failures.
class _RetryOnceInterceptor extends Interceptor {
  _RetryOnceInterceptor(this._dio);

  final Dio _dio;
  static const _retriedKey = 'lumin_retried';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retriable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.receiveTimeout;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (retriable && !alreadyRetried) {
      err.requestOptions.extra[_retriedKey] = true;
      try {
        final response = await _dio.fetch<dynamic>(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    }
    handler.next(err);
  }
}
