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
    this.currentPrice,
    this.livePoints,
    this.livePct,
    this.status = 'OPEN',
    this.resultPct,
    this.resultPoints,
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

  /// Live overlay the engine adds to open signals (absent otherwise): the
  /// symbol's current price and running result signed for the subscriber.
  /// ``livePct`` is the cross-instrument-comparable running % (points/entry).
  final double? currentPrice;
  final double? livePoints;
  final double? livePct;

  /// Outcome status joined from the engine: OPEN until the monitor resolves
  /// the signal (TP1_HIT / SL_HIT / EXPIRED, or the two-target outcomes
  /// TP1_BE / TP2_HIT / TP1_EXPIRED). ``resultPct`` / ``resultPoints`` are the
  /// realised, signed result once resolved (null while OPEN; position-weighted
  /// across both legs for two-target outcomes).
  final String status;
  final double? resultPct;
  final double? resultPoints;

  bool get isLong => direction == 'LONG';

  bool get hasLivePrice => currentPrice != null && currentPrice! > 0;

  bool get isResolved => status.isNotEmpty && status != 'OPEN';

  /// Two-target plan (engine Session 19): every TP1-banked outcome is a win —
  /// TP1_HIT (legacy single-target), TP2_HIT (full winner), TP1_BE (runner
  /// scratched at break-even) and TP1_EXPIRED (runner open at the close).
  /// result_pct arrives position-weighted from the engine.
  bool get isWin =>
      status == 'TP1_HIT' ||
      status == 'TP2_HIT' ||
      status == 'TP1_BE' ||
      status == 'TP1_EXPIRED';
  bool get isLoss => status == 'SL_HIT';
  bool get isExpired => status == 'EXPIRED';

  /// Short badge label for the card/detail.
  String get statusLabel {
    switch (status) {
      case 'TP1_HIT':
        return 'TP1 HIT';
      case 'TP2_HIT':
        return 'TP2 HIT';
      case 'TP1_BE':
        return 'TP1 + BE';
      case 'TP1_EXPIRED':
        return 'TP1 + EXP';
      case 'SL_HIT':
        return 'SL HIT';
      case 'EXPIRED':
        return 'EXPIRED';
      default:
        return 'OPEN';
    }
  }

  /// Fraction of the way from entry to TP1 (clamped 0..1), for a progress bar.
  double get progressToTp1 {
    if (!hasLivePrice) return 0;
    final span = (tp1 - entry).abs();
    if (span <= 0) return 0;
    final moved = isLong ? (currentPrice! - entry) : (entry - currentPrice!);
    final f = moved / span;
    return f.isNaN ? 0 : f.clamp(0.0, 1.0);
  }

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
        currentPrice:
            json['current_price'] == null ? null : _asDouble(json['current_price']),
        livePoints:
            json['live_points'] == null ? null : _asDouble(json['live_points']),
        livePct: json['live_pct'] == null ? null : _asDouble(json['live_pct']),
        status: _asString(json['status']).isEmpty
            ? 'OPEN'
            : _asString(json['status']),
        resultPct:
            json['result_pct'] == null ? null : _asDouble(json['result_pct']),
        resultPoints: json['result_points'] == null
            ? null
            : _asDouble(json['result_points']),
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
    this.tp1BeCount = 0,
    this.tp2Count = 0,
    this.tp1ExpiredCount = 0,
    this.totalPct = 0,
    this.avgPct = 0,
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

  /// Two-target plan outcome counts (0 on rows written before Session 19).
  final int tp1BeCount;
  final int tp2Count;
  final int tp1ExpiredCount;

  /// Cross-instrument-comparable P&L: cumulative % across the day's resolved
  /// signals and the average % per signal. Summed raw points are meaningless
  /// across a 46-base universe — % is the honest ledger.
  final double totalPct;
  final double avgPct;

  /// Wins = every TP1-banked outcome (two-target plan).
  int get winCount => tp1Count + tp2Count + tp1BeCount + tp1ExpiredCount;
  int get resolvedCount =>
      winCount + slCount + expiredCount;
  bool get hasOutcomes => resolvedCount > 0;
  double get winRate =>
      resolvedCount == 0 ? 0 : winCount / resolvedCount * 100;

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
      tp1BeCount: _asInt(json['tp1_be_count']),
      tp2Count: _asInt(json['tp2_count']),
      tp1ExpiredCount: _asInt(json['tp1_expired_count']),
      totalPoints: _asDouble(json['total_points']),
      totalPct: _asDouble(json['total_pct']),
      avgPct: _asDouble(json['avg_pct']),
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
    this.pct = 0,
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

  /// Signed % return (points/entry) — comparable across instruments, unlike
  /// raw points. The session ledger aggregates this, not points.
  final double pct;
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

  /// TP1-banked outcomes are wins (two-target plan — see IndiaSignal.isWin).
  bool get isWin =>
      outcome == 'TP1_HIT' ||
      outcome == 'TP2_HIT' ||
      outcome == 'TP1_BE' ||
      outcome == 'TP1_EXPIRED';
  bool get isLoss => outcome == 'SL_HIT';
  bool get isExpired => outcome == 'EXPIRED';

  /// Short badge label for the outcome row.
  String get shortLabel {
    switch (outcome) {
      case 'TP1_HIT':
        return 'TP1';
      case 'TP2_HIT':
        return 'TP2';
      case 'TP1_BE':
        return 'TP1+BE';
      case 'TP1_EXPIRED':
        return 'TP1+EXP';
      case 'SL_HIT':
        return 'SL';
      default:
        return 'EXP';
    }
  }

  factory SignalOutcome.fromJson(Map<String, dynamic> json) => SignalOutcome(
        signalId: _asString(json['signal_id']),
        outcome: _asString(json['outcome']),
        exitPrice: _asDouble(json['exit_price']),
        points: _asDouble(json['points']),
        pct: _asDouble(json['pct']),
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

/// FCM foreground notification data — shown as an in-app banner.
/// Never includes price targets (CLAUDE.md hard limit).
class FcmForegroundNotif {
  const FcmForegroundNotif({
    required this.signalId,
    required this.symbol,
    required this.direction,
    required this.tier,
  });

  final String signalId;
  final String symbol;
  final String direction;
  final String tier;
}

class EnginePulse {
  const EnginePulse({
    required this.sessionState,
    required this.signalsToday,
    required this.uptimeSeconds,
    this.autoExecution = false,
    this.allowedBases = const [],
  });

  final String sessionState;
  final int signalsToday;
  final int uptimeSeconds;

  /// The bases the engine is actually scanning (from /api/pulse). Drives the
  /// session status line so it reflects the real universe, not a hardcoded
  /// "NIFTY and BANKNIFTY".
  final List<String> allowedBases;

  /// Phase 2 flag from the engine. Gates the Auto-Trade settings screen —
  /// it stays "Coming Soon" until the engine reports true.
  final bool autoExecution;

  bool get isOpen => sessionState == 'OPEN';

  factory EnginePulse.fromJson(Map<String, dynamic> json) => EnginePulse(
        sessionState: _asString(json['session_state']),
        signalsToday: _asInt(json['signals_today']),
        uptimeSeconds: _asInt(json['uptime_seconds']),
        autoExecution: json['auto_execution'] == true,
        allowedBases: (json['allowed_bases'] is List)
            ? (json['allowed_bases'] as List)
                .map((e) => e.toString())
                .toList()
            : const [],
      );
}
