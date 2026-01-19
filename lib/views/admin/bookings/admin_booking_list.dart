import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_theme.dart';
import '../../../../utils/language_provider.dart';
import 'package:provider/provider.dart';
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
    'confirmed',
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
    if (refresh) {
      _bookings = [];
      _lastDocument = null;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('tickets')
          .orderBy(FieldPath.documentId) // Stable Sort
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();
      if (snap.docs.length < _limit) {
        _hasMore = false;
      }
      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;
        _bookings.addAll(snap.docs);
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
        title: Text(Provider.of<LanguageProvider>(context)
            .translate('booking_management_title')),
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
                  onChanged: (val) => setState(() {}),
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
                            hint: Text(Provider.of<LanguageProvider>(context)
                                .translate('filter_status_hint')),
                            isExpanded: true,
                            items: _statusOptions.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                    Provider.of<LanguageProvider>(context)
                                        .translate('status_$s')
                                        .toUpperCase(),
                                    style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedStatus = v),
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
                                      : Provider.of<LanguageProvider>(context)
                                          .translate('travel_date_hint'),
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
                    ? Center(
                        child: Text(Provider.of<LanguageProvider>(context)
                            .translate('no_bookings_found')))
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
                          final status = (data['status'] ?? 'confirmed');
                          if (_selectedStatus != null &&
                              status != _selectedStatus) {
                            return const SizedBox.shrink();
                          }

                          // Search (Email Only per user request)
                          if (_searchController.text.isNotEmpty) {
                            final q =
                                _searchController.text.toLowerCase().trim();
                            // Checks passengerEmail (ticket) or user email (account)
                            final passengerEmail =
                                (data['passengerEmail'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final userEmail =
                                (data['email'] ?? '') // Sometimes duplicate
                                    .toString()
                                    .toLowerCase();
                            final userDataEmail = (data['userData'] != null &&
                                    data['userData']['email'] != null)
                                ? data['userData']['email']
                                    .toString()
                                    .toLowerCase()
                                : '';

                            if (!passengerEmail.contains(q) &&
                                !userEmail.contains(q) &&
                                !userDataEmail.contains(q)) {
                              return const SizedBox.shrink();
                            }
                          }

                          // Date Filter
                          if (_selectedDate != null) {
                            if (data['bookingTime'] != null) {
                              final bt =
                                  (data['bookingTime'] as Timestamp).toDate();
                              if (bt.year != _selectedDate!.year ||
                                  bt.month != _selectedDate!.month ||
                                  bt.day != _selectedDate!.day) {
                                return const SizedBox.shrink();
                              }
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
    final status = (data['status'] ?? 'unknown').toString().toLowerCase();
    Color statusColor = Colors.grey;
    if (status == 'confirmed') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'completed') statusColor = Colors.blue;
    if (status == 'refund_requested') statusColor = Colors.orange;
    if (status == 'refunded') statusColor = Colors.purple;

    final tripData = data['tripData'] as Map<String, dynamic>? ?? {};
    final fromCity = tripData['fromCity'] ??
        tripData['originCity'] ??
        data['fromCity'] ??
        'N/A';
    final toCity = tripData['toCity'] ??
        tripData['destinationCity'] ??
        data['toCity'] ??
        'N/A';

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
          title: Text(
              data['passengerName'] ?? data['userName'] ?? 'Unknown User',
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
              // Removed Reference ID display as per user request
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
                child: Text(status.toUpperCase(),
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
