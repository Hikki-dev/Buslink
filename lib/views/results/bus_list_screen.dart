import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for Google Maps link
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../booking/seat_selection_screen.dart';
import '../../utils/app_theme.dart';
import '../layout/desktop_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../layout/app_footer.dart';
import '../../services/auth_service.dart';

class BusListScreen extends StatefulWidget {
  const BusListScreen({super.key});

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  String _sortBy = 'price_asc';
  final List<String> _selectedFilters = [];

  // Weather & Time State
  late Timer _timer;
  final MapController _mapController = MapController();
  DateTime _currentTime = DateTime.now();
  String _weatherCondition = "Sunny";
  int _temperature = 29;

  @override
  void initState() {
    super.initState();
    // Update time every minute
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Fetch real weather
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWeather();
    });
  }

  Future<void> _fetchWeather() async {
    final controller = Provider.of<TripController>(context, listen: false);
    // Prioritize destination for weather as it's more relevant for travelers
    final city = controller.toCity ?? controller.fromCity ?? "Colombo";
    // Fallback if env not loaded
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("Warning: OPENWEATHER_API_KEY not found in .env");
      return;
    }

    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _temperature = (data['main']['temp'] as num).round();
            // Capitalize first letter
            String desc = data['weather'][0]['main'];
            _weatherCondition = desc; // "Clouds", "Clear", "Rain" etc.
          });
        }
      } else {
        debugPrint("Weather API Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching weather: $e");
    }
  }

  void _recenterMap() {
    final controller = Provider.of<TripController>(context, listen: false);
    if (controller.fromCity != null &&
        controller.toCity != null &&
        _cityCoordinates.containsKey(controller.fromCity) &&
        _cityCoordinates.containsKey(controller.toCity)) {
      final p1 = _cityCoordinates[controller.fromCity]!;
      final p2 = _cityCoordinates[controller.toCity]!;

      // Create bounds that include both points
      final bounds = LatLngBounds(p1, p2);

      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ));
    } else {
      // Default center
      _mapController.move(const latlng.LatLng(7.8731, 80.7718), 7);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 1000;

    List<Trip> trips = List.from(controller.searchResults);

    // Filter Logic
    if (_selectedFilters.isNotEmpty) {
      trips = trips.where((trip) {
        final timeOptions = [
          "Before 6 am",
          "6 am to 12 pm",
          "12 pm to 6 pm",
          "After 6 pm"
        ];

        final selectedTimes =
            _selectedFilters.where((f) => timeOptions.contains(f)).toList();

        if (selectedTimes.isNotEmpty) {
          bool timeMatch = false;
          final hour = trip.departureTime.hour;
          for (final filter in selectedTimes) {
            if (filter == "Before 6 am" && hour < 6) {
              timeMatch = true;
            }
            if (filter == "6 am to 12 pm" && hour >= 6 && hour < 12) {
              timeMatch = true;
            }
            if (filter == "12 pm to 6 pm" && hour >= 12 && hour < 18) {
              timeMatch = true;
            }
            if (filter == "After 6 pm" && hour >= 18) {
              timeMatch = true;
            }
          }
          if (!timeMatch) return false;
        }

        return true;
      }).toList();
    }

    // Sort Logic
    if (_sortBy == 'price_asc') {
      trips.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'time_asc') {
      trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isDesktop
          ? _buildDesktopLayout(context, isDesktop, trips, controller)
          : _buildMobileLayout(context, trips, controller),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDesktop,
      List<Trip> trips, TripController controller) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: DesktopNavBar()),
        // Replaced Date Bar with Weather/Map Header
        SliverToBoxAdapter(child: _buildInfoHeader(context, controller)),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 280,
                      child: _buildFilters(context),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildResultsHeader(trips.length),
                          const SizedBox(height: 16),
                          if (controller.isLoading)
                            const Center(
                                child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator()))
                          else if (trips.isEmpty)
                            _buildEmptyState()
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: trips.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) =>
                                  _BusTicketCard(trip: trips[index]),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 40),
              if (isDesktop) const AppFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, List<Trip> trips, TripController controller) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.fromCity} ➔ ${controller.toCity}',
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: const [RouteFavoriteButton()],
        // Using info header in mobile too, maybe simplified?
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMobileFilterModal(context),
        label: const Text("Filters"),
        icon: const Icon(Icons.tune),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length + 1, // +1 for Header
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, index) {
          if (index == 0) {
            return _buildInfoHeader(context, controller, isMobile: true);
          }
          return _BusTicketCard(trip: trips[index - 1]);
        },
      ),
    );
  }

  // --- NEW: Info Header with Weather, Time & Map ---
  Widget _buildInfoHeader(BuildContext context, TripController controller,
      {bool isMobile = false}) {
    // Determine which city's weather is being shown
    final weatherCity = controller.toCity ?? controller.fromCity ?? "Colombo";

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // 1. Weather & Time Row
              if (isMobile)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getWeatherIcon(_weatherCondition),
                            color: _getWeatherColor(_weatherCondition),
                            size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$_temperature°C, $_weatherCondition",
                                style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            Text(weatherCity,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Colors.grey.shade600))
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Text(DateFormat('hh:mm:ss a').format(_currentTime),
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: AppTheme.primaryColor)),
                        Text(
                            DateFormat('EEEE, d MMMM yyyy')
                                .format(_currentTime),
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors.grey.shade600))
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Weather
                    Row(
                      children: [
                        Icon(_getWeatherIcon(_weatherCondition),
                            color: _getWeatherColor(_weatherCondition),
                            size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$_temperature°C, $_weatherCondition",
                                style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            Text(weatherCity,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Colors.grey.shade600))
                          ],
                        )
                      ],
                    ),
                    // Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const RouteFavoriteButton(),
                            const SizedBox(width: 8),
                            Text(DateFormat('hh:mm:ss a').format(_currentTime),
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppTheme.primaryColor)),
                          ],
                        ),
                        Text(
                            DateFormat('EEEE, d MMMM yyyy')
                                .format(_currentTime),
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors.grey.shade600))
                      ],
                    )
                  ],
                ),
              const SizedBox(height: 24),
              // 2. Map Route Preview
              RepaintBoundary(
                child: Container(
                  height: isMobile ? 200 : 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: latlng.LatLng(
                              7.8731, 80.7718), // Sri Lanka Center
                          initialZoom: 7,
                          interactionOptions: InteractionOptions(
                              flags: InteractiveFlag.all &
                                  ~InteractiveFlag.rotate),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.buslink.app',
                          ),
                          PolylineLayer(
                            polylines: _createPolylines(controller),
                          ),
                          MarkerLayer(
                            markers: _createMarkers(controller),
                          ),
                        ],
                      ),
                      Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12, blurRadius: 4)
                                  ]),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map,
                                      size: 16, color: AppTheme.primaryColor),
                                  SizedBox(width: 8),
                                  Text("Live Route Preview",
                                      style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87)),
                                ],
                              ))),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final query =
                                "${controller.fromCity} to ${controller.toCity}";
                            final googleMapsUrl = Uri.parse(
                                "https://www.google.com/maps/search/?api=1&query=$query");
                            if (await canLaunchUrl(googleMapsUrl)) {
                              await launchUrl(googleMapsUrl);
                            }
                          },
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text("Open Google Maps"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 2),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          heroTag: "recenter_map_btn",
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          onPressed: _recenterMap,
                          tooltip: "Recenter Map",
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Map Helper Methods ---

  final Map<String, latlng.LatLng> _cityCoordinates = {
    "Colombo": const latlng.LatLng(6.9271, 79.8612),
    "Kandy": const latlng.LatLng(7.2906, 80.6337),
    "Galle": const latlng.LatLng(6.0535, 80.2210),
    "Jaffna": const latlng.LatLng(9.6615, 80.0255),
    "Matara": const latlng.LatLng(5.9549, 80.5550),
    "Ella": const latlng.LatLng(6.8667, 81.0466),
    "Trincomalee": const latlng.LatLng(8.5874, 81.2152),
    "Anuradhapura": const latlng.LatLng(8.3114, 80.4037),
  };

  List<Marker> _createMarkers(TripController controller) {
    final List<Marker> markers = [];
    if (controller.fromCity != null &&
        _cityCoordinates.containsKey(controller.fromCity)) {
      markers.add(Marker(
        point: _cityCoordinates[controller.fromCity]!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
      ));
    }
    if (controller.toCity != null &&
        _cityCoordinates.containsKey(controller.toCity)) {
      markers.add(Marker(
        point: _cityCoordinates[controller.toCity]!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }
    return markers;
  }

  List<Polyline> _createPolylines(TripController controller) {
    if (controller.fromCity != null &&
        controller.toCity != null &&
        _cityCoordinates.containsKey(controller.fromCity) &&
        _cityCoordinates.containsKey(controller.toCity)) {
      return [
        Polyline(
          points: [
            _cityCoordinates[controller.fromCity]!,
            _cityCoordinates[controller.toCity]!,
          ],
          color: AppTheme.primaryColor,
          strokeWidth: 4.0,
          pattern: StrokePattern.dashed(segments: const [10.0, 10.0]),
        )
      ];
    }
    return [];
  }

  Widget _buildResultsHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$count Buses found",
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              if (Provider.of<TripController>(context).isBulkBooking)
                Text(
                  "Showing valid options for ${Provider.of<TripController>(context).bulkDates.length} Consecutive Days",
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor),
                ),
            ],
          ),
          const Spacer(),
          // Sort Dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 14, color: Colors.black),
              icon: const Icon(Icons.sort_rounded, size: 20),
              items: const [
                DropdownMenuItem(
                    value: 'price_asc', child: Text("Cheapest First")),
                DropdownMenuItem(
                    value: 'time_asc', child: Text("Earliest First")),
              ],
              onChanged: (v) => setState(() => _sortBy = v!),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("FILTERS",
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2)),
          const Divider(height: 32),
          _filterSection("Departure Time",
              ["Before 6 am", "6 am to 12 pm", "12 pm to 6 pm", "After 6 pm"]),
        ],
      ),
    );
  }

  Widget _filterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        const SizedBox(height: 12),
        ...options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _selectedFilters.contains(opt),
                      onChanged: (val) {
                        setState(() {
                          if (val!) {
                            _selectedFilters.add(opt);
                          } else {
                            _selectedFilters.remove(opt);
                          }
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(opt,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.grey.shade700,
                          fontSize: 13))
                ],
              ),
            ))
      ],
    );
  }

  void _showMobileFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildFilters(context)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.directions_bus_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No buses found",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.toLowerCase().contains("clear") || condition == "Sunny") {
      return Icons.wb_sunny;
    }
    if (condition.toLowerCase().contains("cloud")) {
      return Icons.cloud;
    }
    if (condition.toLowerCase().contains("rain")) {
      return Icons.grain;
    }
    if (condition.toLowerCase().contains("drizzle")) {
      return Icons.grain;
    }
    if (condition.toLowerCase().contains("snow")) {
      return Icons.ac_unit;
    }
    if (condition.toLowerCase().contains("thunder")) {
      return Icons.flash_on;
    }
    return Icons.wb_cloudy;
  }

  Color _getWeatherColor(String condition) {
    if (condition.toLowerCase().contains("clear") || condition == "Sunny") {
      return Colors.orange;
    }
    if (condition.toLowerCase().contains("cloud")) {
      return Colors.blueGrey;
    }
    if (condition.toLowerCase().contains("rain")) {
      return Colors.blue;
    }
    return Colors.grey.shade600;
  }
}

