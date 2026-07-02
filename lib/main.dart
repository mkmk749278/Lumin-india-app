import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/signals/signals_page.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: LuminIndiaApp()));
}

class LuminIndiaApp extends StatelessWidget {
  const LuminIndiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumin India',
      debugShowCheckedModeBanner: false,
      theme: buildLuminIndiaTheme(),
      home: const SignalsPage(),
    );
  }
}
