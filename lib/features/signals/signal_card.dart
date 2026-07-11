/// One signal in the feed. Actionable, not decorative (CLAUDE.md):
/// direction, symbol, entry, SL, TP1, tier, time — nothing more.
library;

import 'package:flutter/material.dart';

import '../../shared/tokens.dart';
import 'models.dart';

String formatIstTime(DateTime? dt) {
  if (dt == null) return '--:--';
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatPrice(double v) => v.toStringAsFixed(1);

/// Colour for an outcome status badge. Every TP1-banked outcome renders as a
/// win (two-target plan — TP2_HIT / TP1_BE / TP1_EXPIRED all booked TP1).
Color statusColor(String status) {
  switch (status) {
    case 'TP1_HIT':
    case 'TP2_HIT':
    case 'TP1_BE':
    case 'TP1_EXPIRED':
      return LuminColors.success;
    case 'SL_HIT':
      return LuminColors.loss;
    case 'EXPIRED':
      return LuminColors.warn;
    default:
      return LuminColors.textMuted;
  }
}

/// The signed result string for a signal: realised % once resolved, else the
/// running % while it is open and has a live price. Null when neither applies.
String? signalResultLabel(IndiaSignal s) {
  if (s.isResolved && s.resultPct != null) {
    final p = s.resultPct!;
    return '${p >= 0 ? '+' : ''}${p.toStringAsFixed(2)}%';
  }
  if (s.hasLivePrice && s.livePct != null) {
    final p = s.livePct!;
    return '${p >= 0 ? '+' : ''}${p.toStringAsFixed(2)}%';
  }
  return null;
}

class SignalCard extends StatelessWidget {
  const SignalCard({super.key, required this.signal, this.onTap});

  final IndiaSignal signal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final directionColor =
        signal.isLong ? LuminColors.success : LuminColors.loss;
    final directionFaint =
        signal.isLong ? LuminColors.successFaint : LuminColors.lossFaint;
    final resultLabel = signalResultLabel(signal);

    return Card(
      color: LuminColors.bgCard,
      margin: const EdgeInsets.symmetric(
        horizontal: LuminSpacing.lg,
        vertical: LuminSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuminRadii.md),
        side: const BorderSide(color: LuminColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuminRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(LuminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Chip(
                    label: signal.direction,
                    color: directionColor,
                    background: directionFaint,
                  ),
                  const SizedBox(width: LuminSpacing.sm),
                  Text(
                    signal.base,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (signal.isResolved) ...[
                    _Chip(
                      label: signal.statusLabel,
                      color: statusColor(signal.status),
                      background: statusColor(signal.status).withAlpha(30),
                    ),
                    const SizedBox(width: LuminSpacing.sm),
                  ],
                  _Chip(
                    label: signal.tier,
                    color: tierColor(signal.tier),
                    background: tierColorFaint(signal.tier),
                  ),
                ],
              ),
              const SizedBox(height: LuminSpacing.lg),
              Row(
                children: [
                  _PriceColumn(label: 'ENTRY', value: formatPrice(signal.entry)),
                  _PriceColumn(
                    label: 'SL',
                    value: formatPrice(signal.sl),
                    color: LuminColors.loss,
                  ),
                  _PriceColumn(
                    label: 'TP1',
                    value: formatPrice(signal.tp1),
                    color: LuminColors.success,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (resultLabel != null)
                          Text(
                            resultLabel,
                            style: TextStyle(
                              color: signal.isResolved
                                  ? statusColor(signal.status)
                                  : ((signal.livePct ?? 0) >= 0
                                      ? LuminColors.success
                                      : LuminColors.loss),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          formatIstTime(signal.createdAt),
                          style: const TextStyle(
                            color: LuminColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuminSpacing.md,
        vertical: LuminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(LuminRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: LuminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LuminColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? LuminColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
