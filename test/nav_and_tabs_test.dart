import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumin_india/app/nav_shell.dart';
import 'package:lumin_india/features/session/session_page.dart';
import 'package:lumin_india/features/settings/auto_trade_page.dart';
import 'package:lumin_india/features/settings/settings_page.dart';
import 'package:lumin_india/features/signals/models.dart';
import 'package:lumin_india/features/signals/signals_providers.dart';
import 'package:lumin_india/theme.dart';

const _pulseClosed = EnginePulse(
  sessionState: 'CLOSED',
  signalsToday: 0,
  uptimeSeconds: 7500,
);


Widget _wrap(Widget child, {EnginePulse pulse = _pulseClosed,
    List<IndiaSignal> signals = const [],
    List<SignalOutcome> outcomes = const [],
    List<SessionSummary> summaries = const []}) {
  return ProviderScope(
    overrides: [
      pulseProvider.overrideWith((ref) => Future.value(pulse)),
      signalsProvider.overrideWith((ref) => Future.value(signals)),
      outcomesProvider.overrideWith((ref) => Future.value(outcomes)),
      sessionSummariesProvider.overrideWith((ref) => Future.value(summaries)),
    ],
    child: MaterialApp(theme: buildLuminIndiaTheme(), home: child),
  );
}

void main() {
  testWidgets('NavShell renders three tabs and switches between them',
      (tester) async {
    await tester.pumpWidget(_wrap(const NavShell()));
    await tester.pump();

    expect(find.text('Signals'), findsOneWidget);
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Session'));
    await tester.pump();
    expect(find.text('MARKET CLOSED'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Auto-Trade'), findsOneWidget);

    // Unmount to cancel the feed's periodic refresh timer.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SessionPage shows open state, signal count and empty outcomes',
      (tester) async {
    const pulse = EnginePulse(
      sessionState: 'OPEN',
      signalsToday: 2,
      uptimeSeconds: 600,
    );

    await tester.pumpWidget(_wrap(const SessionPage(), pulse: pulse));
    await tester.pump();

    expect(find.text('MARKET OPEN'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // signalsToday from pulse
    expect(find.text('No resolved outcomes yet today'), findsOneWidget);
  });

  testWidgets('SettingsPage shows engine status and version',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsPage()));
    await tester.pump();

    expect(find.text('Signal engine'), findsOneWidget);
    expect(find.text('CLOSED · up 2h 5m'), findsOneWidget);
    expect(find.text(kAppVersion), findsOneWidget);
  });

  testWidgets('AutoTradePage is gated while engine reports disabled',
      (tester) async {
    await tester.pumpWidget(_wrap(const AutoTradePage()));
    await tester.pump();

    expect(find.text('Coming Soon'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('AutoTradePage acknowledges engine-enabled state without controls',
      (tester) async {
    const enabled = EnginePulse(
      sessionState: 'OPEN',
      signalsToday: 0,
      uptimeSeconds: 60,
      autoExecution: true,
    );
    await tester.pumpWidget(_wrap(const AutoTradePage(), pulse: enabled));
    await tester.pump();

    expect(find.text('Enabled at the engine'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });
}
