import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for Google Maps link
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../models/trip_view_model.dart'; // Import EnrichedTrip
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../booking/seat_selection_screen.dart';
import '../../utils/app_theme.dart';
import '../layout/desktop_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../layout/app_footer.dart';
// import '../../services/auth_service.dart'; // Unused
import '../../services/firestore_service.dart';
import '../booking/bulk_confirmation_screen.dart';
import '../booking/bulk_quantity_dialog.dart';
import '../../utils/language_provider.dart';

part 'parts/clock_widget.dart';

class BusListScreen extends StatefulWidget {
  const BusListScreen({super.key});

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  String _sortBy = 'price_asc';
  final List<String> _selectedFilters = [];

  // Weather & Time State
  final MapController _mapController = MapController();
  String _weatherCondition = "Sunny";
  int _temperature = 29;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final isDesktop = MediaQuery.of(context).size.width > 1000;

    List<EnrichedTrip> trips = List.from(controller.searchResults);

    // Filter Logic
    if (_selectedFilters.isNotEmpty) {
      trips = trips.where((trip) {
        final timeOptions = [
          "before_6_am",
          "6_am_to_12_pm",
          "12_pm_to_6_pm",
          "after_6_pm"
        ];

        final selectedTimes =
            _selectedFilters.where((f) => timeOptions.contains(f)).toList();

        if (selectedTimes.isNotEmpty) {
          bool timeMatch = false;
          final hour = trip.departureTime.hour;
          for (final filter in selectedTimes) {
            if (filter == "before_6_am" && hour < 6) {
              timeMatch = true;
            }
            if (filter == "6_am_to_12_pm" && hour >= 6 && hour < 12) {
              timeMatch = true;
            }
            if (filter == "12_pm_to_6_pm" && hour >= 12 && hour < 18) {
              timeMatch = true;
            }
            if (filter == "after_6_pm" && hour >= 18) {
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

    // Get translations
    // final lp = Provider.of<LanguageProvider>(context); // Already provided? No, context is sufficient later.
    // Actually we need to pass lp down or use Consumer.
    // Since this is build method, we can access provider.

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isDesktop
          ? _buildDesktopLayout(context, isDesktop, trips, controller)
          : _buildMobileLayout(context, trips, controller),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDesktop,
      List<EnrichedTrip> trips, TripController controller) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: DesktopNavBar()),
        if (controller.isPreviewMode)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Text("Welcome Admin - Preview Mode",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
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
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                            color: AppTheme.primaryColor),
                                        SizedBox(height: 16),
                                        Text("Finding best routes...",
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                color: Colors.grey))
                                      ],
                                    )))
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

  Widget _buildMobileLayout(BuildContext context, List<EnrichedTrip> trips,
      TripController controller) {
    final lp = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${lp.translate(controller.fromCity?.toLowerCase().replaceAll(' ', '_') ?? "")} ➔ ${lp.translate(controller.toCity?.toLowerCase().replaceAll(' ', '_') ?? "")}',
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: const [],
        // Using info header in mobile too, maybe simplified?
      ),
      bottomSheet: controller.isPreviewMode
          ? Container(
              width: double.infinity,
              color: Colors.amber,
              padding: const EdgeInsets.all(8),
              child: const Text("Admin Preview Mode",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMobileFilterModal(context),
        label: Text(lp.translate('filters')),
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
    final weatherCityKey = weatherCity.toLowerCase().replaceAll(' ', '_');
    final lp = Provider.of<LanguageProvider>(context);

    // ... (Weather UI same but translation for headers?)
    // No specific headers yet mostly dynamic data.

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
                            Text(lp.translate(weatherCityKey),
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
                        const _ClockWidget(fontSize: 24),
                        Text(
                            DateFormat('EEEE, d MMMM yyyy').format(DateTime
                                .now()), // Date doesn't change every second, safe enough or can move inside
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
                                    fontSize: 18,
                                    color: Colors.black)),
                            Text(lp.translate(weatherCityKey),
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
                          // Time
                          children: [
                            // const SizedBox(width: 8),
                            // const SizedBox(width: 8),
                            const _ClockWidget(fontSize: 24),
                          ],
                        ),
                        Text(
                            DateFormat('EEEE, d MMMM yyyy')
                                .format(DateTime.now()),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Map Layer
                        RepaintBoundary(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: controller.fromCity != null &&
                                      _cityCoordinates
                                          .containsKey(controller.fromCity)
                                  ? _cityCoordinates[controller.fromCity]!
                                  : const latlng.LatLng(
                                      7.8731, 80.7718), // Center of SL
                              initialZoom: 7.5,
                              interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.all &
                                      ~InteractiveFlag.rotate),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.buslink',
                              ),
                              PolylineLayer(
                                polylines: _createPolylines(controller),
                              ),
                              MarkerLayer(
                                markers: _createMarkers(controller),
                              ),
                            ],
                          ),
                        ),
                        // Overlays
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.map,
                                        size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(lp.translate('live_route_preview'),
                                        style: const TextStyle(
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
                            label: Text(lp.translate('open_google_maps')),
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
    "Negombo": const latlng.LatLng(7.2008, 79.8737),
    "Hambantota": const latlng.LatLng(6.1429, 81.1212),
    "Badulla": const latlng.LatLng(6.9897, 81.0558),
    "Ratnapura": const latlng.LatLng(6.6939, 80.3982),
    "Sigiriya": const latlng.LatLng(7.9570, 80.7603),
    "Mirissa": const latlng.LatLng(5.9482, 80.4716),
  };

  List<Marker> _createMarkers(TripController controller) {
    // Collect unique cities involved in the search results to mark key points
    final Set<String> markedCities = {};
    if (controller.fromCity != null) markedCities.add(controller.fromCity!);
    if (controller.toCity != null) markedCities.add(controller.toCity!);

    // Add intermediate cities from search results
    for (var trip in controller.searchResults) {
      if (trip.via.isNotEmpty) {
        // Simple substring matching for known cities in 'via'
        for (var city in _cityCoordinates.keys) {
          if (trip.via.contains(city)) markedCities.add(city);
        }
      }
    }

    final List<Marker> markers = [];
    for (var city in markedCities) {
      if (_cityCoordinates.containsKey(city)) {
        bool isSource = city == controller.fromCity;
        bool isDest = city == controller.toCity;
        Color color =
            isSource ? Colors.blue : (isDest ? Colors.red : Colors.orange);

        markers.add(Marker(
          point: _cityCoordinates[city]!,
          width: 40,
          height: 40,
          child: Icon(Icons.location_on, color: color, size: 40),
        ));
      }
    }
    return markers;
  }

  List<Polyline> _createPolylines(TripController controller) {
    if (controller.searchResults.isEmpty) {
      // Fallback to simple line if no results but query exists
      if (controller.fromCity != null &&
          controller.toCity != null &&
          _cityCoordinates.containsKey(controller.fromCity) &&
          _cityCoordinates.containsKey(controller.toCity)) {
        return [
          Polyline(
              points: [
                _cityCoordinates[controller.fromCity]!,
                _cityCoordinates[controller.toCity]!
              ],
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              strokeWidth: 3.0,
              pattern: StrokePattern.dashed(segments: const [5.0, 5.0]))
        ];
      }
      return [];
    }

    List<Polyline> lines = [];
    int index = 0;

    for (var trip in controller.searchResults) {
      List<latlng.LatLng> points = [];
      // Start
      if (_cityCoordinates.containsKey(trip.fromCity)) {
        points.add(_cityCoordinates[trip.fromCity]!);
      }

      // Via logic: try to find intermediate city in 'via' string
      for (var city in _cityCoordinates.keys) {
        if (trip.via.contains(city) &&
            city != trip.fromCity &&
            city != trip.toCity) {
          points.add(_cityCoordinates[city]!);
        }
      }

      // End
      if (_cityCoordinates.containsKey(trip.toCity)) {
        points.add(_cityCoordinates[trip.toCity]!);
      }

      if (points.length >= 2) {
        lines.add(Polyline(
          points: points,
          color: index == 0
              ? AppTheme.primaryColor
              : Colors.indigoAccent, // Highlight first result primarily?
          strokeWidth: 4.0,
        ));
      }
      index++;
    }
    return lines;
  }

  Widget _buildResultsHeader(int count) {
    final lp = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white12
                : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$count ${lp.translate('buses_found_suffix')}",
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
              if (Provider.of<TripController>(context).isBulkBooking)
                Text(
                  "${lp.translate('showing_valid_options')} ${Provider.of<TripController>(context).bulkDates.length} ${lp.translate('consecutive_days')}",
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
              items: [
                DropdownMenuItem(
                    value: 'price_asc',
                    child: Text(lp.translate('cheapest_first'))),
                DropdownMenuItem(
                    value: 'time_asc',
                    child: Text(lp.translate('earliest_first'))),
              ],
              onChanged: (v) => setState(() => _sortBy = v!),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white12
                  : Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lp.translate('filters'),
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2)),
          const Divider(height: 32),
          _filterSection(lp.translate('departure_time_filter'),
              ["before_6_am", "6_am_to_12_pm", "12_pm_to_6_pm", "after_6_pm"]),
        ],
      ),
    );
  }

  Widget _filterSection(String title, List<String> options) {
    final lp = Provider.of<LanguageProvider>(context);
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
                    child: Transform.scale(
                      scale: 1.3,
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
                  ),
                  const SizedBox(width: 8),
                  Text(lp.translate(opt),
                      style: TextStyle(
                          fontFamily: 'Inter',
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15)) // Increased font size
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
    final lp = Provider.of<LanguageProvider>(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.directions_bus_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(lp.translate('no_buses_found'),
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
  final EnrichedTrip trip;
  const _BusTicketCard({required this.trip});

  @override
  State<_BusTicketCard> createState() => _BusTicketCardState();
}

class _BusTicketCardState extends State<_BusTicketCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);

    // Use StreamBuilder to ensure real-time updates for seat availability
    return StreamBuilder<Trip>(
        stream: Provider.of<FirestoreService>(context, listen: false)
            .getTripStream(widget.trip.id),
        builder: (context, snapshot) {
          // If stream has data (Trip), merge it. Else use widget.trip.
          EnrichedTrip trip = widget.trip;
          if (snapshot.hasData) {
            trip = EnrichedTrip(
                trip: snapshot.data!,
                schedule: widget.trip.schedule,
                route: widget.trip.route);
          }
          final duration = trip.arrivalTime.difference(trip.departureTime);
          final isMobile = MediaQuery.of(context).size.width < 700;

          // Bulk Logic
          final totalPrice = controller.isBulkBooking
              ? trip.price * controller.bulkDates.length
              : trip.price;

          final priceLabel = controller.isBulkBooking
              ? "LKR ${totalPrice.toStringAsFixed(0)} (x${controller.bulkDates.length} Days)"
              : "LKR ${trip.price.toStringAsFixed(0)}";

          return RepaintBoundary(
            child: MouseRegion(
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isHovered
                          ? AppTheme.primaryColor.withValues(alpha: 0.5)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white12
                              : Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isHovered ? 0.08 : 0.02),
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
                            Expanded(
                                child: _buildDesktopContent(trip, duration)),
                            _buildBookButton(trip, context, controller,
                                isMobile, priceLabel),
                          ],
                        ),
                      ),
              ),
            ),
          );
        });
  }

  Widget _buildDesktopContent(EnrichedTrip trip, Duration duration) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(trip),
          const SizedBox(height: 12),
          _buildTimeline(trip, duration),
          const SizedBox(height: 16),
          _buildAmenities(trip),
        ],
      ),
    );
  }

  Widget _buildMobileContent(EnrichedTrip trip, Duration duration) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(trip),
          const SizedBox(height: 12),
          _buildTimeline(trip, duration),
          const SizedBox(height: 16),
          _buildAmenities(trip),
        ],
      ),
    );
  }

  Widget _buildCardHeader(EnrichedTrip trip) {
    final lp = Provider.of<LanguageProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Operator Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(lp.translate('high_rated'),
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ),
            const SizedBox(height: 8),
            Text(
                trip.operatorName.isEmpty
                    ? "BusLink Operator"
                    : trip.operatorName,
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            // Only Show Via
            if (trip.via.isNotEmpty)
              _detailChip(Icons.route, "${lp.translate('via')} ${trip.via}"),
          ],
        ),
      ],
    );
  }

  // Details Removed as requested

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white12
                : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.grey.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTimeline(EnrichedTrip trip, Duration duration) {
    final lp = Provider.of<LanguageProvider>(context);
    return Row(
      children: [
        Column(
          children: [
            Text(DateFormat('HH:mm').format(trip.departureTime),
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            Text(lp.translate(trip.fromCity.toLowerCase().replaceAll(' ', '_')),
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
                    "${duration.inHours}${lp.translate('hrs')} ${duration.inMinutes.remainder(60)}${lp.translate('mins')}",
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
            Text(lp.translate(trip.toCity.toLowerCase().replaceAll(' ', '_')),
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenities(EnrichedTrip trip) {
    return const SizedBox.shrink(); // Amenities hidden as per request
  }

  Widget _buildBookButton(EnrichedTrip trip, BuildContext context,
      TripController controller, bool isMobile, String priceLabel) {
    final lp = Provider.of<LanguageProvider>(context);

    // Filter Logic to translate "Days" if bulk
    String displayPrice = priceLabel;
    if (controller.isBulkBooking) {
      displayPrice = priceLabel.replaceAll('Days', lp.translate('days'));
    }

    return Container(
      width: isMobile ? double.infinity : 180,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: isMobile
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : const BorderRadius.horizontal(right: Radius.circular(12)),
        border: isMobile
            ? Border(
                top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.withValues(alpha: 0.2)
                        : Colors.grey.shade100))
            : Border(
                left: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.withValues(alpha: 0.2)
                        : Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.end,
        children: [
          // Text("Standard", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          Text(displayPrice,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor)),
          const SizedBox(height: 4),
          Text(lp.translate('per_person'),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(lp.translate('booking_closes_error')),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ));
                } else if (controller.isBulkBooking) {
                  // Show Quantity Selection Dialog
                  showDialog(
                    context: context,
                    builder: (context) => BulkQuantityDialog(
                      trip: trip.trip,
                      days: controller.bulkDates.length,
                      onConfirm: (qty) {
                        Navigator.pop(context); // Close dialog

                        // Proceed to Confirmation
                        controller.selectedSeats =
                            List.generate(qty, (index) => "-1");
                        controller.selectedTrip = trip;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BulkConfirmationScreen(trip: trip),
                          ),
                        );
                      },
                    ),
                  );
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
              child: Text(lp.translate('select')),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
                "${trip.totalSeats - trip.bookedSeats.length} ${lp.translate('seats_left_suffix')}",
                style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
          )
        ],
      ),
    );
  }
}
