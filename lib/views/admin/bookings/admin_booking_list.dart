import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_theme.dart';

import 'booking_details_screen.dart';

class AdminBookingListScreen extends StatefulWidget {
  const AdminBookingListScreen({super.key});

  @override
  State<AdminBookingListScreen> createState() => _AdminBookingListScreenState();
}

class _AdminBookingListScreenState extends State<AdminBookingListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  DateTime? _selectedDate;

  // Status Options
  final List<String> _statusOptions = [
    'Confirmed',
    'cancelled',
    'completed',
    'refund_requested',
    'refunded'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDate = null;
      _searchController.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchBookings(refresh: true);
    }
  }

  // Pagination State
  final int _limit = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings({bool refresh = false}) async {
    if (_isLoading) return;

    // Check if we have active filters (search, status, or date)
    final hasFilters = _searchController.text.trim().isNotEmpty ||
        _selectedStatus != null ||
        _selectedDate != null;

    if (refresh) {
      _bookings = [];
      _lastDocument = null;
      _hasMore = true;
    }

    // If filtering, fetch ALL at once (no pagination)
    // If no filters, use normal pagination
    if (!hasFilters && !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('tickets')
          .orderBy(FieldPath.documentId); // Stable Sort

      // Only apply pagination when NOT filtering
      if (!hasFilters) {
        query = query.limit(_limit);
        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }
      }

      final snap = await query.get();

      if (!hasFilters) {
        if (snap.docs.length < _limit) {
          _hasMore = false;
        }
        if (snap.docs.isNotEmpty) {
          _lastDocument = snap.docs.last;
          _bookings.addAll(snap.docs);
        }
      } else {
        // When filtering, replace all bookings with filtered results
        _bookings = snap.docs;
        _hasMore = false; // No pagination when filtering
      }
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Management'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearFilters,
            tooltip: "Clear Filters",
          )
        ],
      ),
      body: Column(
        children: [
          // FILTERS SECTION
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Search Row
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Enter customer's login email",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    _fetchBookings(refresh: true); // Refetch with new search
                  },
                ),
                const SizedBox(height: 12),
                // Dropdowns Row
                Row(
                  children: [
                    // Status Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            hint: const Text('Filter Status'),
                            isExpanded: true,
                            items: _statusOptions.map((s) {
                              // Beautify status
                              String label =
                                  s.replaceAll('_', ' ').toUpperCase();
                              return DropdownMenuItem(
                                value: s,
                                child: Text(label,
                                    style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() => _selectedStatus = v);
                              _fetchBookings(refresh: true);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date Picker Button
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(_selectedDate!)
                                      : 'Travel Date',
                                  style: TextStyle(
                                      color: _selectedDate != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Colors.grey.shade600),
                                ),
                              ),
                              const Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // LIST SECTION
          Expanded(
            child: _isLoading && _bookings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? Center(child: Text('no_bookings_found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _bookings.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _bookings.length) {
                            // Bottom Loader / Load More
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: _hasMore
                                    ? _isLoading
                                        ? const CircularProgressIndicator()
                                        : ElevatedButton(
                                            onPressed: () => _fetchBookings(),
                                            child: const Text("Load More"))
                                    : const Text("No more bookings"),
                              ),
                            );
                          }

                          // Render Trip Card
                          final doc = _bookings[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final id = doc.id;

                          // --- FILTERING (Client Side) ---
                          // Status
                          final status = (data['status'] ?? 'Confirmed');
                          if (_selectedStatus != null &&
                              status != _selectedStatus) {
                            return const SizedBox.shrink();
                          }

                          // Search (Email, Name, or Phone)
                          if (_searchController.text.isNotEmpty) {
                            final q =
                                _searchController.text.toLowerCase().trim();

                            final pEmail = (data['passengerEmail'] ?? '')
                                .toString()
                                .toLowerCase();
                            final uEmail =
                                (data['email'] ?? '').toString().toLowerCase();
                            final pName = (data['passengerName'] ??
                                    data['userName'] ??
                                    '')
                                .toString()
                                .toLowerCase();
                            final pPhone = (data['passengerPhone'] ?? '')
                                .toString()
                                .toLowerCase();

                            final udEmail = (data['userData'] != null &&
                                    data['userData']['email'] != null)
                                ? data['userData']['email']
                                    .toString()
                                    .toLowerCase()
                                : '';
                            final udName = (data['userData'] != null &&
                                    data['userData']['name'] != null)
                                ? data['userData']['name']
                                    .toString()
                                    .toLowerCase()
                                : '';

                            if (!pEmail.contains(q) &&
                                !uEmail.contains(q) &&
                                !udEmail.contains(q) &&
                                !pName.contains(q) &&
                                !udName.contains(q) &&
                                !pPhone.contains(q)) {
                              return const SizedBox.shrink();
                            }
                          }

                          // Date Filter (Departure Date)
                          if (_selectedDate != null) {
                            final tripData =
                                data['tripData'] as Map<String, dynamic>? ?? {};
                            final timestamp = tripData['departureDateTime'] ??
                                tripData['departureTime'] ??
                                data['departureTime'];

                            DateTime? departureDate;
                            if (timestamp is Timestamp) {
                              departureDate = timestamp.toDate();
                            } else if (timestamp is String) {
                              departureDate = DateTime.tryParse(timestamp);
                            }

                            if (departureDate != null) {
                              if (departureDate.year != _selectedDate!.year ||
                                  departureDate.month != _selectedDate!.month ||
                                  departureDate.day != _selectedDate!.day) {
                                return const SizedBox.shrink();
                              }
                            } else {
                              // If no date found, maybe exclude or keep?
                              // Safe to exclude if filtering by date.
                              return const SizedBox.shrink();
                            }
                          }

                          return _buildBookingTile(data, id);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTile(Map<String, dynamic> data, String id) {
    // Helper to build tile and keep build method clean
    // Normalize status to lowercase for comparison
    final statusNorm = (data['status'] ?? 'Unknown').toString().toLowerCase();
    Color statusColor = Colors.grey;
    if (statusNorm == 'confirmed') statusColor = Colors.green;
    if (statusNorm == 'cancelled') statusColor = Colors.red;
    if (statusNorm == 'completed') statusColor = Colors.blue;
    if (statusNorm == 'refund_requested' || statusNorm == 'refund requested')
      statusColor = Colors.orange;
    if (statusNorm == 'refunded') statusColor = Colors.purple;

    // Helper to find string from multiple keys
    String getString(Map m, List<String> keys) {
      for (var k in keys) {
        if (m[k] != null &&
            m[k].toString().isNotEmpty &&
            m[k].toString() != 'N/A') return m[k].toString();
      }
      return '';
    }

    final tripData = data['tripData'] as Map<String, dynamic>? ?? {};

    // Robust City Lookup
    String fromCity = getString(tripData, [
      'fromCity',
      'originCity',
      'origin',
      'from',
      'FromCity',
      'OriginCity',
      'source'
    ]);
    if (fromCity.isEmpty)
      fromCity = getString(data, ['fromCity', 'originCity', 'origin', 'from']);
    if (fromCity.isEmpty) fromCity = 'N/A';

    String toCity = getString(tripData, [
      'toCity',
      'destinationCity',
      'destination',
      'to',
      'ToCity',
      'DestinationCity',
      'dest'
    ]);
    if (toCity.isEmpty)
      toCity =
          getString(data, ['toCity', 'destinationCity', 'destination', 'to']);
    if (toCity.isEmpty) toCity = 'N/A';

    // Parse date safely
    final timestamp = tripData['departureDateTime'] ??
        tripData['departureTime'] ??
        data['departureTime'];

    DateTime? departureDate;
    if (timestamp is Timestamp) {
      departureDate = timestamp.toDate();
    } else if (timestamp is String) {
      departureDate = DateTime.tryParse(timestamp);
    }

    String pName =
        getString(data, ['passengerName', 'userName', 'name', 'user_name']);
    if (pName.isEmpty) pName = 'Unknown User';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.1),
            radius: 24,
            child:
                Icon(Icons.confirmation_number, color: statusColor, size: 24),
          ),
          title: Text(pName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.route, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text("$fromCity ➔ $toCity",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 6),
                  Text(
                      departureDate != null
                          ? DateFormat('MMM d, h:mm a').format(departureDate)
                          : 'Date N/A',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              () {
                final displayEmail = data['passengerEmail'] ??
                    (data['userData'] != null
                        ? data['userData']['email']
                        : null) ??
                    '';
                final displayPhone = data['passengerPhone'] ??
                    (data['userData'] != null
                        ? data['userData']['phone']
                        : null) ??
                    '';
                final List<String> contactParts = [];
                if (displayEmail.isNotEmpty && displayEmail != 'N/A') {
                  contactParts.add(displayEmail);
                }
                if (displayPhone.isNotEmpty && displayPhone != 'N/A') {
                  contactParts.add(displayPhone);
                }

                if (contactParts.isNotEmpty) {
                  return Text(
                    contactParts.join(" ").trim(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  );
                }
                return const SizedBox.shrink();
              }(),
              const SizedBox(height: 6),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("LKR ${data['totalAmount'] ?? data['price'] ?? 0}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15, // Reduced from 17 to fix overflow
                      color: AppTheme.primaryColor)),
              const SizedBox(height: 4), // Reduced from 8
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2), // Reduced vertical
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(statusNorm.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        fontSize: 10, // Reduced from 11
                        color: statusColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailsScreen(data: data, bookingId: id),
              ),
            );
          },
        ),
      ),
    );
  }
}
