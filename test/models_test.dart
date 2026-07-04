import 'package:flutter_test/flutter_test.dart';
import 'package:lumin_india/features/signals/models.dart';

void main() {
  group('IndiaSignal.fromJson', () {
    test('parses a full engine row', () {
      final signal = IndiaSignal.fromJson({
        'signal_id': 'sig-001',
        'symbol': 'NSE:NIFTY26JULFUT-FF',
        'base': 'NIFTY',
        'direction': 'LONG',
        'setup_class': 'OPENING_RANGE_BREAKOUT',
        'entry': 24500.5,
        'sl': 24400,
        'tp1': 24700.25,
        'tp2': 0,
        'rr_ratio': 2.0,
        'lot_size': 75,
        'confidence': 82.0,
        'tier': 'A+',
        'regime_60m': 'TRENDING_UP',
        'regime_daily': 'RANGING',
        'setup_reason': 'ORB breakout with 1.6x volume',
        'vix_at_entry': 14.2,
        'expiry_date': '2026-07-07',
        'days_to_expiry': 5,
        'created_at': '2026-07-02 10:15:33',
      });

      expect(signal.signalId, 'sig-001');
      expect(signal.base, 'NIFTY');
      expect(signal.isLong, true);
      expect(signal.entry, 24500.5);
      expect(signal.sl, 24400.0);
      expect(signal.tp1, 24700.25);
      expect(signal.tp2, 0.0);
      expect(signal.lotSize, 75);
      expect(signal.tier, 'A+');
      expect(signal.createdAt, isNotNull);
      expect(signal.createdAt!.hour, 10);
      expect(signal.createdAt!.minute, 15);
      expect(signal.expiryDate, '2026-07-07');
    });

    test('tolerates nulls and missing fields', () {
      final signal = IndiaSignal.fromJson(const {
        'signal_id': 'sig-002',
        'direction': 'SHORT',
      });

      expect(signal.signalId, 'sig-002');
      expect(signal.isLong, false);
      expect(signal.entry, 0.0);
      expect(signal.lotSize, 0);
      expect(signal.createdAt, isNull);
      expect(signal.setupReason, '');
    });
  });

  group('SessionSummary.fromJson', () {
    test('parses a full summary row', () {
      final s = SessionSummary.fromJson({
        'date': '2026-07-07',
        'signal_count': 4,
        'a_plus_count': 2,
        'b_count': 2,
        'avg_confidence': 79.5,
        'total_suppressed': 12,
        'gates_fired': '{"cooldown_gate": 8, "min_atr_gate": 4}',
        'tp1_count': 3,
        'sl_count': 1,
        'expired_count': 0,
        'total_points': 120.0,
      });

      expect(s.date, '2026-07-07');
      expect(s.signalCount, 4);
      expect(s.aPlusCount, 2);
      expect(s.tp1Count, 3);
      expect(s.slCount, 1);
      expect(s.expiredCount, 0);
      expect(s.totalPoints, 120.0);
      expect(s.resolvedCount, 4);
      expect(s.winRate, closeTo(75.0, 0.01));
      expect(s.gatesFired['cooldown_gate'], 8);
      expect(s.gatesFired['min_atr_gate'], 4);
    });

    test('parses gates_fired when already a map', () {
      final s = SessionSummary.fromJson({
        'date': '2026-07-07',
        'signal_count': 1,
        'a_plus_count': 0,
        'b_count': 1,
        'avg_confidence': 70.0,
        'total_suppressed': 3,
        'gates_fired': {'cooldown_gate': 3},
        'tp1_count': 0,
        'sl_count': 1,
        'expired_count': 0,
        'total_points': -50.0,
      });

      expect(s.gatesFired['cooldown_gate'], 3);
      expect(s.hasOutcomes, true);
      expect(s.winRate, 0.0);
    });

    test('empty day has zeroes and no outcomes', () {
      final s = SessionSummary.fromJson({
        'date': '2026-07-07',
        'signal_count': 0,
        'a_plus_count': 0,
        'b_count': 0,
        'avg_confidence': 0.0,
        'total_suppressed': 0,
        'gates_fired': '{}',
        'tp1_count': 0,
        'sl_count': 0,
        'expired_count': 0,
        'total_points': 0.0,
      });

      expect(s.hasOutcomes, false);
      expect(s.resolvedCount, 0);
      expect(s.gatesFired, isEmpty);
    });
  });

  group('SignalOutcome.fromJson', () {
    test('parses a TP1_HIT outcome', () {
      final o = SignalOutcome.fromJson({
        'signal_id': 'sig-LONG',
        'outcome': 'TP1_HIT',
        'exit_price': 24700.0,
        'points': 100.0,
        'resolved_at': '2026-07-07 11:30:00',
        'symbol': 'NSE:NIFTY26JULFUT-FF',
        'base': 'NIFTY',
        'direction': 'LONG',
        'setup_class': 'ORB',
        'tier': 'A+',
        'entry': 24600.0,
        'sl': 24500.0,
        'tp1': 24700.0,
        'emitted_at': '2026-07-07 09:30:00',
      });

      expect(o.isWin, true);
      expect(o.isLoss, false);
      expect(o.isExpired, false);
      expect(o.points, 100.0);
      expect(o.base, 'NIFTY');
    });

    test('parses a SL_HIT outcome', () {
      final o = SignalOutcome.fromJson({
        'signal_id': 'sig-SHORT',
        'outcome': 'SL_HIT',
        'exit_price': 50200.0,
        'points': -60.0,
        'resolved_at': '2026-07-07 13:00:00',
        'symbol': 'NSE:BANKNIFTY26JULFUT-FF',
        'base': 'BANKNIFTY',
        'direction': 'SHORT',
        'setup_class': 'TPE',
        'tier': 'B',
        'entry': 50150.0,
        'sl': 50250.0,
        'tp1': 49950.0,
      });

      expect(o.isWin, false);
      expect(o.isLoss, true);
      expect(o.points, -60.0);
    });

    test('tolerates missing optional fields', () {
      final o = SignalOutcome.fromJson({
        'signal_id': 'sig-001',
        'outcome': 'EXPIRED',
        'exit_price': 0.0,
        'points': 0.0,
        'resolved_at': '2026-07-07 15:30:00',
      });

      expect(o.isExpired, true);
      expect(o.base, '');
      expect(o.emittedAt, isNull);
    });
  });

  group('EnginePulse.fromJson', () {
    test('parses pulse payload', () {
      final pulse = EnginePulse.fromJson(const {
        'session_state': 'OPEN',
        'signals_today': 3,
        'uptime_seconds': 4200,
      });

      expect(pulse.isOpen, true);
      expect(pulse.signalsToday, 3);
      expect(pulse.uptimeSeconds, 4200);
    });

    test('closed session is not open', () {
      final pulse = EnginePulse.fromJson(const {'session_state': 'CLOSED'});
      expect(pulse.isOpen, false);
      expect(pulse.signalsToday, 0);
    });
  });
}
