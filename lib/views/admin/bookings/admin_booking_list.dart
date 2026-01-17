import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('tickets');

    // NUCLEAR OPTION: Fetch raw data to bypass schema inconsistencies (missing fields).
    // We rely completely on client-side filtering for Status and Date.
    // Default order is Document ID. This guarantees we get data if it exists.

    return query.limit(1000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Management"),
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
                // Search Row (Still Client Side mostly for name, but could be separate)
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by Username, Name or Ref ID",
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
                            hint: const Text("Filter Status"),
                            isExpanded: true,
                            items: _statusOptions.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase(),
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
                                  _selectedDate == null
                                      ? "Travel Date"
                                      : DateFormat('MMM d, yyyy')
                                          .format(_selectedDate!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: _selectedDate == null
                                          ? Colors.grey.shade600
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color),
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red)),
                  ));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> docs = List.from(snapshot.data!.docs);

                // SORTING: Sort by Departure Time Descending (Newest/Future first)
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  // Handle varying date fields/formats
                  final tripDataA =
                      dataA['tripData'] as Map<String, dynamic>? ?? {};
                  final tripDataB =
                      dataB['tripData'] as Map<String, dynamic>? ?? {};

                  final valA = tripDataA['departureDateTime'] ??
                      tripDataA['departureTime'] ??
                      dataA['departureTime'];
                  final valB = tripDataB['departureDateTime'] ??
                      tripDataB['departureTime'] ??
                      dataB['departureTime'];

                  DateTime? timeA;
                  DateTime? timeB;

                  if (valA is Timestamp) {
                    timeA = valA.toDate();
                  } else if (valA is String) {
                    timeA = DateTime.tryParse(valA);
                  }

                  if (valB is Timestamp) {
                    timeB = valB.toDate();
                  } else if (valB is String) {
                    timeB = DateTime.tryParse(valB);
                  }

                  if (timeA == null && timeB == null) return 0;
                  if (timeA == null) return 1; // Put invalid dates at bottom
                  if (timeB == null) return -1;

                  return timeB.compareTo(timeA); // Descending
                });

                // 1. Client-Side Text Search Filter (If not handled by server query efficiently)
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name =
                        (data['userName'] ?? '').toString().toLowerCase();
                    final id = d.id.toLowerCase();
                    final passName =
                        (data['passengerName'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();

                    // Include Email search as well
                    return name.contains(query) ||
                        id.contains(query) ||
                        passName.contains(query) ||
                        email.contains(query);
                  }).toList();
                }

                // 2. Client-Side Status Filter (Apply even if searching)
                if (_selectedStatus != null) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final status =
                        (data['status'] ?? '').toString().toLowerCase();
                    return status == _selectedStatus!.toLowerCase();
                  }).toList();
                }

                // 3. Client-Side Date Filter (Apply even if searching)
                if (_selectedDate != null) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final tripData =
                        data['tripData'] as Map<String, dynamic>? ?? {};
                    final timestamp = tripData['departureDateTime'] ??
                        tripData['departureTime'] ??
                        data['departureTime'];

                    if (timestamp == null) return false; // Skip if no date

                    DateTime? date;
                    if (timestamp is Timestamp) {
                      date = timestamp.toDate();
                    } else if (timestamp is String) {
                      date = DateTime.tryParse(timestamp);
                    }

                    if (date == null) return false;

                    return date.year == _selectedDate!.year &&
                        date.month == _selectedDate!.month &&
                        date.day == _selectedDate!.day;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text("No bookings found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildBookingTile(data, docs[index].id);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBookingTile(Map<String, dynamic> data, String id) {
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

    final timestamp = tripData['departureDateTime'] ??
        tripData['departureTime'] ??
        data['departureTime'];

    DateTime? departureDate;
    if (timestamp is Timestamp) {
      departureDate = timestamp.toDate();
    } else if (timestamp is String) {
      // Try parse if string
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
              Row(
                children: [
                  Text("Ref: ${id.substring(0, 8)}...",
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Booking Reference Copied"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Icon(Icons.copy,
                        size: 16, color: AppTheme.primaryColor),
                  ),
                ],
              ),
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
