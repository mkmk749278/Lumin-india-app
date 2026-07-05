/// HTTP client for the Lumin India engine API.
///
/// Endpoints (lumina-india-engine `src/api/server.py`):
///   GET /api/health           — liveness (no auth)
///   GET /api/pulse            — session state, signal count
///   GET /api/signals          — signal list (filters: date, tier, limit)
///   GET /api/signals/{id}     — single signal
///   GET /api/outcomes         — TP1/SL/EXPIRED outcomes joined onto signals
///   GET /api/session-summary  — 30-day daily quality ledger
///
/// Auth: static Bearer token in Phase 1 owner testing (see AppConfig).
library;

import 'package:dio/dio.dart';

import '../config.dart';
import '../features/signals/models.dart';

class IndiaApiClient {
  IndiaApiClient({Dio? dio}) : _dio = dio ?? _buildDio();

  /// True when the engine actively rejected us (401/403) — a build/token
  /// problem, not a network problem. The UI words these differently.
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
        headers: {
          if (AppConfig.apiToken.isNotEmpty)
            'Authorization': 'Bearer ${AppConfig.apiToken}',
        },
      ),
    );
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

/// Retries a request exactly once on connection-level failures
/// (mobile networks drop; a signal feed should not error on one blip).
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
