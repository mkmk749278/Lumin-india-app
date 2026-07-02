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
