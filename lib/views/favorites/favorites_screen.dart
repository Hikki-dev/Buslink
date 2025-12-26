import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../controllers/trip_controller.dart';
import '../../services/auth_service.dart';

class FavoritesScreen extends StatelessWidget {
  final bool showBackButton;
  const FavoritesScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final controller = Provider.of<TripController>(context, listen: false);
    final user = authService.currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("My Favourites",
            style: GoogleFonts.outfit(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: showBackButton ? const BackButton(color: Colors.black) : null,
      ),
      body: user == null
          ? Center(
              child: Text("Please log in to view favorites",
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
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
                            style: GoogleFonts.inter(
                                fontSize: 18, color: Colors.grey)),
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
                        await controller.removeFavorite(user.uid, fav['id']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Removed from favourites")),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _FavoriteItemCard extends StatelessWidget {
  final String from;
  final String to;
  final String operator;
  final String price;
  final VoidCallback onRemove;

  const _FavoriteItemCard({
    required this.from,
    required this.to,
    required this.operator,
    required this.price,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
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
                          Text("FROM",
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(from,
                              style: GoogleFonts.outfit(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.grey.shade300),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("TO",
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Text(to,
                              style: GoogleFonts.outfit(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
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
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                        Text("Standard Bus",
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Text(price,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor))
                  ],
                ),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Searching for this route...")));
                      // Navigate to search
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0),
                    child: Text("BOOK NOW",
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, color: Colors.white)),
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
                  color: Colors.red.shade50,
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
