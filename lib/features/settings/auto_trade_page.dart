/// Auto-Trade settings — Phase 2 gated.
///
/// Operating-brief rule: this screen exists from day one but shows a
/// clear "Coming Soon — pending regulatory clearance" gate until the
/// engine reports AUTO_EXECUTION_ENABLED=true. It is never hidden and
/// never shows controls before that flag flips (hard limit).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/tokens.dart';
import '../signals/signals_providers.dart';

class AutoTradePage extends ConsumerWidget {
  const AutoTradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulse = ref.watch(pulseProvider);
    final engineEnabled = pulse.valueOrNull?.autoExecution ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('AUTO-TRADE')),
      body: Padding(
        padding: const EdgeInsets.all(LuminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: LuminSpacing.xxl),
            const Icon(
              Icons.lock_clock,
              size: 56,
              color: LuminColors.accentMuted,
            ),
            const SizedBox(height: LuminSpacing.xl),
            Text(
              engineEnabled
                  ? 'Enabled at the engine'
                  : 'Coming Soon',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LuminColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: LuminSpacing.lg),
            Text(
              engineEnabled
                  ? 'Auto-trade execution is active on the platform. '
                      'Per-user controls arrive in an app update.'
                  : 'Automatic trade execution is pending regulatory '
                      'clearance — SEBI Research Analyst registration and '
                      'NSE algo empanelment. Until then, every signal is '
                      'delivered for you to act on manually with your own '
                      'broker.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LuminColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
