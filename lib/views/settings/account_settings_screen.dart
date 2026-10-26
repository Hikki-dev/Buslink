import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isLoading = false;
  bool _isGoogleLinked = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check Auth Providers
    _isGoogleLinked =
        user.providerData.any((info) => info.providerId == 'google.com');

    // Load Firestore Data
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text =
          data['displayName'] ?? data['name'] ?? user.displayName ?? "";
      _phoneController.text =
          data['phoneNumber'] ?? data['phone'] ?? user.phoneNumber ?? "";
    } else {
      _nameController.text = user.displayName ?? "";
      _phoneController.text = user.phoneNumber ?? "";
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'displayName': newName, 'phoneNumber': newPhone});

      // Update Auth Profile (Display Name)
      await user.updateDisplayName(newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating profile: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _linkGoogle() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.linkWithGoogle(context);

    if (result != null) {
      if (mounted) {
        setState(() => _isGoogleLinked = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Google Account Linked Successfully!")));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String? helper) => InputDecoration(
          helperText: helper,
          helperStyle: TextStyle(fontSize: 14, color: BL.muted),
          errorStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          filled: true,
          fillColor: BL.fill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BL.hairline, width: 1.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BL.hairline, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BL.crimson, width: 2)),
        );
    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 14),
          child: Text(t,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      backgroundColor: BL.surface,
      body: Column(
        children: [
          const BlHeader(title: 'Account Settings'),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Personal Information',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        label('Display Name'),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 17),
                          decoration: deco(null),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please enter your name'
                              : null,
                        ),
                        label('Phone Number'),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 17),
                          decoration: deco('Format: +94 7X XXX XXXX'),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            final ok = RegExp(r'^(?:\+94|0)7\d{8}$')
                                .hasMatch(v.replaceAll(' ', ''));
                            return ok
                                ? null
                                : 'Invalid Phone Number. Use 07X XXX XXXX';
                          },
                        ),
                        const SizedBox(height: 20),
                        BlPrimaryButton(
                          label: _isLoading ? 'Saving...' : 'Save Changes',
                          color: BL.crimson,
                          onTap: _isLoading ? null : _saveProfile,
                        ),
                        Divider(height: 44, color: BL.hairline),
                        const Text('Linked Accounts',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: BL.hairline),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Image.asset('assets/images/google_g.png',
                                  width: 32, height: 32),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Google',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700)),
                                    Row(
                                      children: [
                                        if (_isGoogleLinked)
                                          Icon(Icons.check,
                                              size: 16, color: BL.success),
                                        if (_isGoogleLinked)
                                          const SizedBox(width: 4),
                                        Text(
                                            _isGoogleLinked
                                                ? 'Connected'
                                                : 'Not connected',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _isGoogleLinked
                                                    ? BL.successInk
                                                    : BL.muted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isGoogleLinked)
                                OutlinedButton(
                                  onPressed: _isLoading ? null : _linkGoogle,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    foregroundColor: BL.link,
                                    side: const BorderSide(
                                        color: BL.crimson, width: 2),
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  child: const Text('Link'),
                                ),
                            ],
                          ),
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
