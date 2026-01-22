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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Enter name or email",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                if (isMobile) {
                  // Mobile: Horizontal Filter + Vertical List
                  return Column(
                    children: [
                      Container(
                        color: Theme.of(context).cardColor,
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildFilterItemMobile(RefundStatus.pending,
                                Icons.hourglass_top, 'Pending'),
                            const SizedBox(width: 8),
                            _buildFilterItemMobile(RefundStatus.approved,
                                Icons.check_circle_outline, 'Approved'),
                            const SizedBox(width: 8),
                            _buildFilterItemMobile(RefundStatus.rejected,
                                Icons.cancel_outlined, 'Rejected'),
                          ],
                        ),
                      ),
                      Expanded(child: _buildRefundList()),
                    ],
                  );
                } else {
                  // Desktop: Sidebar + List
                  return Row(
                    children: [
                      Container(
                        width: 250,
                        color: Theme.of(context).cardColor,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildFilterItem(RefundStatus.pending,
                                Icons.hourglass_top, 'Pending'),
                            _buildFilterItem(RefundStatus.approved,
                                Icons.check_circle_outline, 'Approved'),
                            _buildFilterItem(RefundStatus.rejected,
                                Icons.cancel_outlined, 'Rejected'),
                          ],
                        ),
                      ),
                      Expanded(child: _buildRefundList()),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundList() {
    // IMPORTANT: When searching, fetch ALL results across all statuses
    // Otherwise, filter by selected status
    final hasSearch = _searchController.text.trim().isNotEmpty;

    Query query = FirebaseFirestore.instance
        .collection('refunds')
        .orderBy('createdAt', descending: true);

    // Only filter by status when NOT searching
    if (!hasSearch) {
      query = query.where('status', isEqualTo: _selectedStatus.name);
      query = query.limit(50); // Reasonable limit for non-search view
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: SelectableText("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No refunds found'));
        }

        List<DocumentSnapshot> docs = snapshot.data!.docs;

        if (hasSearch) {
          final query = _searchController.text.trim().toLowerCase();

          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;

            final pEmail = (data['passengerEmail'] ?? data['email'] ?? '')
                .toString()
                .toLowerCase();
            final pName =
                (data['passengerName'] ?? '').toString().toLowerCase();
            final pPhone = (data['passengerPhone'] ?? data['phone'] ?? '')
                .toString()
                .toLowerCase();

            final udEmail =
                (data['userData'] != null && data['userData']['email'] != null)
                    ? data['userData']['email'].toString().toLowerCase()
                    : '';
            final udName =
                (data['userData'] != null && data['userData']['name'] != null)
                    ? data['userData']['name'].toString().toLowerCase()
                    : '';

            return pEmail.contains(query) ||
                udEmail.contains(query) ||
                pName.contains(query) ||
                udName.contains(query) ||
                pPhone.contains(query);
          }).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text('No refunds match your search'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final refund = RefundRequest.fromFirestore(docs[index]);
            return _buildRefundCard(refund);
          },
        );
      },
    );
  }

  Widget _buildFilterItemMobile(
      RefundStatus status, IconData icon, String label) {
    final bool isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: AppTheme.primaryColor)
                : Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? AppTheme.primaryColor : null),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : null)),
            ],
          ),
        ),
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
            Icon(icon, color: isSelected ? AppTheme.primaryColor : null),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : null))
          ],
        ),
      ),
    );
  }

  Widget _buildRefundCard(RefundRequest refund) {
    Color stripColor = Theme.of(context).disabledColor;
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
                child: FutureBuilder<DocumentSnapshot?>(
                  future: (refund.email == null ||
                              refund.email!.isEmpty ||
                              refund.passengerName == 'Guest') &&
                          refund.userId.isNotEmpty &&
                          refund.userId != 'guest'
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(refund.userId)
                          .get()
                      : Future<DocumentSnapshot?>.value(null),
                  builder: (context, userSnap) {
                    Map<String, dynamic>? userProfile;
                    if (userSnap.hasData && userSnap.data!.exists) {
                      userProfile =
                          userSnap.data!.data() as Map<String, dynamic>?;
                    }

                    final String name =
                        (refund.passengerName == 'Guest' && userProfile != null)
                            ? (userProfile['displayName'] ??
                                userProfile['name'] ??
                                refund.passengerName)
                            : refund.passengerName;

                    String? email = refund.email;
                    if (email == null || email.isEmpty) {
                      email = refund.userData?['email']?.toString();
                    }
                    if ((email == null || email.isEmpty) &&
                        userProfile != null) {
                      email = userProfile['email'];
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                DateFormat('MMM d, h:mm a')
                                    .format(refund.createdAt),
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (email != null && email.isNotEmpty && email != 'N/A')
                          Text(email,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                            "${"Refund Amount"}: LKR ${refund.refundAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("${"Reason"}: ${_getDisplayReason(refund)}",
                            style: const TextStyle(fontSize: 13)),
                      ],
                    );
                  },
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
    // Split camelCase into words and capitalize
    final name = r.name;
    final buffer = StringBuffer();
    for (int i = 0; i < name.length; i++) {
      if (i > 0 && name[i].toUpperCase() == name[i]) {
        buffer.write(' ');
      }
      buffer.write(i == 0 ? name[i].toUpperCase() : name[i]);
    }
    return buffer.toString().toUpperCase();
  }

  String _getDisplayReason(RefundRequest refund) {
    // If the reason is "other" and they provided custom text, show that
    if (refund.reason == RefundReason.other &&
        refund.otherReasonText != null &&
        refund.otherReasonText!.trim().isNotEmpty) {
      // Capitalize first letter and preserve user punctuation
      final text = refund.otherReasonText!.trim();
      return text[0].toUpperCase() + text.substring(1);
    }

    // Otherwise, show the formatted enum name
    return _formatReason(refund.reason);
  }
}
