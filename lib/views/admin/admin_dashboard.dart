import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_model.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

import '../customer_main_screen.dart';
import 'admin_screen.dart';
import 'layout/admin_bottom_nav.dart';
import 'layout/admin_footer.dart';
import 'layout/admin_navbar.dart';
import 'admin_route_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TripController>(context);
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
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ShaderMask(
                                            shaderCallback: (bounds) =>
                                                const LinearGradient(
                                              colors: [
                                                AppTheme.primaryColor,
                                                Color(0xFFFF8A65)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ).createShader(bounds),
                                            child: const FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text("Route Management",
                                                  style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 34,
                                                      height: 1.1,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                              "Manage bus schedules, fares, and availability.",
                                              style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                                  fontSize: 16)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isDesktop) ...[
                                const Spacer(),
                                _buildAddRouteButton(context),
                                const SizedBox(width: 16),
                                _buildAddRouteSimpleButton(context),
                                const SizedBox(width: 16),
                                // Theme Toggle
                                Consumer<ThemeController>(
                                  builder: (context, themeController, _) {
                                    final isDark =
                                        Theme.of(context).brightness ==
                                            Brightness.dark;
                                    return IconButton(
                                      onPressed: () {
                                        themeController.setTheme(isDark
                                            ? ThemeMode.light
                                            : ThemeMode.dark);
                                      },
                                      icon: Icon(
                                          isDark
                                              ? Icons.light_mode // Sun in Dark
                                              : Icons
                                                  .dark_mode, // Moon in Light
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87),
                                      tooltip: "Toggle Theme",
                                    );
                                  },
                                )
                              ]
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Mobile Add Button
                      if (!isDesktop) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(child: _buildAddRouteButton(context)),
                            const SizedBox(width: 16),
                            Flexible(
                                child: _buildAddRouteSimpleButton(context)),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Search Section
                      _buildSearchSection(context, controller, isDesktop),

                      const SizedBox(height: 32),

                      // Results Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
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
                                      Text("No routes found",
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16,
                                              color: Colors.grey
                                                  .withValues(alpha: 0.2))),
                                      const SizedBox(height: 8),
                                      Text("Try adjusting your filters.",
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
                                        label: const Text("Preview App"),
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
      label: const Text("Add New Trip"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle:
            const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
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
      label: const Text("Add Route"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle:
            const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchSection(
      BuildContext context, TripController controller, bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
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
              const Text("FIND ROUTES",
                  style: TextStyle(
                      fontFamily: 'Inter',
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
                        onPressed: () => controller.searchTrips(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 32),
                        ),
                        child: const Text("Search",
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
                        onPressed: () => controller.searchTrips(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("Search",
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
        "Origin", controller.fromCity, (v) => controller.setFromCity(v));

    final destField = _buildAutocomplete(
        "Destination", controller.toCity, (v) => controller.setToCity(v));

    final dateField = InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: controller.travelDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
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
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              controller.travelDate != null
                  ? DateFormat('yyyy-MM-dd').format(controller.travelDate!)
                  : "Select Date",
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
          if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
          }
          return AppConstants.cities.where((String option) {
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
              suffixIcon:
                  const Icon(Icons.search, size: 20, color: Colors.grey),
            ),
            validator: (v) => v == null || v.isEmpty ? "Required" : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
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
      BuildContext context, Trip trip, TripController controller) {
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
            IconButton(
                onPressed: () => _confirmDelete(context, controller, trip.id),
                icon: const Icon(Icons.delete_outline, color: Colors.red))
          ] else ...[
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit Route")),
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
                controller.deleteTrip(context, tripId);
              },
              child: const Text("Delete")),
        ],
      ),
    );
  }
}
