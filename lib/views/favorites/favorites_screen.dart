import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../controllers/trip_controller.dart';
import '../../services/auth_service.dart';
import '../results/bus_list_screen.dart';
import '../layout/desktop_navbar.dart';

class FavoritesScreen extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBookNow;
  const FavoritesScreen(
      {super.key, this.showBackButton = true, this.onBookNow});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final controller = Provider.of<TripController>(context, listen: false);
    final user = authService.currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Column(
      children: [
        if (isDesktop) const DesktopNavBar(selectedIndex: 2),
        Expanded(
          child: Scaffold(
            // Use theme background
            appBar: AppBar(
              title: Text("My Favourites",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
              centerTitle: true,
              elevation: 0,
              // Remove manual background color to use theme
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
                    stream: controller.getUserFavorites(user.uid),
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

                      final favorites = snapshot.data!;

                      return GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 1,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: isDesktop ? 1.5 : 1.8,
                        ),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final fav = favorites[index];
                          return _FavoriteItemCard(
                            from: fav['fromCity'] ?? 'Unknown',
                            to: fav['toCity'] ?? 'Unknown',
                            operator: fav['operatorName'] ?? 'Unknown',
                            price: fav['price'] != null
                                ? "LKR ${fav['price']}"
                                : "Price Varies",
                            onRemove: () async {
                              await controller.removeFavorite(
                                  user.uid, fav['id']);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Removed from favourites")),
                                );
                              }
                            },
                            onBook: () {
                              // 1. Pre-fill Search
                              controller.setFromCity(fav['fromCity']);
                              controller.setToCity(fav['toCity']);
                              controller.setDepartureDate(DateTime.now());

                              // 2. Navigate
                              controller.searchTrips(context); // Trigger search
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const BusListScreen()),
                              );
                            },
                          );
                        },
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Route
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("FROM",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(from,
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("TO",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(to,
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

                // Operator & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(price,
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor))
                  ],
                ),

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
                    child: const Text("BOOK AGAIN",
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
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.red, size: 18),
              ),
            ),
          )
        ],
      ),
    );
  }
}
