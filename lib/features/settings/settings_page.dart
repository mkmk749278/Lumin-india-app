/// Settings tab — auto-trade entry (Phase 2 gated), engine status, version.
///
/// Profile / logout join with Firebase auth; Subscription joins with
/// Razorpay. Per the operating brief the Auto-Trade screen must exist
/// from day one, visibly gated — never hidden.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/tokens.dart';
import '../auth/auth_providers.dart';
import '../signals/signals_providers.dart';
import 'auto_trade_page.dart';

const String kAppVersion = '0.1.0';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _uptime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulse = ref.watch(pulseProvider);

    final engineStatus = pulse.when(
      data: (p) =>
          '${p.sessionState} · up ${_uptime(p.uptimeSeconds)}',
      loading: () => 'Connecting…',
      error: (_, __) => 'Unreachable',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(
              Icons.auto_mode,
              color: LuminColors.textSecondary,
            ),
            title: const Text('Auto-Trade'),
            subtitle: const Text(
              'Coming soon',
              style: TextStyle(color: LuminColors.textMuted),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: LuminColors.textMuted,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AutoTradePage(),
              ),
            ),
          ),
          const Divider(color: LuminColors.bgElevated, height: 1),
          ListTile(
            leading: const Icon(
              Icons.dns_outlined,
              color: LuminColors.textSecondary,
            ),
            title: const Text('Signal engine'),
            subtitle: Text(
              engineStatus,
              style: const TextStyle(color: LuminColors.textMuted),
            ),
          ),
          const Divider(color: LuminColors.bgElevated, height: 1),
          ListTile(
            leading: const Icon(
              Icons.person_outline,
              color: LuminColors.textSecondary,
            ),
            title: const Text('Account'),
            subtitle: Text(
              ref.watch(currentPhoneProvider),
              style: const TextStyle(color: LuminColors.textMuted),
            ),
          ),
          const Divider(color: LuminColors.bgElevated, height: 1),
          const ListTile(
            leading: Icon(
              Icons.info_outline,
              color: LuminColors.textSecondary,
            ),
            title: Text('Version'),
            subtitle: Text(
              kAppVersion,
              style: TextStyle(color: LuminColors.textMuted),
            ),
          ),
          const Divider(color: LuminColors.bgElevated, height: 1),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: LuminColors.loss,
            ),
            title: const Text(
              'Sign out',
              style: TextStyle(color: LuminColors.loss),
            ),
            onTap: () => ref.read(signOutProvider)(),
          ),
        ],
      ),
    );
  }
}
