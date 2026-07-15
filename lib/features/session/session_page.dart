/// Session tab — today's session at a glance + 30-day quality window.
///
/// Data sources (all from the engine API):
///   /api/pulse          → session state, signal count today
///   /api/outcomes       → today's TP1/SL/EXPIRED outcomes + net points
///   /api/session-summary → 30-day daily ledger
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/tokens.dart';
import '../signals/models.dart';
import '../signals/signals_providers.dart';

class SessionPage extends ConsumerWidget {
  const SessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulse = ref.watch(pulseProvider);
    final outcomes = ref.watch(todayOutcomesProvider);
    final summaries = ref.watch(sessionSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SESSION')),
      body: RefreshIndicator(
        color: LuminColors.accent,
        backgroundColor: LuminColors.bgCard,
        onRefresh: () async {
          ref.invalidate(pulseProvider);
          ref.invalidate(todayOutcomesProvider);
          ref.invalidate(sessionSummariesProvider);
          await ref.read(pulseProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(LuminSpacing.lg),
          children: [
            _StateCard(pulse: pulse.valueOrNull, error: pulse.hasError),
            const SizedBox(height: LuminSpacing.lg),
            _TodayStatsCard(pulse: pulse.valueOrNull),
            const SizedBox(height: LuminSpacing.lg),
            _OutcomesCard(outcomes: outcomes.valueOrNull ?? const []),
            const SizedBox(height: LuminSpacing.lg),
            _PerformanceWindowCard(summaries: summaries.valueOrNull ?? const []),
            const SizedBox(height: LuminSpacing.lg),
            const _HoursCard(),
          ],
        ),
      ),
    );
  }
}

// ── Session state card ────────────────────────────────────────────────────────

class _StateCard extends StatelessWidget {
  const _StateCard({this.pulse, this.error = false});

  final EnginePulse? pulse;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final String headline;
    final String sub;
    final Color color;

