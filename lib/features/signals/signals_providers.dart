/// Riverpod providers — API client, engine pulse, signal feed, quality window.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/india_api_client.dart';
import 'models.dart';

final apiClientProvider = Provider<IndiaApiClient>((ref) => IndiaApiClient());

final pulseProvider = FutureProvider<EnginePulse>(
  (ref) => ref.watch(apiClientProvider).pulse(),
);

final signalsProvider = FutureProvider<List<IndiaSignal>>(
  (ref) => ref.watch(apiClientProvider).signals(),
);

final outcomesProvider = FutureProvider<List<SignalOutcome>>(
  (ref) => ref.watch(apiClientProvider).outcomes(limit: 100),
);

final sessionSummariesProvider = FutureProvider<List<SessionSummary>>(
  (ref) => ref.watch(apiClientProvider).sessionSummaries(limit: 30),
);

/// Signal ID waiting for deep-link navigation after a notification tap.
final pendingSignalIdProvider = StateProvider<String?>((ref) => null);

/// Foreground FCM notification waiting to be shown as an in-app banner.
final fcmForegroundProvider = StateProvider<FcmForegroundNotif?>((ref) => null);
