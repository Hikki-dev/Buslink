import 'package:flutter/material.dart';
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen(
      {super.key, required this.verificationId, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer == 0) {
        timer.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  @override
  void dispose() {
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _fullCode => _codeControllers.map((c) => c.text).join();

  void _verifyCode() async {
    final code = _fullCode;
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the full 6-digit code")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithPhoneCredential(context, credential);

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = "Verification failed";
        if (e.code == 'invalid-verification-code') {
          message = "Invalid code. Please check and try again.";
        } else if (e.code == 'session-expired') {
          message = "Code expired. Please resend.";
        }
        setState(() => _error = message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const BlHeader(title: 'Verify Phone'),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Verification Code',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text.rich(TextSpan(
                        style: const TextStyle(
                            fontSize: 18, height: 1.4, color: BL.muted),
                        children: [
                          const TextSpan(text: 'Type the 6 digits we sent to '),
                          TextSpan(
                              text: widget.phoneNumber,
                              style: const TextStyle(
                                  color: BL.ink, fontWeight: FontWeight.w700)),
                        ],
                      )),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          return SizedBox(
                            width: 48,
                            height: 60,
                            child: TextField(
                              controller: _codeControllers[i],
                              focusNode: _focusNodes[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w800),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFF5F3F4),
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: BL.border, width: 1.5)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: BL.border, width: 1.5)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: BL.crimson, width: 2.5)),
                              ),
                              onChanged: (v) {
                                setState(() => _error = null);
                                if (v.isNotEmpty && i < 5) {
                                  _focusNodes[i + 1].requestFocus();
                                }
                                if (v.isEmpty && i > 0) {
                                  _focusNodes[i - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFBE0DC),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFF7F1D14)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7F1D14))),
                            ),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 22),
                      BlPrimaryButton(
                        label: _isLoading ? 'Checking...' : 'Verify',
                        color: BL.crimson,
                        onTap: _isLoading ? null : _verifyCode,
                      ),
                      const SizedBox(height: 14),
                      const Text('Did not get it?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: BL.muted)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _resendTimer == 0
                              ? () => Navigator.pop(context)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BL.crimson,
                            side: BorderSide(
                                color:
                                    _resendTimer == 0 ? BL.crimson : BL.border,
                                width: 2),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          child: Text(_resendTimer > 0
                              ? 'Resend code in ${_resendTimer}s'
                              : 'Resend Code'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                          'Code expired? Tap Resend Code to get a new one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: BL.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
