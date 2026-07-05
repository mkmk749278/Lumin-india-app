/// FCM push notification service.
///
/// Handles Firebase Cloud Messaging initialization, token registration
/// with the engine, and foreground/background notification routing.
///
/// Notification body never contains price targets (CLAUDE.md) — just
/// symbol, direction, and confidence tier. Full detail is in-app only,
/// behind the subscription wall.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/india_api_client.dart';

/// Top-level handler for background messages (required by Firebase).
/// Must be a top-level function, not a method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

class FcmService {
  FcmService(this._api);

  final IndiaApiClient _api;

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

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.registerFcmToken(token);
      debugPrint('FCM token registered with engine');
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final signalId = data['signal_id'] as String?;
    final symbol = data['base'] as String? ?? data['symbol'] as String? ?? '';
    final direction = data['direction'] as String? ?? '';
    final tier = data['confidence_tier'] as String? ?? '';

    debugPrint('FCM foreground: $symbol $direction $tier (id=$signalId)');

    // The in-app banner and navigation to signal detail will be wired
    // when the nav router supports deep-linking to /signal/:id.
    // For now, the signal feed auto-refreshes every 30s, so the user
    // sees the new signal on the next poll.
  }

  /// Extract a signal_id from a notification tap (background or terminated).
  static String? signalIdFromMessage(RemoteMessage message) {
    return message.data['signal_id'] as String?;
  }
}
