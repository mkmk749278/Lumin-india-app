/// Full signal detail. Shows tier only, never the raw confidence score
/// (CLAUDE.md hard limit).
library;

import 'package:flutter/material.dart';

import '../../shared/tokens.dart';
import 'models.dart';
import 'signal_card.dart' show formatIstTime, formatPrice;

class SignalDetailPage extends StatelessWidget {
  const SignalDetailPage({super.key, required this.signal});

  final IndiaSignal signal;

  @override
  Widget build(BuildContext context) {
    final directionColor =
        signal.isLong ? LuminColors.success : LuminColors.loss;

    return Scaffold(
      appBar: AppBar(title: Text(signal.base)),
      body: ListView(
        padding: const EdgeInsets.all(LuminSpacing.lg),
        children: [
          Row(
            children: [
              Text(
                signal.direction,
                style: TextStyle(
                  color: directionColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuminSpacing.lg,
                  vertical: LuminSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: tierColorFaint(signal.tier),
                  borderRadius: BorderRadius.circular(LuminRadii.pill),
                ),
                child: Text(
                  '${signal.tier} confidence',
                  style: TextStyle(
                    color: tierColor(signal.tier),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuminSpacing.xs),
          Text(
            signal.symbol,
            style: const TextStyle(color: LuminColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: LuminSpacing.xl),
          if (signal.hasLivePrice) ...[
            _LiveCard(signal: signal),
            const SizedBox(height: LuminSpacing.lg),
          ],
          _LevelsCard(signal: signal),
          const SizedBox(height: LuminSpacing.lg),
          _MetaCard(signal: signal),
          if (signal.setupReason.isNotEmpty) ...[
            const SizedBox(height: LuminSpacing.lg),
            _ReasonCard(reason: signal.setupReason),
          ],
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.signal});

  final IndiaSignal signal;

  @override
  Widget build(BuildContext context) {
    final pts = signal.livePoints ?? 0;
    final ptsColor = pts >= 0 ? LuminColors.success : LuminColors.loss;
    final sign = pts > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(LuminSpacing.lg),
      decoration: BoxDecoration(
        color: LuminColors.bgCard,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        border: Border.all(color: ptsColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'LIVE PRICE',
                style: TextStyle(
                  color: LuminColors.textMuted,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '$sign${pts.toStringAsFixed(1)} pts',
                style: TextStyle(
                  color: ptsColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuminSpacing.xs),
          Text(
            formatPrice(signal.currentPrice ?? 0),
            style: const TextStyle(
              color: LuminColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LuminSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(LuminRadii.pill),
            child: LinearProgressIndicator(
              value: signal.progressToTp1,
              minHeight: 6,
              backgroundColor: LuminColors.bgElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(LuminColors.success),
            ),
          ),
          const SizedBox(height: LuminSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Entry ${formatPrice(signal.entry)}',
                  style: const TextStyle(
                      color: LuminColors.textMuted, fontSize: 11)),
              Text('TP1 ${formatPrice(signal.tp1)}',
                  style: const TextStyle(
                      color: LuminColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelsCard extends StatelessWidget {
  const _LevelsCard({required this.signal});

  final IndiaSignal signal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuminSpacing.lg),
      decoration: BoxDecoration(
        color: LuminColors.bgCard,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        border: Border.all(color: LuminColors.cardBorder),
      ),
      child: Column(
        children: [
          _LevelRow(label: 'Entry', value: formatPrice(signal.entry)),
          const Divider(color: LuminColors.bgElevated, height: LuminSpacing.xl),
          _LevelRow(
            label: 'Stop Loss',
            value: formatPrice(signal.sl),
            color: LuminColors.loss,
          ),
          const Divider(color: LuminColors.bgElevated, height: LuminSpacing.xl),
          _LevelRow(
            label: 'Target 1',
            value: formatPrice(signal.tp1),
            color: LuminColors.success,
          ),
          if (signal.tp2 > 0) ...[
            const Divider(
                color: LuminColors.bgElevated, height: LuminSpacing.xl),
            _LevelRow(
              label: 'Target 2',
              value: formatPrice(signal.tp2),
              color: LuminColors.success,
            ),
          ],
          const Divider(color: LuminColors.bgElevated, height: LuminSpacing.xl),
          _LevelRow(
            label: 'Risk : Reward',
            value: '1 : ${signal.rrRatio.toStringAsFixed(1)}',
          ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style:
              const TextStyle(color: LuminColors.textSecondary, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color ?? LuminColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.signal});

  final IndiaSignal signal;

  String _pretty(String upperSnake) =>
      upperSnake.replaceAll('_', ' ').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Setup', _pretty(signal.setupClass)),
      MapEntry('Lot size', '${signal.lotSize}'),
      MapEntry('Time', formatIstTime(signal.createdAt)),
      if (signal.regime60m.isNotEmpty)
        MapEntry('Regime 60m', _pretty(signal.regime60m)),
      if (signal.vixAtEntry > 0)
        MapEntry('India VIX', signal.vixAtEntry.toStringAsFixed(1)),
      if (signal.expiryDate.isNotEmpty)
        MapEntry(
            'Expiry', '${signal.expiryDate} (${signal.daysToExpiry}d)'),
    ];

    return Container(
      padding: const EdgeInsets.all(LuminSpacing.lg),
      decoration: BoxDecoration(
        color: LuminColors.bgCard,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        border: Border.all(color: LuminColors.cardBorder),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: LuminSpacing.xs),
              child: Row(
                children: [
                  Text(
                    row.key,
                    style: const TextStyle(
                        color: LuminColors.textMuted, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    row.value,
                    style: const TextStyle(
                        color: LuminColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuminSpacing.lg),
      decoration: BoxDecoration(
        color: LuminColors.bgCard,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        border: Border.all(color: LuminColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHY THIS SIGNAL',
            style: TextStyle(
              color: LuminColors.textMuted,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: LuminSpacing.sm),
          Text(
            reason,
            style: const TextStyle(
              color: LuminColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
