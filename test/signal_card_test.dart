import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumin_india/features/signals/models.dart';
import 'package:lumin_india/features/signals/session_bar.dart';
import 'package:lumin_india/features/signals/signal_card.dart';
import 'package:lumin_india/theme.dart';

IndiaSignal _signal({String direction = 'LONG', String tier = 'A+'}) {
  return IndiaSignal.fromJson({
    'signal_id': 'sig-001',
    'symbol': 'NSE:BANKNIFTY26JULFUT-FF',
    'base': 'BANKNIFTY',
    'direction': direction,
    'setup_class': 'LIQUIDITY_SWEEP_REVERSAL',
    'entry': 52350.0,
    'sl': 52250.0,
    'tp1': 52550.0,
    'rr_ratio': 2.0,
    'lot_size': 35,
    'tier': tier,
    'created_at': '2026-07-02 11:42:00',
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildLuminIndiaTheme(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('SignalCard shows direction, symbol, levels, tier, time',
      (tester) async {
    await tester.pumpWidget(_wrap(SignalCard(signal: _signal())));

    expect(find.text('LONG'), findsOneWidget);
    expect(find.text('BANKNIFTY'), findsOneWidget);
    expect(find.text('52350.0'), findsOneWidget);
    expect(find.text('52250.0'), findsOneWidget);
    expect(find.text('52550.0'), findsOneWidget);
    expect(find.text('A+'), findsOneWidget);
    expect(find.text('11:42'), findsOneWidget);
  });

  testWidgets('SignalCard never renders the raw confidence score',
      (tester) async {
    await tester.pumpWidget(_wrap(SignalCard(signal: _signal())));
    expect(find.textContaining('82'), findsNothing);
  });

  testWidgets('SessionBar renders open state with signal count',
      (tester) async {
    const pulse = EnginePulse(
      sessionState: 'OPEN',
      signalsToday: 4,
      uptimeSeconds: 100,
    );
    await tester.pumpWidget(_wrap(const SessionBar(pulse: pulse)));

    expect(find.textContaining('Market Open'), findsOneWidget);
    expect(find.text('4 signals today'), findsOneWidget);
  });

  testWidgets('SessionBar renders closed state', (tester) async {
    const pulse = EnginePulse(
      sessionState: 'CLOSED',
      signalsToday: 0,
      uptimeSeconds: 100,
    );
    await tester.pumpWidget(_wrap(const SessionBar(pulse: pulse)));

    expect(find.text('Market Closed'), findsOneWidget);
  });

  testWidgets('SessionBar renders error state', (tester) async {
    await tester.pumpWidget(_wrap(const SessionBar(error: true)));
    expect(find.text('Engine unreachable'), findsOneWidget);
  });
}
