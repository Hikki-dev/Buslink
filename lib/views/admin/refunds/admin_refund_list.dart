import '../layout/admin_shell.dart';
import 'package:flutter/material.dart';
import '../widgets/status_chip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/bl_colors.dart';
import '../../widgets/bl_widgets.dart';
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
  Widget build(BuildContext context) =>
      AdminShell(selected: 4, child: _buildPage(context));

  Widget _buildPage(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    Widget tab(RefundStatus st, String label) {
      final on = _selectedStatus == st;
      return Semantics(
        button: true,
        selected: on,
        child: InkWell(
          onTap: () => setState(() => _selectedStatus = st),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? BL.crimson : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: on ? BL.crimson : BL.border, width: 1.5),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : BL.ink)),
          ),
        ),
      );
    }

    final search = TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: 'Enter name or email',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF5F3F4),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BL.hairline, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BL.hairline, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BL.crimson, width: 2)),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          if (!isDesktop) const BlHeader(title: 'Refund Management'),
          Padding(
            padding: EdgeInsets.fromLTRB(isDesktop ? 36 : 16,
                isDesktop ? 32 : 16, isDesktop ? 36 : 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 18),
                      child: Text('Refund Management',
                          style: TextStyle(
                              fontSize: 34, fontWeight: FontWeight.w800)),
                    ),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        tab(RefundStatus.pending, 'Pending'),
                        const SizedBox(width: 8),
                        tab(RefundStatus.approved, 'Approved'),
                        const SizedBox(width: 8),
                        tab(RefundStatus.rejected, 'Rejected'),
                      ]),
                      SizedBox(width: 420, child: search),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildRefundList()),
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
        .where('status', isEqualTo: _selectedStatus.name)
        .orderBy('createdAt', descending: true);

    if (!hasSearch) {
      query = query.limit(50);
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
          return const BlEmpty(
              icon: Icons.payments_outlined, title: 'No refunds found');
        }

        List<DocumentSnapshot> docs = snapshot.data!.docs;

        if (hasSearch) {
          final query = _searchController.text.trim().toLowerCase();

          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;

            final pEmail = (data['passengerEmail'] ?? data['email'] ?? '')
                .toString()
                .toLowerCase();
            final udEmail = (data['userData'] != null
                    ? (data['userData']['email'] ??
                        data['userData']['passengerEmail'] ??
                        '')
                    : '')
                .toString()
                .toLowerCase();

            final pName = (data['passengerName'] ?? data['name'] ?? '')
                .toString()
                .toLowerCase();
            final udName = (data['userData'] != null
                    ? (data['userData']['name'] ??
                        data['userData']['displayName'] ??
                        '')
                    : '')
                .toString()
                .toLowerCase();

            final pPhone = (data['passengerPhone'] ?? data['phone'] ?? '')
                .toString()
                .toLowerCase();

            return pEmail.contains(query) ||
                udEmail.contains(query) ||
                pName.contains(query) ||
                udName.contains(query) ||
                pPhone.contains(query);
          }).toList();
        }

        if (docs.isEmpty) {
          return const BlEmpty(
              icon: Icons.search_off, title: 'No refunds match your search');
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

  Widget _buildRefundCard(RefundRequest refund) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BL.hairline),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<DocumentSnapshot?>(
                  future: (refund.email == null ||
                              refund.email!.isEmpty ||
                              refund.email == 'N/A' ||
                              refund.email == 'null' ||
                              refund.passengerName == 'Guest' ||
                              refund.passengerName == 'Unknown User' ||
                              refund.passengerName == 'N/A') &&
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

                    final String name = (refund.passengerName == 'Guest' ||
                                refund.passengerName == 'Unknown User' ||
                                refund.passengerName == 'N/A') &&
                            userProfile != null
                        ? (userProfile['displayName'] ??
                            userProfile['name'] ??
                            refund.passengerName)
                        : refund.passengerName;

                    String? email = refund.email;
                    if (email == null ||
                        email.isEmpty ||
                        email == 'N/A' ||
                        email == 'null') {
                      email = refund.userData?['email']?.toString();
                    }
                    if ((email == null ||
                            email.isEmpty ||
                            email == 'N/A' ||
                            email == 'null') &&
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
                            StatusChip(refund.status.name),
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
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                foregroundColor: BL.crimson,
                side: const BorderSide(color: BL.crimson, width: 2),
                shape: const StadiumBorder(),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              child: const Text('Review'),
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
