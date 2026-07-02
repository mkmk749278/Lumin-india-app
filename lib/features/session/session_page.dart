/// Session tab — today's trading session at a glance.
///
/// Everything here derives from the two live endpoints the app already
/// polls: /api/pulse (session state, today's count) and /api/signals
/// (per-tier and per-direction breakdown, computed client-side).
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
    final signals = ref.watch(signalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SESSION')),
      body: RefreshIndicator(
        color: LuminColors.accent,
        backgroundColor: LuminColors.bgCard,
        onRefresh: () async {
          ref.invalidate(pulseProvider);
          ref.invalidate(signalsProvider);
          await ref.read(pulseProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(LuminSpacing.lg),
          children: [
            _StateCard(pulse: pulse.valueOrNull, error: pulse.hasError),
            const SizedBox(height: LuminSpacing.lg),
            _TodayCard(
              pulse: pulse.valueOrNull,
              signals: signals.valueOrNull ?? const [],
            ),
            const SizedBox(height: LuminSpacing.lg),
            const _HoursCard(),
          ],
        ),
      ),
    );
  }
}

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
      sub = 'Scanning NIFTY and BANKNIFTY every 30 seconds';
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({this.pulse, required this.signals});

  final EnginePulse? pulse;
  final List<IndiaSignal> signals;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = signals.where((s) {
      final c = s.createdAt;
      return c != null &&
          c.year == now.year &&
          c.month == now.month &&
          c.day == now.day;
    }).toList();

    final aPlus = today.where((s) => s.tier == 'A+').length;
    final b = today.where((s) => s.tier == 'B').length;
    final longs = today.where((s) => s.isLong).length;
    final shorts = today.length - longs;

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
          const Text(
            'TODAY',
            style: TextStyle(
              color: LuminColors.textMuted,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: LuminSpacing.lg),
          Row(
            children: [
              _Stat(
                label: 'Signals',
                value: '${pulse?.signalsToday ?? today.length}',
              ),
              _Stat(
                label: 'A+',
                value: '$aPlus',
                color: LuminColors.success,
              ),
              _Stat(label: 'B', value: '$b', color: LuminColors.warn),
              _Stat(
                label: 'Long / Short',
                value: '$longs / $shorts',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
              fontSize: 20,
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
          _HoursRow(label: 'Last signal', value: '15:20 IST'),
          SizedBox(height: LuminSpacing.sm),
          _HoursRow(label: 'Trading days', value: 'Mon–Fri, NSE holidays excluded'),
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