    if (error) {
      headline = 'ENGINE UNREACHABLE';
      sub = 'Pull to retry';
      color = LuminColors.loss;
    } else if (pulse == null) {
      headline = 'CONNECTING';
      sub = 'Reaching the signal engine…';
      color = LuminColors.textMuted;
    } else if (pulse!.isOpen) {
      headline = 'MARKET OPEN';
      final n = pulse!.allowedBases.length;
      sub = n > 0
          ? 'Scanning $n instrument${n == 1 ? '' : 's'} every 30 seconds'
          : 'Scanning every 30 seconds';
      color = LuminColors.success;
    } else if (pulse!.sessionState == 'PRE_OPEN') {
      headline = 'PRE-OPEN';
      sub = 'Scanning starts at 09:15 IST';
      color = LuminColors.warn;
    } else {
      headline = 'MARKET CLOSED';
      sub = 'Next session 09:15 IST on the next trading day';
      color = LuminColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(LuminSpacing.xl),
      decoration: BoxDecoration(
        color: LuminColors.bgCard,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        border: Border.all(color: LuminColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: LuminSpacing.sm),
          Text(
            sub,
            style: const TextStyle(
              color: LuminColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today signals card ────────────────────────────────────────────────────────

class _TodayStatsCard extends StatelessWidget {
  const _TodayStatsCard({this.pulse});

  final EnginePulse? pulse;

  @override
  Widget build(BuildContext context) {
    return _Card(
      label: 'TODAY',
      child: Row(
        children: [
          _Stat(
            label: 'Signals',
            value: '${pulse?.signalsToday ?? '—'}',
          ),
          _Stat(
            label: 'Uptime',
            value: pulse == null ? '—' : _fmtUptime(pulse!.uptimeSeconds),
          ),
          _Stat(
            label: 'State',
            value: pulse?.sessionState ?? '—',
            color: pulse?.isOpen == true ? LuminColors.success : null,
          ),
        ],
      ),
    );
  }

  String _fmtUptime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

// ── Today outcomes card ───────────────────────────────────────────────────────

class _OutcomesCard extends StatelessWidget {
  const _OutcomesCard({required this.outcomes});

  final List<SignalOutcome> outcomes;

  @override
  Widget build(BuildContext context) {
    if (outcomes.isEmpty) {
      return const _Card(
        label: 'TODAY\'S OUTCOMES',
        child: Text(
          'No resolved outcomes yet today',
          style: TextStyle(color: LuminColors.textMuted, fontSize: 13),
        ),
      );
    }

    // Wins = every TP1-banked outcome (two-target plan: TP1/TP2/BE/TP1-exp).
    final wins = outcomes.where((o) => o.isWin).length;
    final sl = outcomes.where((o) => o.isLoss).length;
    final expired = outcomes.where((o) => o.isExpired).length;
    // % is the cross-instrument-comparable measure — summing raw points across a
    // 46-base universe is meaningless (it just weights by price level).
    final netPct = outcomes.fold<double>(0, (sum, o) => sum + o.pct);
    final avgPct = outcomes.isEmpty ? 0.0 : netPct / outcomes.length;
    final winRate = outcomes.isEmpty ? 0.0 : wins / outcomes.length * 100;

    return _Card(
      label: 'TODAY\'S OUTCOMES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(
                label: 'Wins',
                value: '$wins',
                color: LuminColors.success,
              ),
              _Stat(
                label: 'SL Hit',
                value: '$sl',
                color: LuminColors.loss,
              ),
              _Stat(label: 'Expired', value: '$expired'),
              _Stat(
                label: 'Win %',
                value: '${winRate.toStringAsFixed(0)}%',
                color: winRate >= 50 ? LuminColors.success : LuminColors.loss,
              ),
            ],
          ),
          const SizedBox(height: LuminSpacing.md),
          Row(
            children: [
              _Stat(
                label: 'Net P&L',
                value: '${netPct >= 0 ? '+' : ''}${netPct.toStringAsFixed(2)}%',
                color: netPct >= 0 ? LuminColors.success : LuminColors.loss,
              ),
              _Stat(
                label: 'Avg / signal',
                value: '${avgPct >= 0 ? '+' : ''}${avgPct.toStringAsFixed(2)}%',
                color: avgPct >= 0 ? LuminColors.success : LuminColors.loss,
              ),
            ],
          ),
          if (outcomes.isNotEmpty) ...[
            const SizedBox(height: LuminSpacing.md),
            const Divider(color: LuminColors.bgElevated, height: 1),
            const SizedBox(height: LuminSpacing.sm),
            ...outcomes.take(5).map((o) => _OutcomeRow(outcome: o)),
          ],
        ],
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({required this.outcome});

  final SignalOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (outcome.isWin) {
      color = LuminColors.success;
    } else if (outcome.isLoss) {
      color = LuminColors.loss;
    } else {
      color = LuminColors.textMuted;
    }
    final label = outcome.shortLabel;

    final pct = outcome.pct;
    final pctStr = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
    final pts = outcome.points;
    final ptsStr = '${pts >= 0 ? '+' : ''}${pts.toStringAsFixed(1)} pts';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: LuminSpacing.sm),
          Text(
            '${outcome.base} ${outcome.direction}',
            style: const TextStyle(
              color: LuminColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          // Raw points as secondary context — not comparable across bases.
          Text(
            ptsStr,
            style: const TextStyle(
              color: LuminColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: LuminSpacing.sm),
          Text(
            pctStr,
            style: TextStyle(
              color: pct >= 0 ? LuminColors.success : LuminColors.loss,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Selectable performance-window card ────────────────────────────────────────
//
// The daily quality ledger, aggregated over a look-back the subscriber picks
// (3D / 1W / 1M, default 1W). Distinct from the TODAY card above: this is the
// settled-session ledger, so a live session in progress shows once it closes
// at 15:30 IST and its summary row is written.

class _PerformanceWindowCard extends ConsumerWidget {
  const _PerformanceWindowCard({required this.summaries});

  final List<SessionSummary> summaries;

  /// Sessions whose date falls within `window.days` calendar days back from
  /// today (IST). Newest first, as the ledger arrives.
  List<SessionSummary> _inWindow(PerfWindow window) {
    final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final today = DateTime(ist.year, ist.month, ist.day);
    final cutoff = today.subtract(Duration(days: window.days - 1));
    return summaries.where((s) {
      final d = DateTime.tryParse(s.date);
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(cutoff);
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(perfWindowProvider);
    final rows = _inWindow(window);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuminSpacing.xl),
      decoration: BoxDecoration(
        color: LuminColors.bgCard,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        border: Border.all(color: LuminColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'QUALITY WINDOW',
                  style: TextStyle(
                    color: LuminColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              _WindowSelector(
                selected: window,
                onSelect: (w) =>
                    ref.read(perfWindowProvider.notifier).state = w,
              ),
            ],
          ),
          const SizedBox(height: LuminSpacing.lg),
          if (rows.isEmpty)
            const Text(
              'No closed sessions in this window yet',
              style: TextStyle(color: LuminColors.textMuted, fontSize: 13),
            )
          else
            _WindowBody(rows: rows),
        ],
      ),
    );
  }
}

class _WindowBody extends StatelessWidget {
  const _WindowBody({required this.rows});

  final List<SessionSummary> rows;

  @override
  Widget build(BuildContext context) {
    final totalSignals = rows.fold<int>(0, (s, r) => s + r.signalCount);
    final totalPct = rows.fold<double>(0.0, (s, r) => s + r.totalPct);
    // Win = every TP1-banked outcome (TP1_HIT/TP1_BE/TP1_EXPIRED/TP2_HIT), not
    // just literal TP1_HIT — matches SessionSummary.winRate used by the rows
    // below. Counting r.tp1Count here read 0% on days where every win ran to
    // TP2, trailed to BE, or expired past TP1 (e.g. 2026-07-14).
    final overallWin = SessionSummary.windowWinRate(rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Stat(label: 'Signals', value: '$totalSignals'),
            _Stat(
              label: 'TP1 Win %',
              value: '${overallWin.toStringAsFixed(0)}%',
              color: overallWin >= 50 ? LuminColors.success : LuminColors.loss,
            ),
            _Stat(
              label: 'Net P&L',
              value: '${totalPct >= 0 ? '+' : ''}${totalPct.toStringAsFixed(2)}%',
              color: totalPct >= 0 ? LuminColors.success : LuminColors.loss,
            ),
          ],
        ),
        const SizedBox(height: LuminSpacing.md),
        const Divider(color: LuminColors.bgElevated, height: 1),
        const SizedBox(height: LuminSpacing.sm),
        ...rows.take(10).map((s) => _SummaryRow(summary: s)),
        if (rows.length > 10) ...[
          const SizedBox(height: LuminSpacing.sm),
          Text(
            '+ ${rows.length - 10} earlier sessions',
            style: const TextStyle(
              color: LuminColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _WindowSelector extends StatelessWidget {
  const _WindowSelector({required this.selected, required this.onSelect});

  final PerfWindow selected;
  final ValueChanged<PerfWindow> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final w in PerfWindow.values)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => onSelect(w),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: w == selected
                      ? LuminColors.accent.withAlpha(30)
                      : LuminColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: w == selected
                        ? LuminColors.accent
                        : LuminColors.cardBorder,
                  ),
                ),
                child: Text(
                  w.label,
                  style: TextStyle(
                    color: w == selected
                        ? LuminColors.accent
                        : LuminColors.textMuted,
                    fontSize: 12,
                    fontWeight:
                        w == selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final pct = summary.totalPct;
    final pctStr = summary.hasOutcomes
        ? '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%'
        : '—';
    final winStr = summary.hasOutcomes
        ? '${summary.winRate.toStringAsFixed(0)}%'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              summary.date,
              style: const TextStyle(
                color: LuminColors.textMuted,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${summary.signalCount}',
              style: const TextStyle(
                color: LuminColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              winStr,
              style: TextStyle(
                color: summary.hasOutcomes
                    ? (summary.winRate >= 50
                        ? LuminColors.success
                        : LuminColors.loss)
                    : LuminColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            pctStr,
            style: TextStyle(
              color: summary.hasOutcomes
                  ? (pct >= 0 ? LuminColors.success : LuminColors.loss)
                  : LuminColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Market hours card ─────────────────────────────────────────────────────────

class _HoursCard extends StatelessWidget {
  const _HoursCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuminSpacing.lg),
      decoration: BoxDecoration(
        color: LuminColors.bgCard,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        border: Border.all(color: LuminColors.cardBorder),
      ),
      child: const Column(
        children: [
          _HoursRow(label: 'Market hours', value: '09:15 – 15:30 IST'),
          SizedBox(height: LuminSpacing.sm),
          _HoursRow(label: 'Last signal window', value: '≤ 15:20 IST'),
          SizedBox(height: LuminSpacing.sm),
          _HoursRow(
            label: 'Trading days',
            value: 'Mon–Fri, NSE holidays excluded',
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: LuminColors.textMuted, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: LuminColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Shared card container ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LuminSpacing.xl),
      decoration: BoxDecoration(
        color: LuminColors.bgCard,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        border: Border.all(color: LuminColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LuminColors.textMuted,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: LuminSpacing.lg),
          child,
        ],
      ),
    );
  }
}

// ── Shared stat widget ────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? LuminColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: LuminColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
