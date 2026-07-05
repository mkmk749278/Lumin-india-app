/// FCM push notification service.
///
/// Handles Firebase Cloud Messaging init, token registration with the engine,
/// and foreground/background notification routing.
///
/// Notification body never contains price targets (CLAUDE.md) — just
/// symbol, direction, and confidence tier. Full detail is in-app only.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/india_api_client.dart';
import '../features/signals/models.dart';

/// Top-level handler for background messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

class FcmService {
  FcmService(
    this._api, {
    this.uid = '',
    this.onSignalTapped,
    this.onForegroundMessage,
  });

  final IndiaApiClient _api;
  final String uid;

  /// Called when the user taps a notification (background or terminated app).
  /// Provides the signal_id to navigate to.
  final void Function(String signalId)? onSignalTapped;

  /// Called when an FCM message arrives while the app is in the foreground.
  final void Function(FcmForegroundNotif notif)? onForegroundMessage;

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: user denied notification permission');
      return;
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    messaging.onTokenRefresh.listen(_registerToken);

    // Background → foreground: user tapped a notification while app was suspended.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final id = signalIdFromMessage(message);
      if (id != null) onSignalTapped?.call(id);
    });

    // Terminated → foreground: user tapped a notification that launched the app.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      final id = signalIdFromMessage(initial);
      if (id != null) onSignalTapped?.call(id);
    }

    // Foreground: app is active, message arrives — show in-app banner.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.registerFcmToken(token, uid: uid);
      debugPrint('FCM token registered with engine');
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final signalId = signalIdFromMessage(message);
    final symbol = data['base'] as String? ?? data['symbol'] as String? ?? '';
    final direction = data['direction'] as String? ?? '';
    final tier = data['confidence_tier'] as String? ?? '';

    debugPrint('FCM foreground: $symbol $direction $tier (id=$signalId)');

    if (signalId != null && symbol.isNotEmpty) {
      onForegroundMessage?.call(FcmForegroundNotif(
        signalId: signalId,
        symbol: symbol,
        direction: direction,
        tier: tier,
      ));
    }
  }

  /// Extracts a signal_id from an FCM message payload.
  static String? signalIdFromMessage(RemoteMessage message) {
    return message.data['signal_id'] as String?;
  }
}
