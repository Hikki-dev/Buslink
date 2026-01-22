import 'package:flutter/material.dart';

class NewsCarousel extends StatelessWidget {
  const NewsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Promo Data
    final List<Map<String, dynamic>> news = [
      {
        "title": "Track Your Bus Live",
        "subtitle": "See exactly where your bus is right now.",
        "color": Colors.blue.shade800,
        "icon": Icons.gps_fixed,
      },
      {
        "title": "Need Help?",
        "subtitle": "Contact our 24/7 support team for assistance.",
        "color": Colors.orange.shade800,
        "icon": Icons.support_agent,
      },
      {
        "title": "Manage Bookings",
        "subtitle": "View or cancel your upcoming trips easily.",
        "color": Colors.purple.shade700,
        "icon": Icons.confirmation_number,
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 120, // Compact height
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.9), // Peek next item
          itemCount: news.length,
          itemBuilder: (context, index) {
            final item = news[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item['color'],
                    (item['color'] as Color).withValues(alpha: 0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: (item['color'] as Color).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: Icon(item['icon'], color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item['title'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Outfit')),
                        const SizedBox(height: 4),
                        Text(item['subtitle'],
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Inter'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
