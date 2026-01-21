import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../layout/app_footer.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _LandingHero(),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _LandingHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height, // Full screen hero
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
              "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            // Simple Navbar
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_bus,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 8),
                      Text("BusLink",
                          style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text("Login",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

            // Hero Content
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Travel with Comfort & Style",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              fontSize: isDesktop ? 64 : 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Sri Lanka's most reliable bus booking platform. Book your tickets instantly and travel stress-free.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: isDesktop ? 20 : 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5),
                        ),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 48 : 32,
                                vertical: isDesktop ? 24 : 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                          child: Text("GET STARTED",
                              style: GoogleFonts.outfit(
                                  fontSize: isDesktop ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
