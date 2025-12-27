// lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this import
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart'; // Import AppTheme to access colors directly if needed

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // Toggles between Login and Sign Up
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _submitAuthForm() async {
    setState(() {
      _isLoading = true;
    });
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

      // Variable to hold credential
      dynamic cred;

      if (_isLogin) {
        cred = await authService.signInWithEmail(
          context,
          email,
          password,
        );
      } else {
        cred = await authService.signUpWithEmail(
          context,
          email,
          password,
        );
      }

      // Manual Navigation Fallback
      if (cred != null && cred.user != null && mounted) {
        // Stop loading first
        setState(() => _isLoading = false);

        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          debugPrint("Manual navigation fallback triggered (Email)");
          Navigator.of(context).pushReplacementNamed('/');
        }
        return; // Exit function so finally block doesn't mess with state if unmounted
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _googleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    final authService = Provider.of<AuthService>(context, listen: false);

    // 1. Attempt Sign In
    final cred = await authService.signInWithGoogle(context);

    if (mounted) {
      // 2. Stop Loading
      setState(() {
        _isLoading = false;
      });

      // 3. Manual Fallback: If we have a user but UI didn't update, force a navigation
      if (cred != null && cred.user != null) {
        // We use a small delay to let StreamProvider update first if possible
        await Future.delayed(const Duration(milliseconds: 200));

        // If we are still on this screen (mounted), force a reload of the app root
        if (mounted) {
          debugPrint("Manual navigation fallback triggered");
          // Navigator.of(context).popUntil((route) => route.isFirst);
          // This triggers a rebuild of the route, hopefully firing AuthWrapper
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Desktop / Web View
            return Row(
              key: const ValueKey("desktop_login"),
              children: [
                const Expanded(flex: 6, child: _LeftPanel()),
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Padding(
                            padding: const EdgeInsets.all(60.0),
                            child: _buildAnimatedForm(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile View
            return Stack(
              key: const ValueKey("mobile_login"),
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.network(
                    "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80",
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient Overlay
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
                // Form Content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
        style: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    ]);
  }

  Widget _buildAnimatedForm(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (MediaQuery.of(context).size.width > 900) ...[
            // Desktop Header inside form
            Text(
              'Hello Again! 👋',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin
                  ? 'Welcome back, you\'ve been missed!'
                  : 'Join us and start your journey today.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 48),
          ] else ...[
            // Mobile Title
            Text(
              _isLogin ? 'Welcome Back' : 'Create Account',
              style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],

          // Email Field
          _buildPremiumTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'name@example.com',
              icon: Icons.email_outlined,
              theme: theme,
              validator: (v) {
                if (v == null || v.isEmpty) return "Email is required";
                if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                    .hasMatch(v)) {
                  return "Enter a valid email address";
                }
                return null;
              }),
          const SizedBox(height: 20),

          // Password Field
          _buildPremiumTextField(
              controller: _passwordController,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              isPassword: true,
              theme: theme,
              isPasswordVisible: _isPasswordVisible,
              onVisibilityToggle: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              validator: (v) {
                if (v == null || v.isEmpty) return "Password is required";
                if (v.length < 6) {
                  return "Password must be at least 6 characters";
                }
                return null;
              }),

          // Recovery Password
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: theme.primaryColor,
                  ),
                  child: const Text("Recovery Password"),
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Sign In Button
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _submitAuthForm,
                style: ElevatedButton.styleFrom(
                  elevation: 8,
                  shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isLogin ? 'Sign In' : 'Sign Up',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                    child: Divider(color: Colors.grey.shade200, thickness: 2)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Or continue with",
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                    child: Divider(color: Colors.grey.shade200, thickness: 2)),
              ],
            ),

            const SizedBox(height: 32),

            // Google Button
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _googleSignIn,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade200, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: AppTheme.darkText,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/google.jpeg',
                      height: 24.0,
                    ),
                    const SizedBox(width: 12),
                    const Text('Google Account',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Toggle Login/Signup
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_isLogin ? "Not a member? " : "Already a member? ",
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin ? "Register now" : "Sign in",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ]
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword ? !isPasswordVisible : false,
            style: const TextStyle(fontWeight: FontWeight.w600),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              prefixIcon: Icon(icon, color: Colors.grey.shade400),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
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

class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        image: DecorationImage(
          image: NetworkImage(
              "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80"), // Red Bus
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.red.shade900.withValues(alpha: 0.9),
              Colors.red.shade600.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "New Experience",
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Travel with\nComfort & Style",
                style: GoogleFonts.outfit(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Join thousands of satisfied travelers who trust BusLink for their daily commutes and long-distance journeys.",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildStatItem("10k+", "Users"),
                  const SizedBox(width: 40),
                  _buildStatItem("500+", "Buses"),
                  const SizedBox(width: 40),
                  _buildStatItem("50+", "Cities"),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
      ],
    );
  }
}
