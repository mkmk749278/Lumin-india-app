/// Bottom-tab navigation shell — Signals / Session / Settings.
///
/// IndexedStack keeps each tab's state alive (the feed's refresh timer
/// keeps polling while the user reads the session tab). Auth, Profile,
/// and Subscription tabs join once Firebase / Razorpay exist.
library;

import 'package:flutter/material.dart';

import '../features/session/session_page.dart';
import '../features/settings/settings_page.dart';
import '../features/signals/signals_page.dart';
import '../shared/tokens.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _index = 0;

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
