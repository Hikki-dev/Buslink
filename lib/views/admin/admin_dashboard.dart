import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../utils/app_theme.dart';
import '../../utils/language_provider.dart';

import '../customer_main_screen.dart';
import 'admin_screen.dart';
import 'layout/admin_bottom_nav.dart';
import 'layout/admin_footer.dart';
import 'layout/admin_navbar.dart';
import 'admin_route_screen.dart';
import 'route_management_screen.dart';
import 'package:buslink/views/booking/bus_layout_widget.dart';
import 'refunds/admin_refund_list.dart';
import 'bookings/admin_booking_list.dart';

import 'analytics/admin_analytics_dashboard.dart';
import 'admin_feedback_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripController>(context, listen: false)
          .fetchAvailableCities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar:
          isDesktop ? null : const AdminBottomNav(selectedIndex: 0),
      body: Column(
        children: [
          // Desktop Nav (Hidden on Mobile inside widget)
          if (isDesktop) const AdminNavBar(selectedIndex: 0),

          // Mobile Header
          if (!isDesktop) const AdminNavBar(selectedIndex: 0),

          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Title Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isDesktop)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          languageProvider
                                              .translate('route_management'),
                                          style: GoogleFonts.outfit(
                                              fontSize: 34,
                                              height: 1.1,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryColor)),
                                      const SizedBox(height: 8),
                                      Text(
                                          languageProvider.translate(
                                              'route_management_desc'),
                                          style: GoogleFonts.inter(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                              fontSize: 16)),
                                      const SizedBox(height: 24),
                                      Center(
                                        child: Wrap(
                                          spacing: 16,
                                          runSpacing: 16,
                                          children: [
                                            _buildAddRouteButton(context),
                                            _buildAddRouteSimpleButton(context),
                                            _buildManageRoutesButton(context),
                                            _buildRefundButton(context),
                                            _buildBookingsButton(context),
                                            _buildAnalyticsButton(context),
                                            _buildFeedbackButton(context),
                                            Consumer<ThemeController>(
                                              builder: (context,
                                                  themeController, _) {
                                                final isDark = Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark;
                                                return IconButton(
                                                  onPressed: () {
                                                    themeController.setTheme(
                                                        isDark
                                                            ? ThemeMode.light
                                                            : ThemeMode.dark);
                                                  },
                                                  icon: Icon(
                                                      isDark
                                                          ? Icons.light_mode
                                                          : Icons.dark_mode,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87),
                                                  tooltip: "Toggle Theme",
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                                languageProvider.translate(
                                                    'route_management'),
                                                style: GoogleFonts.outfit(
                                                    fontSize: 34,
                                                    height: 1.1,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        AppTheme.primaryColor)),
                                          ),
                                          Consumer<ThemeController>(
                                            builder:
                                                (context, themeController, _) {
                                              final isDark = Theme.of(context)
                                                      .brightness ==
                                                  Brightness.dark;
                                              return IconButton(
                                                onPressed: () {
                                                  themeController.setTheme(
                                                      isDark
                                                          ? ThemeMode.light
                                                          : ThemeMode.dark);
                                                },
                                                icon: Icon(
                                                    isDark
                                                        ? Icons.light_mode
                                                        : Icons.dark_mode,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87),
                                                tooltip: "Toggle Theme",
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                          languageProvider.translate(
                                              'route_management_desc'),
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                              fontSize: 16)),
                                    ],
                                  ),

                                // Mobile Actions (Grid Layout)
                                if (!isDesktop) ...[
                                  const SizedBox(height: 32),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          _buildMobileActionCard(
                                              context,
                                              Icons.add_circle_outline,
                                              languageProvider
                                                  .translate('add_new_trip'),
                                              () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const AdminScreen(
                                                              trip: null))),
                                              isPrimary: true),
                                          const SizedBox(width: 16),
                                          _buildMobileActionCard(
                                              context,
                                              Icons.alt_route,
                                              languageProvider
                                                  .translate('add_route'),
                                              () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const AdminRouteScreen())),
                                              isPrimary: true),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          _buildMobileActionCard(
                                              context,
                                              Icons.map_outlined,
                                              languageProvider
                                                  .translate('manage_routes'),
                                              () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const RouteManagementScreen()))),
                                          const SizedBox(width: 16),
                                          _buildMobileActionCard(
                                              context,
                                              Icons
                                                  .confirmation_number_outlined,
                                              languageProvider
                                                  .translate('bookings'),
                                              () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const AdminBookingListScreen()))),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          _buildMobileActionCard(
                                              context,
                                              Icons.monetization_on_outlined,
                                              languageProvider
                                                  .translate('refunds'),
                                              () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const AdminRefundListScreen()))),
                                          const SizedBox(width: 16),
                                          _buildMobileActionCard(
                                              context,
                                              Icons.analytics_outlined,
                                              languageProvider
                                                  .translate('analytics'),
                                              () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const AdminAnalyticsDashboard()))),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          _buildMobileActionCard(
                                              context,
                                              Icons.feedback_outlined,
                                              languageProvider
                                                  .translate('app_feedback'),
                                              () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const AdminFeedbackScreen()))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Search Section
                      _buildSearchSection(context, controller, isDesktop),

                      const SizedBox(height: 32),

                      // Results Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Consumer<TripController>(
                            builder: (context, ctl, _) {
                              if (ctl.isLoading) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (ctl.searchResults.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color:
                                            Colors.grey.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.search_off,
                                          size: 64,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                          languageProvider
                                              .translate('no_routes_found'),
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16,
                                              color: Colors.grey
                                                  .withValues(alpha: 0.2))),
                                      const SizedBox(height: 8),
                                      Text(
                                          languageProvider
                                              .translate('adjust_filters'),
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              color: Colors.grey)),
                                      const SizedBox(height: 24),
                                      // Preview Action
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CustomerMainScreen(
                                                      isAdminView: true),
                                            ),
                                          ).then((_) {
                                            // Reset when coming back (Delayed to prevent black screen)
                                            if (context.mounted) {
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 300), () {
                                                if (context.mounted) {
                                                  Provider.of<TripController>(
                                                          context,
                                                          listen: false)
                                                      .setPreviewMode(false);
                                                }
                                              });
                                            }
                                          });
                                        },
                                        icon: const Icon(Icons.preview),
                                        label: Text(languageProvider
                                            .translate('preview_app')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: ctl.searchResults.length,
                                itemBuilder: (context, index) {
                                  return _buildResultRow(
                                      context, ctl.searchResults[index], ctl);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AdminFooter(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRouteButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminScreen(trip: null)));
      },
      icon: const Icon(Icons.add),
      label: Text(
          Provider.of<LanguageProvider>(context).translate('add_new_trip')),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildManageRoutesButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RouteManagementScreen()));
      },
      icon: const Icon(Icons.alt_route),
      label: Text(
          Provider.of<LanguageProvider>(context).translate('manage_routes')),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRefundButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminRefundListScreen()));
      },
      icon: const Icon(Icons.monetization_on_outlined),
      label: Text(Provider.of<LanguageProvider>(context).translate('refunds')),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFeedbackButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()));
      },
      icon: const Icon(Icons.feedback_outlined),
      label: Text(
          Provider.of<LanguageProvider>(context).translate('app_feedback')),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBookingsButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminBookingListScreen()));
      },
      icon: const Icon(Icons.confirmation_number_outlined),
      label: Text(Provider.of<LanguageProvider>(context).translate('bookings')),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAnalyticsButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminAnalyticsDashboard()));
      },
      icon: const Icon(Icons.analytics_outlined),
      label:
          Text(Provider.of<LanguageProvider>(context).translate('analytics')),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddRouteSimpleButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminRouteScreen()));
      },
      icon: const Icon(Icons.alt_route),
      label:
          Text(Provider.of<LanguageProvider>(context).translate('add_route')),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchSection(
      BuildContext context, TripController controller, bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  Provider.of<LanguageProvider>(context)
                      .translate('find_routes'),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1)),
              const SizedBox(height: 20),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                        child: _buildSearchInput(context, controller, true)),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 56, // Increased from 50
                      child: ElevatedButton(
                        onPressed: () => controller.searchTrips(
                            controller.fromCity ?? '',
                            controller.toCity ?? '',
                            controller.tripDate ?? DateTime.now()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 32),
                        ),
                        child: Text(
                            Provider.of<LanguageProvider>(context)
                                .translate('search_action'),
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildSearchInput(context, controller, false),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Increased from 50
                      child: ElevatedButton(
                        onPressed: () => controller.searchTrips(
                            controller.fromCity ?? '',
                            controller.toCity ?? '',
                            controller.tripDate ?? DateTime.now()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                            Provider.of<LanguageProvider>(context)
                                .translate('search_action'),
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput(
      BuildContext context, TripController controller, bool isDesktop) {
    // Autocomplete fields
    final originField = _buildAutocomplete(
        Provider.of<LanguageProvider>(context).translate('from'),
        controller.fromCity,
        (v) => controller.setFromCity(v));

    final destField = _buildAutocomplete(
        Provider.of<LanguageProvider>(context).translate('to'),
        controller.toCity,
        (v) => controller.setToCity(v));

    final dateField = InkWell(
      onTap: () async {
        final now = DateTime.now();
        // Ensure initialDate is not before firstDate (now)
        final DateTime initialDate = (controller.travelDate != null &&
                controller.travelDate!.isBefore(now))
            ? now
            : (controller.travelDate ?? now);

        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) controller.setDate(picked);
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 12),
            Text(
              controller.travelDate != null
                  ? DateFormat('yyyy-MM-dd').format(controller.travelDate!)
                  : Provider.of<LanguageProvider>(context)
                      .translate('select_date'),
              style: TextStyle(
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onSurface),
            )
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 2, child: originField),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: destField),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: dateField),
        ],
      );
    } else {
      return Column(
        children: [
          originField,
          const SizedBox(height: 12),
          destField,
          const SizedBox(height: 12),
          dateField,
        ],
      );
    }
  }

  Widget _buildAutocomplete(
      String label, String? initialValue, Function(String) onSelected) {
    return LayoutBuilder(builder: (context, constraints) {
      return Autocomplete<String>(
        initialValue: TextEditingValue(text: initialValue ?? ''),
        optionsBuilder: (TextEditingValue textEditingValue) {
          final cities = Provider.of<TripController>(context, listen: false)
              .availableCities;
          if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
          }
          return cities.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: onSelected,
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          // Sync controller if external value changes (simplified)
          if (initialValue != null &&
              textEditingController.text != initialValue &&
              textEditingController.text.isEmpty) {
            // textEditingController.text = initialValue;
          }

          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
            },
            onChanged: (val) {
              onSelected(val);
            },
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.search, size: 20),
            ),
            validator: (v) => v == null || v.isEmpty
                ? Provider.of<LanguageProvider>(context).translate('required')
                : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: SizedBox(
                width: constraints.maxWidth,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(option),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildResultRow(
      BuildContext context, EnrichedTrip trip, TripController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Bus Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.directions_bus, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 20),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${trip.fromCity} ➝ ${trip.toCity}",
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Departs: ${DateFormat('HH:mm').format(trip.departureTime)} • Arrives: ${DateFormat('HH:mm').format(trip.arrivalTime)}",
                  style: TextStyle(
                      fontFamily: 'Inter', color: Colors.grey.shade600),
                ),
                if (trip.via.isNotEmpty)
                  Text(
                    "Via: ${trip.via}",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.grey.shade500,
                        fontSize: 12),
                  ),
              ],
            ),
          ),

          // Actions
          if (MediaQuery.of(context).size.width > 600) ...[
            OutlinedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AdminScreen(trip: trip)));
                },
                child: const Text("Edit")),
            const SizedBox(width: 12),
            OutlinedButton(
                onPressed: () => _showSeatLayout(context, trip.trip),
                child: const Text("View Seats")),
            const SizedBox(width: 12),
            IconButton(
                onPressed: () => _confirmDelete(context, controller, trip.id),
                icon: const Icon(Icons.delete_outline, color: Colors.red))
          ] else ...[
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit Route")),
                const PopupMenuItem(value: 'seats', child: Text("View Seats")),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text("Delete Bus",
                        style: TextStyle(color: Colors.red))),
              ],
              onSelected: (val) {
                if (val == 'edit') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AdminScreen(trip: trip)));
                } else if (val == 'seats') {
                  _showSeatLayout(context, trip.trip);
                } else {
                  _confirmDelete(context, controller, trip.id);
                }
              },
            )
          ]
        ],
      ),
    );
  }

  void _showSeatLayout(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Seat Layout: Bus ${trip.busNumber}",
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: BusLayoutWidget(
                    trip: trip,
                    isReadOnly: true,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Close")),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, TripController controller, String tripId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Bus?"),
        content: const Text(
            "Are you sure you want to delete this route? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                controller.deleteTrip(tripId);
              },
              child: const Text("Delete")),
        ],
      ),
    );
  }

  Widget _buildMobileActionCard(
      BuildContext context, IconData icon, String label, VoidCallback onTap,
      {bool isPrimary = false}) {
    return Expanded(
      child: Material(
        color: isPrimary ? AppTheme.primaryColor : Theme.of(context).cardColor,
        borderRadius: null, // Explicitly null to fix assertion
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 28,
                    color: isPrimary ? Colors.white : AppTheme.primaryColor),
                const SizedBox(height: 12),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isPrimary ? Colors.white : Colors.black87),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
