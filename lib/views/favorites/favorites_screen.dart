import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
//
import '../../controllers/trip_controller.dart';
import '../../services/auth_service.dart';
// import '../results/bus_list_screen.dart';
import '../layout/desktop_navbar.dart';

// import '../layout/mobile_navbar.dart';
import '../layout/custom_app_bar.dart';

import '../customer_main_screen.dart';
import '../widgets/animated_favorite_button.dart';

class FavoritesScreen extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBookNow;
  final VoidCallback? onBack;

  final bool isAdminView;

  const FavoritesScreen(
      {super.key,
      this.showBackButton = true,
      this.onBookNow,
      this.onBack,
      this.isAdminView = false});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final controller = Provider.of<TripController>(context, listen: false);
    final user = authService.currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Column(
      children: [
        if (isDesktop)
          Material(
            elevation: 4,
            child: DesktopNavBar(selectedIndex: 2, isAdminView: isAdminView),
          ),
        Expanded(
          child: Scaffold(
            // bottomNavigationBar:
            //    isDesktop ? null : const MobileBottomNav(selectedIndex: 2),
            // Use theme background
            appBar: CustomAppBar(
              hideActions:
                  isDesktop, // Hide actions on Desktop (they are in Navbar), show on Mobile
              automaticallyImplyLeading: showBackButton && !isDesktop,
              leading: showBackButton && !isDesktop
                  ? BackButton(
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () {
                        if (onBack != null) {
                          onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      })
                  : null,
              title: Text("My Favourites",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: user == null
                ? Center(
                    child: Text("Please log in to view favorites",
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface)),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: controller.getUserFavoriteRoutes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("No favourites yet",
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                            ],
                          ),
                        );
                      }

                      final favorites =
                          snapshot.data!.where((f) => f['id'] != null).toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: favorites.map((fav) {
                              return SizedBox(
                                width: isDesktop
                                    ? 450
                                    : MediaQuery.of(context).size.width -
                                        48, // Responsive width
                                child: _FavoriteItemCard(
                                  from: fav['fromCity'] ?? 'Unknown',
                                  to: fav['toCity'] ?? 'Unknown',
                                  operator: fav['operatorName'] ?? 'Unknown',
                                  price: fav['price'] != null
                                      ? "LKR ${fav['price']}"
                                      : "Price Varies",
                                  onRemove: () async {
                                    await controller.removeFavorite(fav['id']);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Removed from favourites")),
                                      );
                                    }
                                  },
                                  onBook: () {
                                    controller.setFromCity(fav['fromCity']);
                                    controller.setToCity(fav['toCity']);
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const CustomerMainScreen(
                                                  initialIndex: 0)),
                                      (route) => false,
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteItemCard extends StatelessWidget {
  final String from;
  final String to;
  final String operator;
  final String price;
  final VoidCallback onRemove;
  final VoidCallback onBook;

  const _FavoriteItemCard({
    required this.from,
    required this.to,
    required this.operator,
    required this.price,
    required this.onRemove,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A1D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Removed
              children: [
                // Route
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text("FROM",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(from,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.grey.shade500),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text("TO",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(to,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Added spacing

                // Operator & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Centered
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(operator,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface)),
                        const Text("Standard Bus",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(width: 24), // Spacing
                    Text(price,
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor))
                  ],
                ),
                const SizedBox(height: 16), // Added spacing

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0),
                    child: Text("BOOK AGAIN",
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedFavoriteButton(
              isFavorite: true,
              size: 18,
              onToggle: onRemove,
            ),
          )
        ],
      ),
    );
  }
}
