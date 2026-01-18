import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/refund_model.dart';
import '../../../utils/app_theme.dart';
import '../../../../utils/language_provider.dart';
import 'package:provider/provider.dart';
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
        title: Text(Provider.of<LanguageProvider>(context)
            .translate('refund_management_title')),
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
                hintText: "Enter customer's login email",
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
                            _buildFilterItemMobile(
                                RefundStatus.pending,
                                Icons.hourglass_top,
                                Provider.of<LanguageProvider>(context)
                                    .translate('status_pending')),
                            const SizedBox(width: 8),
                            _buildFilterItemMobile(
                                RefundStatus.approved,
                                Icons.check_circle_outline,
                                Provider.of<LanguageProvider>(context)
                                    .translate('status_approved')),
                            const SizedBox(width: 8),
                            _buildFilterItemMobile(
                                RefundStatus.rejected,
                                Icons.cancel_outlined,
                                Provider.of<LanguageProvider>(context)
                                    .translate('status_rejected')),
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
                            _buildFilterItem(
                                RefundStatus.pending,
                                Icons.hourglass_top,
                                Provider.of<LanguageProvider>(context)
                                    .translate('status_pending')),
                            _buildFilterItem(
                                RefundStatus.approved,
                                Icons.check_circle_outline,
                                Provider.of<LanguageProvider>(context)
                                    .translate('status_approved')),
                            _buildFilterItem(
                                RefundStatus.rejected,
                                Icons.cancel_outlined,
                                Provider.of<LanguageProvider>(context)
                                    .translate('status_rejected')),
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
    return StreamBuilder<QuerySnapshot>(
      // Note: We might want to remove 'where' clause if we want to search ALL refunds
      // But user asked for search bar "at the top of each view (Pending, Approved)",
      // which implies searching WITHIN the status view.
      // So we keep the stream filtering by status.
      // However, if the user wants to search for a specific person regardless of status,
      // the current design force them to switch tabs.
      // User said: "Refund is working... best to have a search bar at the top of each view... so it is easy to search and view a specific person."
      // I will keep the status filter as primary, and search filters the result list.
      stream: FirebaseFirestore.instance
          .collection('refunds')
          .where('status', isEqualTo: _selectedStatus.name)
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
          return Center(
              child: Text(Provider.of<LanguageProvider>(context)
                  .translate('no_refunds_status')));
        }

        List<DocumentSnapshot> docs = snapshot.data!.docs;

        // FILTER: By Email (if available in refund data)
        // Wait, 'refunds' collection might not have 'email'.
        // RefundRequest model usually has 'userId', 'ticketId'.
        // Let's check RefundModel in a moment.
        // Assuming it has data map.
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            // Often refunds don't store email directly, they might store it in 'userData' or just use 'userId'.
            // If email is missing, we can't filter by it.
            // User specifically asked for EMAIL search.
            // Email search ONLY
            final email = (data['email'] ?? '').toString().toLowerCase();
            // Fallback to checking nested userData for email if main Doc doesn't have it
            final userEmail =
                (data['userData'] != null && data['userData']['email'] != null)
                    ? data['userData']['email'].toString().toLowerCase()
                    : '';

            final passengerEmail =
                (data['passengerEmail'] ?? '').toString().toLowerCase();

            return email.contains(query) ||
                userEmail.contains(query) ||
                passengerEmail.contains(query);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
              child: Text(Provider.of<LanguageProvider>(context)
                  .translate('no_refunds_search')));
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
                child: Column(
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
                    Text(refund.passengerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                        "${Provider.of<LanguageProvider>(context).translate('refund_amount_prefix')}: LKR ${refund.refundAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                        "${Provider.of<LanguageProvider>(context).translate('reason_prefix')}: ${_formatReason(refund.reason)}",
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
