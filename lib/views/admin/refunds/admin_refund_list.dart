import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/refund_model.dart';
import '../../../utils/app_theme.dart';
import 'admin_refund_details.dart';

class AdminRefundListScreen extends StatefulWidget {
  const AdminRefundListScreen({super.key});

  @override
  State<AdminRefundListScreen> createState() => _AdminRefundListScreenState();
}

class _AdminRefundListScreenState extends State<AdminRefundListScreen> {
  RefundStatus _selectedStatus = RefundStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Refund Management"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey.shade50,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildFilterItem(
                    RefundStatus.pending, Icons.hourglass_top, "Pending"),
                _buildFilterItem(RefundStatus.approved,
                    Icons.check_circle_outline, "Approved"),
                _buildFilterItem(
                    RefundStatus.rejected, Icons.cancel_outlined, "Rejected"),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('refunds')
                  .where('status', isEqualTo: _selectedStatus.name)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("No ${_selectedStatus.name} refunds found"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    // Manually attach ID if needed or use model factory properly
                    // The factory takes DocumentSnapshot, so we pass docs[index]
                    final refund = RefundRequest.fromFirestore(docs[index]);

                    return _buildRefundCard(refund);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterItem(RefundStatus status, IconData icon, String label) {
    final bool isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : Colors.black87))
          ],
        ),
      ),
    );
  }

  Widget _buildRefundCard(RefundRequest refund) {
    Color stripColor = Colors.grey;
    if (refund.status == RefundStatus.pending) stripColor = Colors.orange;
    if (refund.status == RefundStatus.approved) stripColor = Colors.green;
    if (refund.status == RefundStatus.rejected) stripColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, color: stripColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Ref: ${refund.ticketId.substring(0, 8)}...",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                        Text(
                            DateFormat('MMM d, h:mm a')
                                .format(refund.createdAt),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(refund.passengerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                        "Refund Amount: LKR ${refund.refundAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Reason: ${_formatReason(refund.reason)}",
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AdminRefundDetailsScreen(refundId: refund.id)));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _formatReason(RefundReason r) {
    return r.name.toUpperCase(); // Simplify for now
  }
}
