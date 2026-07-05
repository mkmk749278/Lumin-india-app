import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/india_api_client.dart';
import 'app/nav_shell.dart';
import 'services/fcm_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final api = IndiaApiClient();
  final fcm = FcmService(api);
  await fcm.init();

  runApp(ProviderScope(child: LuminIndiaApp(fcmService: fcm)));
}

class LuminIndiaApp extends StatelessWidget {
  const LuminIndiaApp({super.key, required this.fcmService});

  final FcmService fcmService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumin India',
      debugShowCheckedModeBanner: false,
      theme: buildLuminIndiaTheme(),
      home: const NavShell(),
    );
  }
}
