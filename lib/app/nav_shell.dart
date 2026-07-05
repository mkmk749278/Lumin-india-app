/// Bottom-tab navigation shell — Signals / Session / Settings.
///
/// IndexedStack keeps each tab's state alive (the feed's refresh timer
/// keeps polling while the user reads the session tab).
///
/// Handles FCM deep-link navigation: a notification tap sets
/// [pendingSignalIdProvider] which triggers a fetch + push to SignalDetailPage.
/// Foreground FCM messages are shown as a SnackBar with a "View" action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/session/session_page.dart';
import '../features/settings/settings_page.dart';
import '../features/signals/models.dart';
import '../features/signals/signal_detail_page.dart';
import '../features/signals/signals_page.dart';
import '../features/signals/signals_providers.dart';
import '../shared/tokens.dart';

class NavShell extends ConsumerStatefulWidget {
  const NavShell({super.key});

  @override
  ConsumerState<NavShell> createState() => _NavShellState();
}

class _NavShellState extends ConsumerState<NavShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Wire FCM listeners after the first frame so the navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenFcm());
  }

  void _listenFcm() {
    // Background / terminated notification tap → navigate to signal detail.
    ref.listenManual(pendingSignalIdProvider, (_, signalId) {
      if (signalId != null && mounted) {
        _openSignalById(signalId);
        ref.read(pendingSignalIdProvider.notifier).state = null;
      }
    });

    // Foreground message → in-app SnackBar banner with "View" action.
    ref.listenManual(fcmForegroundProvider, (_, notif) {
      if (notif != null && mounted) {
        _showForegroundBanner(notif);
        ref.read(fcmForegroundProvider.notifier).state = null;
      }
    });
  }

  Future<void> _openSignalById(String signalId) async {
    try {
      final signal = await ref.read(apiClientProvider).signalById(signalId);
      if (mounted) {
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => SignalDetailPage(signal: signal),
        ));
      }
    } catch (_) {
      // Fetch failed — switch to signals tab so the user sees the feed.
      if (mounted) setState(() => _index = 0);
    }
  }

  void _showForegroundBanner(FcmForegroundNotif notif) {
    final color = notif.tier == 'A+'
        ? LuminColors.success
        : notif.tier == 'A'
            ? LuminColors.accent
            : LuminColors.warn;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${notif.symbol} ${notif.direction} — ${notif.tier} confidence',
          style: const TextStyle(color: LuminColors.textPrimary),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: color,
          onPressed: () => _openSignalById(notif.signalId),
        ),
        duration: const Duration(seconds: 8),
        backgroundColor: LuminColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuminRadii.md),
          side: BorderSide(color: color.withAlpha(80)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          SignalsPage(),
          SessionPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: LuminColors.bgCard,
        indicatorColor: LuminColors.cardBorder,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt, color: LuminColors.accent),
            label: 'Signals',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats, color: LuminColors.accent),
            label: 'Session',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: LuminColors.accent),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
