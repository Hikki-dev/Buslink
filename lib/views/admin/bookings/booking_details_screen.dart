import '../../../utils/bl_colors.dart';
import '../../widgets/bl_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../refunds/admin_refund_list.dart'; // Import for navigation

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;

  const BookingDetailsScreen(
      {super.key, required this.data, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    // Extract data safely
    // Extract data safely
    final tripData = data['tripData'] as Map<String, dynamic>? ?? {};
    final passengerName = data['passengerName'] ?? data['userName'] ?? 'N/A';
    final userEmail = data['passengerEmail'] ??
        data['userEmail'] ??
        data['email'] ??
        (data['userData'] != null ? data['userData']['email'] : null);
    // Removed unused passengerId

    final fromCity = tripData['fromCity'] ??
        tripData['originCity'] ??
        data['fromCity'] ??
        data['origin'] ??
        'N/A';
    final toCity = tripData['toCity'] ??
        tripData['destinationCity'] ??
        data['toCity'] ??
        data['destination'] ??
        'N/A';
    final route = "$fromCity ➔ $toCity";

    // Removed unused tripId
    final busNumber = tripData['busNumber'] ?? 'N/A';
    final status = (data['status'] ?? 'Unknown').toString().toUpperCase();
    final paymentStatus = (data['paymentStatus'] ?? 'Paid')
        .toString()
        .toUpperCase(); // Infer paid
    final price = data['totalAmount'] ?? data['price'] ?? 0;

    // Safely parse date
    String dateStr = 'N/A';
    final timestamp = tripData['departureDateTime'] ??
        tripData['departureTime'] ??
        data['departureTime'];

    if (timestamp != null) {
      DateTime? dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is String) {
        dt = DateTime.tryParse(timestamp);
      }

      if (dt != null) {
        dateStr = DateFormat('MMM d, yyyy h:mm a').format(dt);
      }
    }

    Color statusColor = Colors.grey;
    if (status == 'CONFIRMED') {
      statusColor = Colors.green;
    } else if (status == 'REFUNDED') {
      statusColor = Colors.red;
    } else if (status == 'CANCELLED') {
      statusColor = Colors.orange;
    }

    return FutureBuilder<DocumentSnapshot?>(
        future: (userEmail == null ||
                    userEmail.toString().isEmpty ||
                    userEmail.toString() == 'N/A' ||
                    userEmail.toString() == 'null' ||
                    passengerName == 'Unknown User' ||
                    passengerName == 'Guest' ||
                    passengerName == 'N/A') &&
                data['userId'] != null &&
                data['userId'] != 'guest'
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(data['userId'])
                .get()
            : Future<DocumentSnapshot?>.value(null),
        builder: (context, userSnap) {
          Map<String, dynamic>? userProfile;
          if (userSnap.hasData && userSnap.data!.exists) {
            userProfile = userSnap.data!.data() as Map<String, dynamic>?;
          }

          final String resolvedName = (passengerName == 'Unknown User' ||
                      passengerName == 'Guest' ||
                      passengerName == 'N/A') &&
                  userProfile != null
              ? (userProfile['displayName'] ??
                  userProfile['name'] ??
                  passengerName)
              : passengerName;

          String? emailVal = userEmail?.toString();
          if (emailVal == null ||
              emailVal.isEmpty ||
              emailVal == 'N/A' ||
              emailVal == 'null') {
            emailVal = userProfile?['email']?.toString();
          }

          final String finalEmail =
              (emailVal == null || emailVal.isEmpty) ? 'N/A' : emailVal;

          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(children: [
              const BlHeader(title: 'Booking Details'),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 1. Status Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                    status == 'CONFIRMED'
                                        ? Icons.check_circle
                                        : (status == 'REFUNDED'
                                            ? Icons.money_off
                                            : Icons.info),
                                    color: statusColor,
                                    size: 32),
                                const SizedBox(height: 8),
                                Text(status,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Trip Details Card
                          _buildSectionCard(
                            context,
                            title: "Trip Information",
                            icon: Icons.directions_bus,
                            children: [
                              const Divider(),
                              _buildInfoRow(context, "Route", route),
                              _buildInfoRow(context, "Date", dateStr),
                              _buildInfoRow(context, "Bus Number", busNumber),
                              _buildInfoRow(
                                  context,
                                  "Seat Numbers",
                                  (data['seatNumbers'] as List<dynamic>?)
                                          ?.join(", ") ??
                                      "N/A"),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 3. Passenger Details Card
                          _buildSectionCard(
                            context,
                            title: "Passenger Details",
                            icon: Icons.person,
                            children: [
                              _buildInfoRow(context, "Name", resolvedName),
                              if (finalEmail != 'N/A')
                                _buildCopyRow(context, "Email", finalEmail),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 4. Payment Details Card
                          _buildSectionCard(
                            context,
                            title: "Payment Summary",
                            icon: Icons.receipt_long,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total Amount",
                                      style: TextStyle()),
                                  Text("LKR $price",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: BL.crimson)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(context, "Status", paymentStatus),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 5. Actions
                          if (status == 'REFUNDED' ||
                              status == 'REFUND_REQUESTED')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const AdminRefundListScreen()));
                                },
                                icon: const Icon(Icons.currency_exchange),
                                label: const Text("Manage Refund"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 56),
                                  backgroundColor: BL.crimson,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          );
        });
  }

  Widget _buildSectionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BL.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: BL.crimson)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          ),
          Expanded(
            flex: 5,
            child: Text(value,
                textAlign: TextAlign.end,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500))),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("$label copied!"),
                        duration: const Duration(seconds: 1)));
                  },
                  child: Icon(Icons.copy, size: 16, color: Colors.blue[400]),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