class _BusTicketCard extends StatefulWidget {
  final Trip trip;
  const _BusTicketCard({required this.trip});

  @override
  State<_BusTicketCard> createState() => _BusTicketCardState();
}

class _BusTicketCardState extends State<_BusTicketCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final controller =
        Provider.of<TripController>(context); // Listen to changes esp bulk
    final trip = widget.trip;
    final duration = trip.arrivalTime.difference(trip.departureTime);
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Bulk Logic
    final totalPrice = controller.isBulkBooking
        ? trip.price * controller.bulkDates.length
        : trip.price;

    final priceLabel = controller.isBulkBooking
        ? "LKR ${totalPrice.toStringAsFixed(0)} (x${controller.bulkDates.length} Days)"
        : "LKR ${trip.price.toStringAsFixed(0)}";

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isHovered
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isHovered ? 0.08 : 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: isMobile
            ? Column(
                children: [
                  _buildMobileContent(trip, duration),
                  _buildBookButton(
                      trip, context, controller, isMobile, priceLabel),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildDesktopContent(trip, duration)),
                    _buildBookButton(
                        trip, context, controller, isMobile, priceLabel),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopContent(Trip trip, Duration duration) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(trip),
          const SizedBox(height: 20),
          _buildTimeline(trip, duration),
          const SizedBox(height: 16),
          _buildAmenities(trip),
        ],
      ),
    );
  }

  Widget _buildMobileContent(Trip trip, Duration duration) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(trip),
          const SizedBox(height: 16),
          _buildTimeline(trip, duration),
          const SizedBox(height: 16),
          _buildAmenities(trip),
        ],
      ),
    );
  }

  Widget _buildCardHeader(Trip trip) {
    return Row(
      children: [
        if (trip.delayMinutes > 0) ...{
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4)),
            child: Text("+${trip.delayMinutes} min",
                style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
          ),
          const SizedBox(width: 8),
        },
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4)),
          child: Text("High Rated",
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(trip.operatorName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildTimeline(Trip trip, Duration duration) {
    return Row(
      children: [
        Column(
          children: [
            Text(DateFormat('HH:mm').format(trip.departureTime),
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            Text(trip.fromCity,
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                    "${duration.inHours}h ${duration.inMinutes.remainder(60)}m",
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.grey),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Icon(Icons.circle, size: 8, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
        Column(
          children: [
            Text(DateFormat('HH:mm').format(trip.arrivalTime),
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            Text(trip.toCity,
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenities(Trip trip) {
    return Row(
      children: [
        _amenityIcon(Icons.wifi, "Wifi"),
        _amenityIcon(Icons.power, "Outlet"),
      ],
    );
  }

  Widget _buildBookButton(Trip trip, BuildContext context,
      TripController controller, bool isMobile, String priceLabel) {
    return Container(
      width: isMobile ? double.infinity : 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: isMobile
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : const BorderRadius.horizontal(right: Radius.circular(12)),
        border: isMobile
            ? Border(top: BorderSide(color: Colors.grey.shade100))
            : Border(left: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.end,
        children: [
          Text("Standard",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          Text(priceLabel,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor)),
          const SizedBox(height: 4),
          Text("per person",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final diff = trip.departureTime.difference(now).inMinutes;

                if (diff <= 10) {
                  // Block booking
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        "Online booking closes 10 minutes before departure. Please contact the conductor."),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                  ));
                } else {
                  controller.selectTrip(trip);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SeatSelectionScreen(trip: trip)));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: const Text("Select"),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
                "${trip.totalSeats - trip.bookedSeats.length} seats left",
                style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
          )
        ],
      ),
    );
  }

  Widget _amenityIcon(IconData icon, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, size: 16, color: Colors.grey.shade400),
      ),
    );
  }
}

class RouteFavoriteButton extends StatefulWidget {
  const RouteFavoriteButton({super.key});

  @override
  State<RouteFavoriteButton> createState() => _RouteFavoriteButtonState();
}

class _RouteFavoriteButtonState extends State<RouteFavoriteButton> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final controller = Provider.of<TripController>(context, listen: false);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null &&
        controller.fromCity != null &&
        controller.toCity != null) {
      final isFav = await controller.isRouteFavorite(
          user.uid, controller.fromCity!, controller.toCity!);
      if (mounted) setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggle() async {
    final controller = Provider.of<TripController>(context, listen: false);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to save favorites")));
      return;
    }

    if (controller.fromCity == null || controller.toCity == null) return;

    setState(() => _isLoading = true);

    // Calculate best price
    double? minPrice;
    if (controller.searchResults.isNotEmpty) {
      minPrice = controller.searchResults
          .map((t) => t.price)
          .reduce((a, b) => a < b ? a : b);
    }

    await controller.toggleRouteFavorite(
        user.uid, controller.fromCity!, controller.toCity!,
        operatorName: "Various Operators", price: minPrice);

    // Toggle state immediately for UI (optimistic) or wait?
    // We can just flip it:
    setState(() {
      _isFavorite = !_isFavorite;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isFavorite
              ? "Route saved to favorites"
              : "Route removed from favorites"),
          duration: const Duration(seconds: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading ? null : _toggle,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey,
            ),
      tooltip: "Save Route",
    );
  }
}
