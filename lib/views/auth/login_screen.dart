// lib/views/auth/login_screen.dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/language_provider.dart';
import '../../utils/bl_colors.dart';
import 'phone_login_screen.dart';
import 'package:buslink/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Added
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Added
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false; // Added

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty || !email.contains('@')) {
      messenger.showSnackBar(const SnackBar(
          content:
              Text('Type your email above first, then tap Forgot Password.')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(SnackBar(
          content: Text('We sent a link to $email to choose a new password.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'We could not send the email. Check the address and try again.')));
    }
  }

  void _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.loginErrorEmpty)),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      dynamic cred;
      if (_isLogin) {
        cred = await authService.signInWithEmail(context, email, password);
      } else {
        cred = await authService.signUpWithEmail(
            context,
            email,
            password,
            null, // Phone number removed
            _nameController.text.trim() // Added displayName
            );
      }

      if (cred != null && cred.user != null && mounted) {
        setState(() => _isLoading = false);
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
        return;
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _googleSignIn() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final cred = await authService.signInWithGoogle(context);

    if (mounted) {
      setState(() => _isLoading = false);
      if (cred != null && cred.user != null) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      }
    }
  }

  static const _photo = 'assets/images/home/ella_train.jpg';

  Widget _languagePills() {
    final lp = Provider.of<LanguageProvider>(context);
    final cur = lp.currentLocale.languageCode;
    Widget pill(String code, String label) {
      final on = cur == code;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          child: InkWell(
            onTap: () => lp.changeLanguage(code),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? BL.crimson : BL.surface,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: on ? BL.crimson : BL.border, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (on)
                    const Icon(Icons.check, size: 18, color: Colors.white),
                  if (on) const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: on ? Colors.white : BL.ink)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      pill('en', 'English'),
      const SizedBox(width: 8),
      pill('si', 'සිංහල'),
      const SizedBox(width: 8),
      pill('ta', 'தமிழ்'),
    ]);
  }

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool password = false,
    bool visible = false,
    VoidCallback? onToggle,
    TextInputType? type,
    String? helper,
    double height = 52,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: type,
          obscureText: password && !visible,
          style: const TextStyle(fontSize: 17),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle: TextStyle(fontSize: 14, color: BL.muted),
            errorStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            hintStyle: TextStyle(fontSize: 17, color: BL.muted),
            prefixIcon: Icon(icon, color: BL.muted),
            suffixIcon: password
                ? IconButton(
                    tooltip: visible ? 'Hide password' : 'Show password',
                    icon: Icon(visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: onToggle,
                  )
                : null,
            filled: true,
            fillColor: BL.fill,
            contentPadding: EdgeInsets.symmetric(vertical: (height - 24) / 2),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: BL.hairline, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: BL.hairline, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BL.crimson, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _form(bool desktop) {
    final l10n = AppLocalizations.of(context)!;
    final gap = SizedBox(height: desktop ? 14 : 12);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _languagePills(),
          gap,
          if (!_isLogin) ...[
            _field(
              label: l10n.fullName,
              hint: l10n.enterFullName,
              icon: Icons.person_outline,
              controller: _nameController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.nameRequired;
                if (v.trim().length < 3) return l10n.nameTooShort;
                if (!RegExp(r"^[\p{L} .'-]+$", unicode: true)
                    .hasMatch(v.trim())) {
                  return l10n.nameInvalid;
                }
                return null;
              },
            ),
            gap,
          ],
          _field(
            label: l10n.email,
            hint: l10n.enterEmail,
            icon: Icons.mail_outline,
            controller: _emailController,
            type: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.emailRequired;
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return l10n.emailInvalid;
              }
              return null;
            },
          ),
          gap,
          _field(
            label: l10n.password,
            hint: l10n.enterPassword,
            icon: Icons.lock_outline,
            controller: _passwordController,
            password: true,
            visible: _isPasswordVisible,
            onToggle: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            helper: _isLogin ? null : 'At least 6 characters',
            validator: (v) =>
                v == null || v.length < 6 ? l10n.passwordLengthError : null,
          ),
          if (!_isLogin) ...[
            gap,
            _field(
              label: l10n.confirmPassword,
              hint: l10n.reenterPassword,
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
              password: true,
              visible: _isConfirmPasswordVisible,
              onToggle: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.confirmPasswordRequired;
                if (v != _passwordController.text) {
                  return l10n.passwordsDoNotMatch;
                }
                return null;
              },
            ),
          ],
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                style: TextButton.styleFrom(
                    foregroundColor: BL.link,
                    minimumSize: const Size(0, 44),
                    textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                child: Text(l10n.forgotPassword),
              ),
            )
          else
            const SizedBox(height: 6),
          SizedBox(
            height: desktop ? 58 : 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _submitAuthForm,
              style: FilledButton.styleFrom(
                backgroundColor: BL.crimson,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 19,
                    fontWeight: FontWeight.w800),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(_isLogin ? l10n.login : l10n.signup),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Divider(color: BL.hairline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l10n.orDivider,
                  style: TextStyle(fontSize: 15, color: BL.muted)),
            ),
            Expanded(child: Divider(color: BL.hairline)),
          ]),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isLoading ? null : _googleSignIn,
            style: _outline,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/google_g.png',
                    width: 22, height: 22),
                const SizedBox(width: 10),
                Text(l10n.continueWithGoogle),
              ],
            ),
          ),
          if (_isLogin) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PhoneLoginScreen())),
              icon: const Icon(Icons.phone_iphone),
              label: const Text('Log in with phone number'),
              style: _outline,
            ),
          ],
        ],
      ),
    );
  }

  ButtonStyle get _outline => OutlinedButton.styleFrom(
        minimumSize: const Size(0, 54),
        foregroundColor: BL.ink,
        side: BorderSide(color: BL.border, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
            fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w700),
      );

  Widget _switchMode() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(_isLogin ? l10n.noAccount : l10n.alreadyHaveAccount,
              style: TextStyle(fontSize: 16, color: BL.muted)),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            style: TextButton.styleFrom(
                foregroundColor: BL.link,
                minimumSize: const Size(0, 48),
                textStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            child: Text(_isLogin ? l10n.signup : l10n.login),
          ),
        ],
      ),
    );
  }

  void _debugLogin(String email, String pass) {
    _emailController.text = email;
    _passwordController.text = pass;
    _submitAuthForm();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: BL.surface,
      body: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth > 900) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('BusLink',
                                style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: BL.link)),
                            const SizedBox(height: 18),
                            Text(l10n.welcome,
                                style: const TextStyle(
                                    fontSize: 38, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                                _isLogin
                                    ? l10n.loginSubtitle
                                    : l10n.signupSubtitle,
                                style:
                                    TextStyle(fontSize: 18, color: BL.muted)),
                            const SizedBox(height: 18),
                            _form(true),
                            const SizedBox(height: 8),
                            _switchMode(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Semantics(
                        image: true,
                        label:
                            'A blue train crossing the Nine Arches Bridge near Ella',
                        child: Image.asset(_photo,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, 0.2)),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x8C3C0304), Color(0xEB660708)],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 56,
                        right: 56,
                        bottom: 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Travel with\nComfort & Style',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 52,
                                    height: 1.08,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 16),
                            Text(
                                'Join thousands of satisfied travelers who trust BusLink for their daily commutes.',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: HiddenDebugButton(onDebugLogin: _debugLogin)),
                    ],
                  ),
                ),
              ],
            );
          }
          final top = MediaQuery.paddingOf(context).top;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Positioned.fill(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Semantics(
                              image: true,
                              label:
                                  'A blue train crossing the Nine Arches Bridge near Ella',
                              child: Image.asset(_photo,
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0, 0.2)),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x803C0304),
                                    Color(0xE6660708)
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, top + 20, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BusLink',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            Text(l10n.welcome,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800)),
                            Text(
                                _isLogin
                                    ? l10n.loginSubtitle
                                    : l10n.signupSubtitle,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 17)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24,
                        MediaQuery.viewInsetsOf(context).bottom + 8),
                    child: _form(false),
                  ),
                  _switchMode(),
                  HiddenDebugButton(onDebugLogin: _debugLogin),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class HiddenDebugButton extends StatelessWidget {
  final Function(String, String) onDebugLogin;
  const HiddenDebugButton({super.key, required this.onDebugLogin});

  @override
  Widget build(BuildContext context) {
    // Debug-only shortcut. In a release build (the public demo) this widget
    // must not exist: it would auto-sign-in as admin with a known password.
    if (!kDebugMode) return const SizedBox.shrink();
    return Opacity(
      opacity: 0.02, // Hidden
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.settings, size: 40, color: Colors.white),
        tooltip: 'Debug Access',
        onSelected: (value) {
          String email = "";
          String pass = "123456";
          if (value == 'admin') {
            email = "admin@buslink.com";
          } else if (value == 'conductor') {
            email = "conductor@buslink.com";
          } else if (value == 'user') {
            email = "test@test.com";
          }
          onDebugLogin(email, pass);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'admin',
            child: Text('Admin Access'),
          ),
          const PopupMenuItem<String>(
            value: 'conductor',
            child: Text('Conductor Access'),
          ),
          const PopupMenuItem<String>(
            value: 'user',
            child: Text('User Access'),
          ),
        ],
      ),
    );
  }
}
