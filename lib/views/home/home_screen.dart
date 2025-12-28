// lib/views/home/home_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/language_provider.dart';
import '../results/bus_list_screen.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';

// Mock Data for Popular Destinatinos
final List<Map<String, dynamic>> _allDestinations = [
  {
    'city': 'Colombo',
    'image':
        'https://images.unsplash.com/photo-1578508479831-7e5088235288?auto=format&fit=crop&q=80',
    'buses': 120,
    'desc':
        'The commercial capital with vibrant street life and colonial heritage.'
  },
  {
    'city': 'Kandy',
    'image':
        'https://images.unsplash.com/photo-1596700773663-8328de8d3381?auto=format&fit=crop&q=80',
    'buses': 85,
    'desc': 'Home to the Temple of the Tooth Relic and scenic lake views.'
  },
  {
    'city': 'Galle',
    'image':
        'https://images.unsplash.com/photo-1550955217-08709d7cf744?auto=format&fit=crop&q=80',
    'buses': 64,
    'desc': 'Famous for its 17th-century Dutch Fort and coastal charm.'
  },
  {
    'city': 'Ella',
    'image':
        'https://images.unsplash.com/photo-1566838029562-b13c77d54406?auto=format&fit=crop&q=80',
    'buses': 42,
    'desc': 'A hill country paradise known for hiking and the Nine Arch Bridge.'
  },
  {
    'city': 'Nuwara Eliya',
    'image':
        'https://images.unsplash.com/photo-1546708773-e57c8d352dbd?auto=format&fit=crop&q=80',
    'buses': 30,
    'desc': 'Little England of Sri Lanka, surrounded by tea plantations.'
  },
  {
    'city': 'Sigiriya',
    'image':
        'https://images.unsplash.com/photo-1625992983637-25e4c0dde47e?auto=format&fit=crop&q=80',
    'buses': 25,
    'desc': 'Ancient rock fortress and a UNESCO World Heritage site.'
  },
  {
    'city': 'Jaffna',
    'image':
        'https://images.unsplash.com/photo-1620202860822-4c9197c369fc?auto=format&fit=crop&q=80',
    'buses': 45,
    'desc': 'Cultural hub of the north with unique Hindu traditions.'
  },
  {
    'city': 'Trincomalee',
    'image':
        'https://images.unsplash.com/photo-1587595431973-160d0d94add1?auto=format&fit=crop&q=80',
    'buses': 35,
    'desc': 'Home to Nilaveli Beach and Koneswaram Temple.'
  }
];

class HomeScreen extends StatefulWidget {
  final bool isAdminView;
  const HomeScreen({super.key, this.isAdminView = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  bool _isRoundTrip = false;
  bool _isBulkBooking = false;

  List<Map<String, dynamic>> _currentDestinations = [];

  @override
  void initState() {
    super.initState();
    // Shuffle and pick 4
    var list = List<Map<String, dynamic>>.from(_allDestinations);
    list.shuffle();
    _currentDestinations = list.take(4).toList();
  }

  void _searchBuses() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter origin and destination')),
      );
      return;
    }

    final tripController = Provider.of<TripController>(context, listen: false);
    tripController.setFromCity(_originController.text);
    tripController.setToCity(_destinationController.text);
    tripController.setDate(_selectedDate);
    tripController.setRoundTrip(_isRoundTrip);
    tripController.setBulkMode(_isBulkBooking);

