/// Auth-state providers — testable wrappers around FirebaseAuth.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentPhoneProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
});

final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () => FirebaseAuth.instance.signOut();
});
