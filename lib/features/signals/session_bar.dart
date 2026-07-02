/// Session status bar — always visible on Home (CLAUDE.md UI rules).
library;

import 'package:flutter/material.dart';

import '../../shared/tokens.dart';
import 'models.dart';

class SessionBar extends StatelessWidget {
  const SessionBar({super.key, this.pulse, this.error = false});

  final EnginePulse? pulse;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color dotColor;

    if (error) {
      label = 'Engine unreachable';
      dotColor = LuminColors.loss;
    } else if (pulse == null) {
      label = 'Connecting…';
      dotColor = LuminColors.textMuted;
    } else if (pulse!.isOpen) {
      label = 'Market Open · 09:15–15:30 IST';
      dotColor = LuminColors.success;
    } else if (pulse!.sessionState == 'PRE_OPEN') {
      label = 'Pre-open · opens 09:15 IST';
      dotColor = LuminColors.warn;
    } else {
      label = 'Market Closed';
      dotColor = LuminColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuminSpacing.lg,
        vertical: LuminSpacing.md,
      ),
      color: LuminColors.bgElevated,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: LuminSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: LuminColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (pulse != null)
            Text(
              '${pulse!.signalsToday} signals today',
              style: const TextStyle(
                color: LuminColors.textMuted,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}
