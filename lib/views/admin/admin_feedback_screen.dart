import 'layout/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';
import 'package:intl/intl.dart';

class AdminFeedbackScreen extends StatelessWidget {
  const AdminFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      AdminShell(selected: 5, child: _buildPage(context));

  Widget _buildPage(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: BL.surface,
      body: Column(
        children: [
          if (!isDesktop) const BlHeader(title: 'Customer Feedback'),
          if (isDesktop)
            const Padding(
              padding: EdgeInsets.fromLTRB(36, 32, 36, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Customer Feedback',
                    style:
                        TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
              ),
            ),
          const Expanded(child: _FeedbackBody()),
        ],
      ),
    );
  }
}

class _FeedbackBody extends StatefulWidget {
  const _FeedbackBody();

  @override
  State<_FeedbackBody> createState() => _FeedbackBodyState();
}

class _FeedbackBodyState extends State<_FeedbackBody> {
  String _searchQuery = "";

  Widget _stars(int n) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(i <= n ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 24, color: i <= n ? BL.crimson : const Color(0xFFB5ABAC)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width > 900 ? 36.0 : 16.0;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 18, pad, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: TextField(
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  hintText: 'Search by Email',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: BL.fill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: BL.hairline, width: 1.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: BL.hairline, width: 1.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: BL.crimson, width: 2)),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: BL.crimson));
              }
              if (snapshot.hasError) {
                return const BlEmpty(
                    icon: Icons.cloud_off,
                    title: 'We could not load the feedback',
                    message: 'Check the connection and try again.');
              }
              var docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const BlEmpty(
                    icon: Icons.chat_bubble_outline,
                    title: 'No feedback received yet.');
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['userEmail'] ?? data['email'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q);
                }).toList();
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 32),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final comment =
                      (data['comment'] ?? data['feedback'] ?? '').toString();
                  final rating = (data['rating'] as num?)?.toInt();
                  final email =
                      (data['userEmail'] ?? data['email'] ?? '').toString();
                  final name = (data['userName'] ?? data['passengerName'] ?? '')
                      .toString();
                  final who = email.isNotEmpty && email != 'N/A'
                      ? email
                      : (name.isNotEmpty ? name : 'Anonymous');
                  DateTime? date;
                  if (data['timestamp'] is Timestamp) {
                    date = (data['timestamp'] as Timestamp).toDate();
                  }
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: BL.hairline),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(who,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          Text(
                              date != null
                                  ? DateFormat('d MMM yyyy').format(date)
                                  : 'Unknown Date',
                              style: TextStyle(fontSize: 15, color: BL.muted)),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Rating: ',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          if (rating != null) _stars(rating),
                          const SizedBox(width: 8),
                          Text(
                              rating == null ? 'No rating' : '$rating out of 5',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 8),
                        comment.isEmpty
                            ? Text('No comment provided.',
                                style: TextStyle(fontSize: 17, color: BL.muted))
                            : Text.rich(TextSpan(
                                style:
                                    const TextStyle(fontSize: 17, height: 1.45),
                                children: [
                                    const TextSpan(
                                        text: 'Feedback: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    TextSpan(text: comment),
                                  ])),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
