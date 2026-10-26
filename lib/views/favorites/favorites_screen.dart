import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/bl_colors.dart';
import '../home/home_sections.dart' show cityPhoto;
import '../layout/app_footer.dart';
import '../layout/desktop_navbar.dart';
import '../customer_main_screen.dart';
import '../widgets/bl_widgets.dart';

/// "My favourites" (mockups "Favourites" and "Desktop-Favourites").
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
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final controller = Provider.of<TripController>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    Widget body;
    if (user == null) {
      body = const BlEmpty(
          icon: Icons.lock_outline,
          title: 'Please log in to continue',
          message: 'Your trips and favourites are saved to your account.');
    } else {
      body = StreamBuilder<List<Map<String, dynamic>>>(
        stream: controller.getUserFavoriteRoutes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: BL.crimson));
          }
          final favs = (snap.data ?? []).where((f) => f['id'] != null).toList();
          if (favs.isEmpty) {
            return const BlEmpty(
                icon: Icons.favorite_border,
                title: 'No favourites yet',
                message:
                    'Tap the heart on a bus to save the route. It will be here for quick booking.');
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 600),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 14,
                  children: [
                    for (final f in favs)
                      SizedBox(
                        width: isDesktop
                            ? 380
                            : MediaQuery.of(context).size.width - 32,
                        height: 150,
                        child: _FavCard(
                          from: (f['fromCity'] ?? 'Unknown').toString(),
                          to: (f['toCity'] ?? 'Unknown').toString(),
                          operator: (f['operatorName'] ?? '').toString(),
                          price: f['price'] != null
                              ? 'LKR ${f['price']}'
                              : 'Price varies',
                          onRemove: () async {
                            await controller.removeFavorite(f['id']);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Removed from favourites')));
                            }
                          },
                          onBook: () {
                            controller.setFromCity(f['fromCity']);
                            controller.setToCity(f['toCity']);
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const CustomerMainScreen(
                                      initialIndex: 0)),
                              (r) => false,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: BL.surface,
        body: Column(children: [
          BlHeader(
              title: 'My Favourites',
              subtitle: 'Routes you travel often',
              showBack: showBackButton,
              onBack: onBack),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: BL.surface,
      body: FooterScroll(children: [
        DesktopNavBar(selectedIndex: 2, isAdminView: isAdminView),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My favourites',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
                  Text('Routes you travel often',
                      style: TextStyle(fontSize: 18, color: BL.muted)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 360, child: body),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _FavCard extends StatelessWidget {
  final String from;
  final String to;
  final String operator;
  final String price;
  final VoidCallback onRemove;
  final VoidCallback onBook;
  const _FavCard({
    required this.from,
    required this.to,
    required this.operator,
    required this.price,
    required this.onRemove,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(cityPhoto(to),
              fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x0D000000), Color(0xE6320304)],
                stops: [0.2, 1],
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Semantics(
              button: true,
              label: 'Remove $from to $to from favourites',
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.favorite, color: BL.link, size: 24),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$from to $to',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      Text(
                          '${operator.isEmpty ? 'Standard Bus' : operator} · $price',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onBook,
                    style: FilledButton.styleFrom(
                      backgroundColor: BL.surface,
                      foregroundColor: BL.crimson,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                    ),
                    child: const Text('BOOK AGAIN'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
