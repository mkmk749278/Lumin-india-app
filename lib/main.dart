import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/india_api_client.dart';
import 'app/nav_shell.dart';
import 'features/auth/phone_auth_page.dart';
import 'services/fcm_service.dart';
import 'shared/tokens.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
      home: const _AuthGate(),
    );
  }
}

/// Routes to [NavShell] when signed in, [PhoneAuthPage] when not.
///
/// FCM init is deferred until the user is authenticated so the device
/// token is registered with the user's Firebase UID.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _fcmInitialized = false;

  Future<void> _initFcm() async {
    if (_fcmInitialized) return;
    _fcmInitialized = true;
    final user = FirebaseAuth.instance.currentUser;
    final api = IndiaApiClient();
    final fcm = FcmService(api, uid: user?.uid ?? '');
    await fcm.init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: LuminColors.bgDeep,
            body: Center(
              child: CircularProgressIndicator(color: LuminColors.accent),
            ),
          );
        }

        if (snapshot.hasData) {
          _initFcm();
          return const NavShell();
        }

        return const PhoneAuthPage();
      },
    );
  }
}
