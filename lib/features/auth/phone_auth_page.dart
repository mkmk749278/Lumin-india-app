/// Phone number input screen — first step of Firebase Phone Auth.
///
/// Indian mobile numbers only (+91). No email, no social login (CLAUDE.md).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/tokens.dart';
import 'otp_verify_page.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullNumber => '+91${_phoneController.text.trim()}';

  bool get _isValid {
    final digits = _phoneController.text.trim();
    return digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
  }

  Future<void> _sendOtp() async {
    if (!_isValid) {
      setState(() => _error = 'Enter a valid 10-digit Indian mobile number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _fullNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = e.message ?? 'Verification failed. Try again.';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OtpVerifyPage(
              verificationId: verificationId,
              phoneNumber: _fullNumber,
              resendToken: resendToken,
            ),
          ),
        );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LuminSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Text(
                'Lumin India',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: LuminColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: LuminSpacing.sm),
              const Text(
                'NSE F&O intraday signals',
                style: TextStyle(
                  color: LuminColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Login with your mobile number',
                style: TextStyle(
                  color: LuminColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: LuminSpacing.xl),
              Row(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuminSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: LuminColors.bgCard,
                      borderRadius: BorderRadius.circular(LuminRadii.md),
                      border: Border.all(color: LuminColors.cardBorder),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '+91',
                      style: TextStyle(
                        color: LuminColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: LuminSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(
                        color: LuminColors.textPrimary,
                        fontSize: 16,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Mobile number',
                        hintStyle: const TextStyle(
                          color: LuminColors.textMuted,
                        ),
                        filled: true,
                        fillColor: LuminColors.bgCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LuminRadii.md),
                          borderSide: const BorderSide(
                            color: LuminColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LuminRadii.md),
                          borderSide: const BorderSide(
                            color: LuminColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LuminRadii.md),
                          borderSide: const BorderSide(
                            color: LuminColors.accent,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _sendOtp(),
                    ),
                  ),
                ],
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
                  onPressed: _loading ? null : _sendOtp,
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
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
