// lib/views/auth/login_screen.dart
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  int _currentBgIndex = 0;
  Timer? _bgTimer;
  final List<String> _bgImages = [
    "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80",
    "https://images.unsplash.com/photo-1557223562-6c77ef16210f?auto=format&fit=crop&q=80",
    "https://images.unsplash.com/photo-1561361513-2d000a50f0dc?auto=format&fit=crop&q=80",
    "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?auto=format&fit=crop&q=80",
  ];

  @override
  void initState() {
    super.initState();
    _currentBgIndex = Random().nextInt(_bgImages.length);
    _startBgTimer();
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startBgTimer() {
    _bgTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  void _submitAuthForm() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Email and Password cannot be empty.")),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      dynamic cred;
      if (_isLogin) {
        cred = await authService.signInWithEmail(context, email, password);
      } else {
        cred = await authService.signUpWithEmail(context, email, password);
      }

      if (cred != null && cred.user != null && mounted) {
        setState(() => _isLoading = false);
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
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
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  void _appleSignIn() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final cred = await authService.signInWithApple(context);

    if (mounted) {
      setState(() => _isLoading = false);
      if (cred != null && cred.user != null) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Stack(
                      children: [
                        Center(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 450),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40.0, vertical: 60),
                                child: _buildAnimatedForm(context),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          right: 40,
                          child: Material(
                            color: Colors.transparent,
                            elevation: 8,
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ThemeSwitcher(),
                                const SizedBox(width: 12),
                                _LanguageSwitcher(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child:
                      _IllustrationPanel(bgImage: _bgImages[_currentBgIndex]),
                ),
              ],
            );
          } else {
            // Mobile Layout
            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(seconds: 2),
                    child: Image.network(
                      _bgImages[_currentBgIndex],
                      key: ValueKey(_bgImages[_currentBgIndex]),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: const Color(0xFF0A0B10));
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.red.shade900.withOpacity(0.8),
                          Colors.red.shade800.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeaderLogo(context),
                            const SizedBox(height: 32),
                            _buildAnimatedForm(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Theme & Language Switchers - LAST = ON TOP
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ThemeSwitcher(),
                        const SizedBox(width: 12),
                        _LanguageSwitcher(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderLogo(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.directions_bus_filled_rounded,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'BusLink',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    ]);
  }

  Widget _buildAnimatedForm(BuildContext context) {
    final theme = Theme.of(context);
    final lp = Provider.of<LanguageProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lp.translate('welcome'),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lp.translate(_isLogin ? 'login_subtitle' : 'signup_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  onPressed: _googleSignIn,
                  iconUrl:
                      'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                  label: lp.translate('google_login'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialButton(
                  onPressed: _appleSignIn,
                  icon: Icons.apple,
                  label: lp.translate('apple_login'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFF1E1E22))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(lp.translate('or_separator'),
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
              const Expanded(child: Divider(color: Color(0xFF1E1E22))),
            ],
          ),
          const SizedBox(height: 32),
          _buildPremiumTextField(
            controller: _emailController,
            label: lp.translate('email'),
            hint: lp.translate('email_hint'),
            icon: Icons.email_outlined,
            theme: theme,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 24),
          _buildPremiumTextField(
            controller: _passwordController,
            label: lp.translate('password'),
            hint: lp.translate('password_hint'),
            icon: Icons.lock_outline_rounded,
            theme: theme,
            isPassword: true,
            isPasswordVisible: _isPasswordVisible,
            onVisibilityToggle: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            validator: (v) => v == null || v.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 16),
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  textStyle: const TextStyle(
                      fontSize: 13, decoration: TextDecoration.underline),
                ),
                child: Text(lp.translate('forgot_password')),
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitAuthForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16161A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF1E1E22)),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Text(
                      lp.translate(_isLogin ? 'login_button' : 'signup_button'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(lp.translate(_isLogin ? 'no_account' : 'have_account'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade600, fontSize: 16)),
              GestureDetector(
                onTap: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  lp.translate(_isLogin ? 'signup_button' : 'login_button'),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F12) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? const Color(0xFF1E1E22) : Colors.grey.shade200),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword ? !isPasswordVisible : false,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: isDark ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? iconUrl;
  final IconData? icon;
  final String label;

  const _SocialButton(
      {required this.onPressed, this.iconUrl, this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF0F0F12),
          side: const BorderSide(color: Color(0xFF1E1E22)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconUrl != null)
              Image.network(iconUrl!, height: 18)
            else if (icon != null)
              Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher();

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(button.size.bottomRight(Offset.zero),
                ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        );
        showMenu(
          context: context,
          position: position,
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: [
            PopupMenuItem(
              value: 'en',
              child: Text(
                "🇺🇸 English",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'si',
              child: Text(
                "🇱🇰 Sinhala",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'ta',
              child: Text(
                "🇱🇰 Tamil",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ).then((value) {
          if (value != null) {
            debugPrint('🌍 Language changed to: $value');
            lp.setLanguage(value);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF1E1E22) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lp.currentLanguageName,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: isDark ? Colors.grey.shade600 : Colors.black54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  final String bgImage;
  const _IllustrationPanel({required this.bgImage});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0A0A0B)),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Opacity(
                opacity: 0.5,
                child: AnimatedSwitcher(
                  duration: const Duration(seconds: 2),
                  child: Transform.scale(
                    scale: 1.2, // Zoom in by 20%
                    child: Image.network(
                      bgImage,
                      key: ValueKey(bgImage),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: const Color(0xFF0A0A0B));
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.4),
                    const Color(0xFF0A0B10).withOpacity(1.0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lp.translate('travel_comfort'),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lp.translate('travel_description'),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        color: Colors.white70,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSwitcher extends StatelessWidget {
  const _ThemeSwitcher();
  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
        debugPrint('🎨 Theme toggled to: $newMode');
        themeController.setTheme(newMode);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF1E1E22) : Colors.grey.shade300,
          ),
        ),
        child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: isDark ? Colors.grey.shade400 : Colors.black87,
            size: 20),
      ),
    );
  }
}
