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

/// Today's resolved outcomes only — filtered server-side by the current IST
/// date so the "TODAY'S OUTCOMES" card never bleeds in earlier sessions.
/// The engine stores outcome timestamps in IST (container TZ) and filters on
/// `DATE(o.created_at)`, so we hand it today's IST calendar date.
final todayOutcomesProvider = FutureProvider<List<SignalOutcome>>(
  (ref) => ref.watch(apiClientProvider).outcomes(
        date: istTodayString(),
        limit: 200,
      ),
);

/// Daily quality ledger — one row per closed session. Drives the selectable
/// performance-window card (3D / 1W / 1M). 40 rows comfortably covers a
/// one-month calendar window of trading sessions.
final sessionSummariesProvider = FutureProvider<List<SessionSummary>>(
  (ref) => ref.watch(apiClientProvider).sessionSummaries(limit: 40),
);

/// Selectable look-back for the performance-window card. Defaults to one week.
final perfWindowProvider =
    StateProvider<PerfWindow>((ref) => PerfWindow.week);

/// Look-back ranges for the performance-window card. `days` is a calendar
/// span measured back from today (IST); the card filters the daily ledger to
/// sessions whose date falls inside it.
enum PerfWindow {
  threeDay(3, '3D'),
  week(7, '1W'),
  month(30, '1M');

  const PerfWindow(this.days, this.label);

  final int days;
  final String label;
}

/// Today's calendar date in IST as `YYYY-MM-DD`, independent of the device
/// timezone (IST is UTC+5:30, no DST). Matches how the engine keys its rows.
String istTodayString() {
  final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${ist.year}-${two(ist.month)}-${two(ist.day)}';
}

/// Signal ID waiting for deep-link navigation after a notification tap.
final pendingSignalIdProvider = StateProvider<String?>((ref) => null);

/// Foreground FCM notification waiting to be shown as an in-app banner.
final fcmForegroundProvider = StateProvider<FcmForegroundNotif?>((ref) => null);
