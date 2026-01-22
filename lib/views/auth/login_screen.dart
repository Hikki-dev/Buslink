// lib/views/auth/login_screen.dart
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
//  // Removed

// import 'phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Added
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Added
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false; // Added
  int _currentBgIndex = 0;
  Timer? _bgTimer;
  final List<String> _bgImages = [
    "https://live.staticflickr.com/65535/55025510678_c31eb6da24_b.jpg", // Flickr 1
    "https://live.staticflickr.com/65535/55025567979_f812048ac2_h.jpg", // Flickr 2
    "https://live.staticflickr.com/65535/55015711501_a4d336d2c0_b.jpg", // Flickr 3
    "https://upload.wikimedia.org/wikipedia/commons/e/e6/SLTB_Kandy_South_Depot_Mercedes-Benz_OP312_Bus_-_II.jpg",
    "https://upload.wikimedia.org/wikipedia/commons/8/87/CTB_bus_no._290.JPG",
  ];

  @override
  void initState() {
    super.initState();
    _currentBgIndex = Random().nextInt(_bgImages.length);
    _startBgTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages();
  }

  void _precacheImages() {
    for (String url in _bgImages) {
      precacheImage(NetworkImage(url), context);
    }
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _nameController.dispose(); // Added
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Added
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
        cred = await authService.signUpWithEmail(
            context,
            email,
            password,
            _phoneController.text.trim(),
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

  // void _appleSignIn() async {
  //   setState(() => _isLoading = true);
  //   final authService = Provider.of<AuthService>(context, listen: false);
  //   final cred = await authService.signInWithApple(context);

  //   if (mounted) {
  //     setState(() => _isLoading = false);
  //     if (cred != null && cred.user != null) {
  //       await Future.delayed(const Duration(milliseconds: 200));
  //       if (mounted) Navigator.of(context).pushReplacementNamed('/');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Fix: Prevent keyboard from squashing the background
      resizeToAvoidBottomInset: false,
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
                        // Theme & Language Switchers (Desktop)
                        Positioned(
                          top: 24,
                          right: 24,
                          child: Row(
                            children: [
                              const _ThemeSwitcher(),
                              // Language Switcher Removed
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: _IllustrationPanel(
                    bgImage: _bgImages[_currentBgIndex],
                    onDebugLogin: (email, pass) {
                      _emailController.text = email;
                      _passwordController.text = pass;
                      _submitAuthForm();
                    },
                  ),
                ),
              ],
            );
          } else {
            // Mobile Layout
            return Stack(
              children: [
                // Background stays static
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(seconds: 2),
                    child: Image.network(
                      _bgImages[_currentBgIndex],
                      key: ValueKey(_bgImages[_currentBgIndex]),
                      fit: BoxFit.cover,
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
                          Colors.red.shade900.withValues(alpha: 0.8),
                          Colors.red.shade800.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                // Scrollable Form Container that respects keyboard
                Positioned.fill(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 24,
                        // Add padding for keyboard manually
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
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
                ),
                // Theme & Language Switchers
                Positioned(
                  top: 16,
                  right: 16,
                  child: SafeArea(
                    child: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ThemeSwitcher(),
                          // Language Switcher Removed
                        ],
                      ),
                    ),
                  ),
                ),
                // HIDDEN DEBUG BUTTON (Mobile)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: HiddenDebugButton(
                    onDebugLogin: (email, pass) {
                      _emailController.text = email;
                      _passwordController.text = pass;
                      _submitAuthForm();
                    },
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
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
    // 

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Welcome!",
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin
                ? "Log in to BusLink to continue."
                : "Join us and start your journey today.",
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
                  label: "Continue with Google",
                ),
              ),
              const SizedBox(width: 12),
              // Phone Button Removed
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFF1E1E22))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("OR",
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
              const Expanded(child: Divider(color: Color(0xFF1E1E22))),
            ],
          ),
          const SizedBox(height: 32),
          if (!_isLogin) ...[
            _buildPremiumTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
              theme: theme,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Name is required';
                if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(v)) {
                  return 'Enter a valid name (Alphabets only)';
                }
                if (v.length < 3) return 'Name too short';
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],
          _buildPremiumTextField(
            controller: _emailController,
            label: "Email",
            hint: "Your email address",
            icon: Icons.email_outlined,
            theme: theme,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                  .hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 24),
            // Phone Number Removed
          ],
          const SizedBox(height: 24),
          _buildPremiumTextField(
            controller: _passwordController,
            label: "Password",
            hint: "Your password",
            icon: Icons.lock_outline_rounded,
            theme: theme,
            isPassword: true,
            isPasswordVisible: _isPasswordVisible,
            onVisibilityToggle: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            validator: (v) => v == null || v.length < 6
                ? 'Password must be at least 6 characters'
                : null,
            onFieldSubmitted: _submitAuthForm, // Submit on Enter
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 24),
            _buildPremiumTextField(
              controller: _confirmPasswordController,
              label:
                  'Confirm Password', // Hardcoded for now, or use lp.translate
              hint: 'Re-enter your password',
              icon: Icons.lock_outline_rounded,
              theme: theme,
              isPassword: true,
              isPasswordVisible:
                  _isConfirmPasswordVisible, // Use separate state
              onVisibilityToggle: () => setState(() =>
                  _isConfirmPasswordVisible =
                      !_isConfirmPasswordVisible), // Toggle
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
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
                child: Text("Forgot Password?"),
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
                      _isLogin ? "Log In" : "Sign Up",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4, // Horizontal spacing
            runSpacing: 4, // Vertical spacing if it wraps
            children: [
              Text(
                  _isLogin
                      ? "Don't have an account?"
                      : "Already have an account?",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade600, fontSize: 16)),
              GestureDetector(
                onTap: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? "Sign Up" : "Login",
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
    VoidCallback? onFieldSubmitted, // NEW: Callback for Submit
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
            textInputAction: isPassword
                ? TextInputAction.done
                : TextInputAction.next, // Keyboard Action
            onFieldSubmitted: (_) => onFieldSubmitted?.call(), // Trigger Submit
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
  final String label;

  const _SocialButton(
      {required this.onPressed, this.iconUrl, required this.label});

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
            if (iconUrl != null) Image.network(iconUrl!, height: 18),
            // if (icon != null) Icon(icon, size: 18, color: Colors.white), // Removed unused logic
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

// Language Switcher Class Removed

class _IllustrationPanel extends StatelessWidget {
  final String bgImage;
  final Function(String email, String pass)? onDebugLogin;

  const _IllustrationPanel({required this.bgImage, this.onDebugLogin});

  @override
  Widget build(BuildContext context) {
    // 
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
                    AppTheme.primaryColor.withValues(alpha: 0.4),
                    const Color(0xFF0A0B10).withValues(alpha: 1.0),
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
                    'Travel with\nComfort & Style',
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
                    'Join thousands of satisfied travelers who trust\nBusLink for their daily commutes.',
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
          // HIDDEN DEBUG BUTTON
          if (onDebugLogin != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: HiddenDebugButton(onDebugLogin: onDebugLogin!),
            ),
        ],
      ),
    );
  }
}

class HiddenDebugButton extends StatelessWidget {
  final Function(String, String) onDebugLogin;
  const HiddenDebugButton({super.key, required this.onDebugLogin});

  @override
  Widget build(BuildContext context) {
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
