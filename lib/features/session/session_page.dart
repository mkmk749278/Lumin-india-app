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
    final outcomes = ref.watch(outcomesProvider);
    final summaries = ref.watch(sessionSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SESSION')),
      body: RefreshIndicator(
        color: LuminColors.accent,
        backgroundColor: LuminColors.bgCard,
        onRefresh: () async {
          ref.invalidate(pulseProvider);
          ref.invalidate(outcomesProvider);
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
            _QualityWindowCard(summaries: summaries.valueOrNull ?? const []),
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

    final tp1 = outcomes.where((o) => o.isWin).length;
    final sl = outcomes.where((o) => o.isLoss).length;
    final expired = outcomes.where((o) => o.isExpired).length;
    // % is the cross-instrument-comparable measure — summing raw points across a
    // 46-base universe is meaningless (it just weights by price level).
    final netPct = outcomes.fold<double>(0, (sum, o) => sum + o.pct);
    final avgPct = outcomes.isEmpty ? 0.0 : netPct / outcomes.length;
    final winRate = outcomes.isEmpty ? 0.0 : tp1 / outcomes.length * 100;

    return _Card(
      label: 'TODAY\'S OUTCOMES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(
                label: 'TP1 Hit',
                value: '$tp1',
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
    final String label;
    if (outcome.isWin) {
      color = LuminColors.success;
      label = 'TP1';
    } else if (outcome.isLoss) {
      color = LuminColors.loss;
      label = 'SL';
    } else {
      color = LuminColors.textMuted;
      label = 'EXP';
    }

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

// ── 30-day quality window card ────────────────────────────────────────────────

class _QualityWindowCard extends StatelessWidget {
  const _QualityWindowCard({required this.summaries});

  final List<SessionSummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const _Card(
        label: '30-DAY QUALITY WINDOW',
        child: Text(
          'First session summary written at 15:30 IST on the first trading day',
          style: TextStyle(color: LuminColors.textMuted, fontSize: 13),
        ),
      );
    }

    final totalSignals = summaries.fold<int>(0, (s, r) => s + r.signalCount);
    final totalTp1 = summaries.fold<int>(0, (s, r) => s + r.tp1Count);
    final totalResolved = summaries.fold<int>(0, (s, r) => s + r.resolvedCount);
    final totalPct = summaries.fold<double>(0.0, (s, r) => s + r.totalPct);
    final overallWin =
        totalResolved == 0 ? 0.0 : totalTp1 / totalResolved * 100;

    return _Card(
      label: '${summaries.length}-DAY QUALITY WINDOW',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(label: 'Signals', value: '$totalSignals'),
              _Stat(
                label: 'TP1 Win %',
                value: '${overallWin.toStringAsFixed(0)}%',
                color:
                    overallWin >= 50 ? LuminColors.success : LuminColors.loss,
              ),
              _Stat(
                label: 'Net P&L',
                value:
                    '${totalPct >= 0 ? '+' : ''}${totalPct.toStringAsFixed(2)}%',
                color: totalPct >= 0 ? LuminColors.success : LuminColors.loss,
              ),
            ],
          ),
          const SizedBox(height: LuminSpacing.md),
          const Divider(color: LuminColors.bgElevated, height: 1),
          const SizedBox(height: LuminSpacing.sm),
          ...summaries.take(10).map((s) => _SummaryRow(summary: s)),
          if (summaries.length > 10) ...[
            const SizedBox(height: LuminSpacing.sm),
            Text(
              '+ ${summaries.length - 10} earlier sessions',
              style: const TextStyle(
                color: LuminColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
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