    // Trigger the actual Firestore search
    tripController.searchTrips(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BusListScreen(),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          if (widget.isAdminView)
            Container(
              width: double.infinity,
              color: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Welcome Admin - Preview Mode",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text("EXIT",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                if (isDesktop)
                  const SliverToBoxAdapter(
                      child: DesktopNavBar(selectedIndex: 0)),
                SliverToBoxAdapter(
                  child: _HeroSection(
                    isDesktop: isDesktop,
                    originController: _originController,
                    destinationController: _destinationController,
                    selectedDate: _selectedDate,
                    onDateTap: () => _selectDate(context),
                    onSearchTap: _searchBuses,
                    isRoundTrip: _isRoundTrip,
                    isBulkBooking: _isBulkBooking,
                    onRoundTripChanged: (val) =>
                        setState(() => _isRoundTrip = val),
                    onBulkBookingChanged: (val) =>
                        setState(() => _isBulkBooking = val),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  sliver: SliverToBoxAdapter(
                    child: _FeaturesSection(isDesktop: isDesktop),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _PopularDestinationsGrid(
                    isDesktop: isDesktop,
                    destinations: _currentDestinations,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                if (isDesktop) const SliverToBoxAdapter(child: AppFooter()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatefulWidget {
  final bool isDesktop;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final VoidCallback onSearchTap;
  final bool isRoundTrip;
  final bool isBulkBooking;
  final ValueChanged<bool> onRoundTripChanged;
  final ValueChanged<bool> onBulkBookingChanged;

  const _HeroSection({
    required this.isDesktop,
    required this.originController,
    required this.destinationController,
    required this.selectedDate,
    required this.onDateTap,
    required this.onSearchTap,
    required this.isRoundTrip,
    required this.isBulkBooking,
    required this.onRoundTripChanged,
    required this.onBulkBookingChanged,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  int _currentImageIndex = 0;
  Timer? _timer;

  final List<Map<String, String>> _heroData = [
    {
      "image":
          "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80",
      "subtitle":
          "Book your bus tickets instantly with BusLink. Reliable, fast, and secure."
    },
    {
      "image":
          "https://images.unsplash.com/photo-1570125909232-eb263c188f7e?auto=format&fit=crop&q=80",
      "subtitle":
          "Discover the most beautiful routes across the island in comfort."
    },
    {
      "image":
          "https://images.unsplash.com/photo-1561361513-2d000a50f0dc?auto=format&fit=crop&q=80",
      "subtitle": "Seamless payments and real-time tracking for your journey."
    },
    {
      "image":
          "https://images.unsplash.com/photo-1557223562-6c77ef16210f?auto=format&fit=crop&q=80",
      "subtitle": "Experience premium travel with our top-rated bus operators."
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentImageIndex = Random().nextInt(_heroData.length);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _heroData.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Container(
      height: widget.isDesktop ? 600 : 500,
      width: double.infinity,
      child: Stack(
        children: [
          // Background Image with AnimatedSwitcher
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: Container(
                key: ValueKey(_heroData[_currentImageIndex]["image"]),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                        _heroData[_currentImageIndex]["image"] ?? ""),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lp.translate('find_bus'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: widget.isDesktop ? 64 : 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Animated Subtitle Text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _heroData[_currentImageIndex]["subtitle"] ?? "",
                        key:
                            ValueKey(_heroData[_currentImageIndex]["subtitle"]),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: widget.isDesktop ? 18 : 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Search Bar
                    _buildSearchCard(context, lp),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context, LanguageProvider lp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildTabButton(String text, bool isActive, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: isActive
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2))),
            child: Text(text,
                style: TextStyle(
                    color:
                        isActive ? AppTheme.primaryColor : Colors.grey.shade600,
                    fontWeight: FontWeight.bold))),
      );
    }

    if (widget.isDesktop) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161821) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  buildTabButton("One Way", !widget.isRoundTrip,
                      () => widget.onRoundTripChanged(false)),
                  const SizedBox(width: 16),
                  buildTabButton("Round Trip", widget.isRoundTrip,
                      () => widget.onRoundTripChanged(true)),
                  const Spacer(),
                  Row(
                    children: [
                      Checkbox(
                        value: widget.isBulkBooking,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (v) => widget.onBulkBookingChanged(v!),
                      ),
                      Text("Bulk / Multi-day Booking",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSearchInput(
                      controller: widget.originController,
                      icon: Icons.location_on_outlined,
                      label: 'From',
                      hint: 'Enter origin',
                    ),
                  ),
                  Container(
                      height: 40,
                      width: 1,
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  Expanded(
                    child: _buildSearchInput(
                      controller: widget.destinationController,
                      icon: Icons.navigation_outlined,
                      label: 'To',
                      hint: 'Enter destination',
                    ),
                  ),
                  Container(
                      height: 40,
                      width: 1,
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  Expanded(
                    child: InkWell(
                      onTap: widget.onDateTap,
                      child: _buildSearchDisplay(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: DateFormat('EEE, d MMM')
                            .format(widget.selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 64,
                    width: 150,
                    child: ElevatedButton(
                      onPressed: widget.onSearchTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Search Card
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161821) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: buildTabButton("One Way", !widget.isRoundTrip,
                      () => widget.onRoundTripChanged(false)),
                ),
                Expanded(
                  child: buildTabButton("Round Trip", widget.isRoundTrip,
                      () => widget.onRoundTripChanged(true)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: widget.isBulkBooking,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) => widget.onBulkBookingChanged(v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text("Bulk / Multi-day Booking",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87)),
                  ),
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey)
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSearchInput(
              controller: widget.originController,
              icon: Icons.location_on_outlined,
              label: 'From',
              hint: 'Enter origin',
            ),
            const Divider(height: 32),
            _buildSearchInput(
              controller: widget.destinationController,
              icon: Icons.navigation_outlined,
              label: 'To',
              hint: 'Enter destination',
            ),
            const Divider(height: 32),
            InkWell(
              onTap: widget.onDateTap,
              child: _buildSearchDisplay(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: DateFormat('EEE, d MMM').format(widget.selectedDate),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onSearchTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Search Buses',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSearchInput({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchDisplay({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  final bool isDesktop;
  const _FeaturesSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isDesktop) {
                return Row(
                  children: [
                    _FeatureItem(
                      icon: Icons.bolt,
                      title: 'Fast Booking',
                      description:
                          'Book your seats in less than 60 seconds with our streamlined flow.',
                    ),
                    _FeatureItem(
                      icon: Icons.shield_outlined,
                      title: 'Secure Payments',
                      description:
                          'Your transactions are protected with industry-standard encryption.',
                    ),
                    _FeatureItem(
                      icon: Icons.location_on_outlined,
                      title: 'Live Tracking',
                      description:
                          'Track your bus in real-time and never miss your ride again.',
                    ),
                    _FeatureItem(
                      icon: Icons.support_agent,
                      title: '24/7 Support',
                      description:
                          'Our dedicated team is always here to help with your journey.',
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _FeatureItem(
                      icon: Icons.bolt,
                      title: 'Fast Booking',
                      description: 'Book your seats in less than 60 seconds.',
                    ),
                    const SizedBox(height: 32),
                    _FeatureItem(
                      icon: Icons.shield_outlined,
                      title: 'Secure Payments',
                      description:
                          'Protected with industry-standard encryption.',
                    ),
                    const SizedBox(height: 32),
                    _FeatureItem(
                      icon: Icons.location_on_outlined,
                      title: 'Live Tracking',
                      description: 'Track your bus in real-time on our map.',
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularDestinationsGrid extends StatelessWidget {
  final bool isDesktop;
  final List<Map<String, dynamic>> destinations;

  const _PopularDestinationsGrid({
    required this.isDesktop,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lp.translate('popular_destinations'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 4 : 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.8,
                children: destinations.map((dest) {
                  return _DestinationCard(
                    city: dest['city'],
                    imageUrl: dest['image'],
                    busCount: dest['buses'],
                    description: dest['desc'],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatefulWidget {
  final String city;
  final String imageUrl;
  final int busCount;
  final String description;

  const _DestinationCard({
    required this.city,
    required this.imageUrl,
    required this.busCount,
    this.description = '',
  });

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.white24, size: 40),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Gradient
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(_isHovering ? 0.95 : 0.8),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            // Text Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.city,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedCrossFade(
                    firstChild: Text(
                      '${widget.busCount} Buses Daily',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.busCount} Buses Daily',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: _isHovering
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
