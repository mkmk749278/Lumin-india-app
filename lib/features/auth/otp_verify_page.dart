/// OTP verification screen — second step of Firebase Phone Auth.
///
/// 6-digit code entry with 60-second resend timer (CLAUDE.md).
/// Auto-verifies if SMS auto-detection works on the device.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/tokens.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _resendCountdown = 60;
  Timer? _timer;
  late String _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.code == 'invalid-verification-code'
            ? 'Incorrect code. Check and try again.'
            : (e.message ?? 'Verification failed.');
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = e.message ?? 'Resend failed.';
        });
      },
      codeSent: (String newId, int? token) {
        if (!mounted) return;
        setState(() {
          _verificationId = newId;
          _resendToken = token;
          _loading = false;
        });
        _startCountdown();
      },
      codeAutoRetrievalTimeout: (_) {
        if (!mounted) return;
        setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminColors.bgDeep,
      appBar: AppBar(
        backgroundColor: LuminColors.bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: LuminColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuminSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: LuminSpacing.xl),
              const Text(
                'Enter verification code',
                style: TextStyle(
                  color: LuminColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: LuminSpacing.sm),
              Text(
                'Sent to ${widget.phoneNumber}',
                style: const TextStyle(
                  color: LuminColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: LuminSpacing.xxl),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LuminColors.textPrimary,
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w600,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: LuminColors.textMuted.withAlpha(100),
                    fontSize: 28,
                    letterSpacing: 12,
                  ),
                  filled: true,
                  fillColor: LuminColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LuminRadii.md),
                    borderSide: const BorderSide(color: LuminColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LuminRadii.md),
                    borderSide: const BorderSide(color: LuminColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LuminRadii.md),
                    borderSide: const BorderSide(color: LuminColors.accent),
                  ),
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),
              if (_error != null) ...[
                const SizedBox(height: LuminSpacing.sm),
                Text(
                  _error!,
                  style: const TextStyle(color: LuminColors.loss, fontSize: 13),
                ),
              ],
              const SizedBox(height: LuminSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: FilledButton.styleFrom(
                    backgroundColor: LuminColors.accent,
                    foregroundColor: LuminColors.bgDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LuminRadii.md),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LuminColors.bgDeep,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: LuminSpacing.lg),
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Resend in ${_resendCountdown}s',
                        style: const TextStyle(
                          color: LuminColors.textMuted,
                          fontSize: 14,
                        ),
                      )
                    : TextButton(
                        onPressed: _loading ? null : _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: LuminColors.accent,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
