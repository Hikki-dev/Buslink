import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_theme.dart';

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

    // 1. Status Filter
    if (_selectedStatus != null) {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    // 2. Date Filter
    // Note: To filter by date on a Timestamp field 'departureTime', we need a range (Start of Day to End of Day)
    if (_selectedDate != null) {
      final start = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('departureTime', isGreaterThanOrEqualTo: start)
          .where('departureTime', isLessThan: end);
      // Firestore requires the first orderBy to match the inequality filter
      query = query.orderBy('departureTime');
    } else {
      // Default Sort
      query = query.orderBy('createdAt', descending: true);
    }

    // Limit for performance
    return query.limit(50);
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
                    hintText: "Search by Passenger Name or Ref ID",
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

                var docs = snapshot.data!.docs;

                // Client-side search (Name/ID) - Firestore doesn't support substring search well
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name =
                        (data['userName'] ?? '').toString().toLowerCase();
                    final id = d.id.toLowerCase();
                    final passName =
                        (data['passengerName'] ?? '').toString().toLowerCase();
                    return name.contains(query) ||
                        id.contains(query) ||
                        passName.contains(query);
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
    final status = data['status'] ?? 'unknown';
    Color statusColor = Colors.grey;
    if (status == 'confirmed') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'completed') statusColor = Colors.blue;
    if (status == 'refund_requested') statusColor = Colors.orange;
    if (status == 'refunded') statusColor = Colors.purple;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.confirmation_number, color: statusColor),
        ),
        title: Text(data['passengerName'] ?? data['userName'] ?? 'Unknown User',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.route, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(
                        "${data['fromCity'] ?? data['origin']} ➔ ${data['toCity'] ?? data['destination']}",
                        style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                    data['departureTime'] != null
                        ? DateFormat('MMM d, h:mm a').format(
                            (data['departureTime'] as Timestamp).toDate())
                        : 'Date N/A',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text("Ref: ${id.substring(0, 8)}...",
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("LKR ${data['totalAmount'] ?? data['price'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        onTap: () {
          // Future: Open detail view to see payment intent ID etc.
          // For now just show snackbar
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Booking ID: $id")));
        },
      ),
    );
  }
}
