/// Signal + engine-pulse models.
///
/// Field names mirror the engine's `india_signals` SQLite table exactly
/// (lumina-india-engine `src/signal_store.py`) — the API returns raw rows.
library;

import 'dart:convert' show json;

double _asDouble(dynamic v) =>
    v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0);

int _asInt(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

String _asString(dynamic v) => v?.toString() ?? '';

class IndiaSignal {
  const IndiaSignal({
    required this.signalId,
    required this.symbol,
    required this.base,
    required this.direction,
    required this.setupClass,
    required this.entry,
    required this.sl,
    required this.tp1,
    required this.tp2,
    required this.rrRatio,
    required this.lotSize,
    required this.tier,
    required this.setupReason,
    required this.regime60m,
    required this.regimeDaily,
    required this.vixAtEntry,
    required this.expiryDate,
    required this.daysToExpiry,
    required this.createdAt,
  });

  final String signalId;
  final String symbol;
  final String base;
  final String direction;
  final String setupClass;
  final double entry;
  final double sl;
  final double tp1;
  final double tp2;
  final double rrRatio;
  final int lotSize;
  final String tier;
  final String setupReason;
  final String regime60m;
  final String regimeDaily;
  final double vixAtEntry;
  final String expiryDate;
  final int daysToExpiry;
  final DateTime? createdAt;

  bool get isLong => direction == 'LONG';

  /// `created_at` is written by SQLite in IST (container TZ) as
  /// `YYYY-MM-DD HH:MM:SS`, so it parses directly and displays as-is.
  static DateTime? _parseCreatedAt(dynamic raw) {
    final s = _asString(raw);
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  factory IndiaSignal.fromJson(Map<String, dynamic> json) => IndiaSignal(
        signalId: _asString(json['signal_id']),
        symbol: _asString(json['symbol']),
        base: _asString(json['base']),
        direction: _asString(json['direction']),
        setupClass: _asString(json['setup_class']),
        entry: _asDouble(json['entry']),
        sl: _asDouble(json['sl']),
        tp1: _asDouble(json['tp1']),
        tp2: _asDouble(json['tp2']),
        rrRatio: _asDouble(json['rr_ratio']),
        lotSize: _asInt(json['lot_size']),
        tier: _asString(json['tier']),
        setupReason: _asString(json['setup_reason']),
        regime60m: _asString(json['regime_60m']),
        regimeDaily: _asString(json['regime_daily']),
        vixAtEntry: _asDouble(json['vix_at_entry']),
        expiryDate: _asString(json['expiry_date']),
        daysToExpiry: _asInt(json['days_to_expiry']),
        createdAt: _parseCreatedAt(json['created_at']),
      );
}

/// One row from `india_session_summary` — the daily quality ledger.
class SessionSummary {
  const SessionSummary({
    required this.date,
    required this.signalCount,
    required this.aPlusCount,
    required this.bCount,
    required this.avgConfidence,
    required this.totalSuppressed,
    required this.gatesFired,
    required this.tp1Count,
    required this.slCount,
    required this.expiredCount,
    required this.totalPoints,
  });

  final String date;
  final int signalCount;
  final int aPlusCount;
  final int bCount;
  final double avgConfidence;
  final int totalSuppressed;
  final Map<String, int> gatesFired;
  final int tp1Count;
  final int slCount;
  final int expiredCount;
  final double totalPoints;

  bool get hasOutcomes => tp1Count + slCount + expiredCount > 0;
  int get resolvedCount => tp1Count + slCount + expiredCount;
  double get winRate =>
      resolvedCount == 0 ? 0 : tp1Count / resolvedCount * 100;

  static Map<String, int> _decodeGates(dynamic raw) {
    Map<String, dynamic> map = const {};
    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) map = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {for (final e in map.entries) e.key: _asInt(e.value)};
  }

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      date: _asString(json['date']),
      signalCount: _asInt(json['signal_count']),
      aPlusCount: _asInt(json['a_plus_count']),
      bCount: _asInt(json['b_count']),
      avgConfidence: _asDouble(json['avg_confidence']),
      totalSuppressed: _asInt(json['total_suppressed']),
      gatesFired: _decodeGates(json['gates_fired']),
      tp1Count: _asInt(json['tp1_count']),
      slCount: _asInt(json['sl_count']),
      expiredCount: _asInt(json['expired_count']),
      totalPoints: _asDouble(json['total_points']),
    );
  }
}

/// One row from `india_signal_outcomes` joined onto `india_signals`.
class SignalOutcome {
  const SignalOutcome({
    required this.signalId,
    required this.outcome,
    required this.exitPrice,
    required this.points,
    required this.resolvedAt,
    required this.symbol,
    required this.base,
    required this.direction,
    required this.setupClass,
    required this.tier,
    required this.entry,
    required this.sl,
    required this.tp1,
    this.emittedAt,
  });

  final String signalId;
  final String outcome;
  final double exitPrice;
  final double points;
  final String resolvedAt;
  final String symbol;
  final String base;
  final String direction;
  final String setupClass;
  final String tier;
  final double entry;
  final double sl;
  final double tp1;
  final String? emittedAt;

  bool get isWin => outcome == 'TP1_HIT';
  bool get isLoss => outcome == 'SL_HIT';
  bool get isExpired => outcome == 'EXPIRED';

  factory SignalOutcome.fromJson(Map<String, dynamic> json) => SignalOutcome(
        signalId: _asString(json['signal_id']),
        outcome: _asString(json['outcome']),
        exitPrice: _asDouble(json['exit_price']),
        points: _asDouble(json['points']),
        resolvedAt: _asString(json['resolved_at']),
        symbol: _asString(json['symbol']),
        base: _asString(json['base']),
        direction: _asString(json['direction']),
        setupClass: _asString(json['setup_class']),
        tier: _asString(json['tier']),
        entry: _asDouble(json['entry']),
        sl: _asDouble(json['sl']),
        tp1: _asDouble(json['tp1']),
        emittedAt: json['emitted_at']?.toString(),
      );
}

class EnginePulse {
  const EnginePulse({
    required this.sessionState,
    required this.signalsToday,
    required this.uptimeSeconds,
    this.autoExecution = false,
  });

  final String sessionState;
  final int signalsToday;
  final int uptimeSeconds;

  /// Phase 2 flag from the engine. Gates the Auto-Trade settings screen —
  /// it stays "Coming Soon" until the engine reports true.
  final bool autoExecution;

  bool get isOpen => sessionState == 'OPEN';

  factory EnginePulse.fromJson(Map<String, dynamic> json) => EnginePulse(
        sessionState: _asString(json['session_state']),
        signalsToday: _asInt(json['signals_today']),
        uptimeSeconds: _asInt(json['uptime_seconds']),
        autoExecution: json['auto_execution'] == true,
      );
}
