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
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        formatIstTime(signal.createdAt),
                        style: const TextStyle(
                          color: LuminColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
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
