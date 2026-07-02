/// Signal + engine-pulse models.
///
/// Field names mirror the engine's `india_signals` SQLite table exactly
/// (lumina-india-engine `src/signal_store.py`) — the API returns raw rows.
library;

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

class EnginePulse {
  const EnginePulse({
    required this.sessionState,
    required this.signalsToday,
    required this.uptimeSeconds,
  });

  final String sessionState;
  final int signalsToday;
  final int uptimeSeconds;

  bool get isOpen => sessionState == 'OPEN';

  factory EnginePulse.fromJson(Map<String, dynamic> json) => EnginePulse(
        sessionState: _asString(json['session_state']),
        signalsToday: _asInt(json['signals_today']),
        uptimeSeconds: _asInt(json['uptime_seconds']),
      );
}
