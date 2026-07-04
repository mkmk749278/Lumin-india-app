/// Home — live signal feed with session status bar.
///
/// FCM is the doorbell, this API poll is the source of truth. Auto-refreshes
/// every 30s while visible (matches the engine's scan interval) + pull to
/// refresh. Signals are never cached beyond the current session.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/india_api_client.dart' show IndiaApiClient;
import '../../config.dart';
import '../../shared/tokens.dart';
import 'session_bar.dart';
import 'signal_card.dart';
import 'signal_detail_page.dart';
import 'signals_providers.dart';

class SignalsPage extends ConsumerStatefulWidget {
  const SignalsPage({super.key});

  @override
  ConsumerState<SignalsPage> createState() => _SignalsPageState();
}

class _SignalsPageState extends ConsumerState<SignalsPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(AppConfig.feedRefreshInterval, (_) {
      ref.invalidate(signalsProvider);
      ref.invalidate(pulseProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(signalsProvider);
    ref.invalidate(pulseProvider);
    await ref.read(signalsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final pulse = ref.watch(pulseProvider);
    final signals = ref.watch(signalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LUMIN INDIA')),
      body: Column(
        children: [
          SessionBar(
            pulse: pulse.valueOrNull,
            error: pulse.hasError,
            authError: IndiaApiClient.isAuthError(pulse.error),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: LuminColors.accent,
              backgroundColor: LuminColors.bgCard,
              child: signals.when(
                data: (list) => list.isEmpty
                    ? const _EmptyFeed()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            vertical: LuminSpacing.sm),
                        itemCount: list.length,
                        itemBuilder: (context, i) => SignalCard(
                          signal: list[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SignalDetailPage(signal: list[i]),
                            ),
                          ),
                        ),
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: LuminColors.accent),
                ),
                error: (e, _) => _ErrorFeed(
                  onRetry: _refresh,
                  authError: IndiaApiClient.isAuthError(e),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.radar, size: 48, color: LuminColors.textMuted),
        SizedBox(height: LuminSpacing.lg),
        Center(
          child: Text(
            'No signals yet',
            style: TextStyle(color: LuminColors.textSecondary, fontSize: 16),
          ),
        ),
        SizedBox(height: LuminSpacing.sm),
        Center(
          child: Text(
            'The scanner emits only A+ and B setups.\nQuiet feed = no edge worth taking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: LuminColors.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ErrorFeed extends StatelessWidget {
  const _ErrorFeed({required this.onRetry, this.authError = false});

  final Future<void> Function() onRetry;
  final bool authError;

  @override
  Widget build(BuildContext context) {
    final title = authError
        ? 'Access denied by the engine'
        : 'Could not reach the signal engine';
    final hint = authError
        ? 'This APK was built without a valid API token.\n'
            'Add the INDIA_API_TOKEN repo secret, run the\n'
            '"Build testing APK" workflow again, and reinstall.'
        : null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          authError ? Icons.key_off : Icons.cloud_off,
          size: 48,
          color: LuminColors.textMuted,
        ),
        const SizedBox(height: LuminSpacing.lg),
        Center(
          child: Text(
            title,
            style: const TextStyle(
                color: LuminColors.textSecondary, fontSize: 16),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: LuminSpacing.sm),
          Center(
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: LuminColors.textMuted, fontSize: 13, height: 1.5),
            ),
          ),
        ],
        const SizedBox(height: LuminSpacing.lg),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
