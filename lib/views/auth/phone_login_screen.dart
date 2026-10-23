import 'package:flutter/material.dart';
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';
import 'otp_verification_screen.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String phoneNumber = _phoneController.text.trim();
    // Simple validation/formatting check
    // Remove all spaces and dashes
    phoneNumber = phoneNumber.replaceAll(RegExp(r'\s+|-'), '');

    // SRI LANKA NUMBER FORMATTING
    // Case 1: 0771234567 -> +94771234567
    if (RegExp(r'^07[0-9]{8}$').hasMatch(phoneNumber)) {
      phoneNumber = '+94${phoneNumber.substring(1)}';
    }
    // Case 2: 771234567 -> +94771234567
    else if (RegExp(r'^7[0-9]{8}$').hasMatch(phoneNumber)) {
      phoneNumber = '+94$phoneNumber';
    }
    // Case 3: Already has +94, ensure it's valid
    else if (phoneNumber.startsWith('+94')) {
      // Keep as is
    }
    // Fallback? If it doesn't match these, let it pass to Firebase which handles validation,
    // OR we can show a specific error if we want to enforce SL numbers.
    // For now, allow fallback for reliability.

    final authService = Provider.of<AuthService>(context, listen: false);

    await authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-resolution (Android only usually)
        setState(() => _isLoading = false);
        await authService.signInWithPhoneCredential(context, credential);
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification Failed: ${e.message}")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Timeout handling if needed
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const BlHeader(title: 'Phone Login'),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                                color: Color(0xFFFDEEEE),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.phone_iphone,
                                size: 36, color: BL.crimson),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Enter your phone number',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text(
                            'We will send you a 6-digit verification code.',
                            style: TextStyle(
                                fontSize: 18, height: 1.4, color: BL.muted)),
                        const SizedBox(height: 22),
                        const Text('Phone Number',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style:
                              const TextStyle(fontSize: 19, letterSpacing: 0.8),
                          decoration: InputDecoration(
                            hintText: '+94 77 123 4567',
                            errorStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                            filled: true,
                            fillColor: const Color(0xFFF5F3F4),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 18),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: BL.hairline, width: 1.5)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: BL.hairline, width: 1.5)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: BL.crimson, width: 2.5)),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Please enter your phone number'
                              : null,
                        ),
                        const SizedBox(height: 22),
                        BlPrimaryButton(
                          label: _isLoading ? 'Sending...' : 'Send Code',
                          color: BL.crimson,
                          onTap: _isLoading ? null : _sendCode,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.maybePop(context),
                          style: TextButton.styleFrom(
                              foregroundColor: BL.crimson,
                              minimumSize: const Size(0, 52),
                              textStyle: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                          child: const Text('Use email instead'),
                        ),
                      ],
                    ),
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
