import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';

class AdminFeedbackScreen extends StatelessWidget {
  const AdminFeedbackScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Feedback"),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: _FeedbackBody(),
    );
  }
}

class _FeedbackBody extends StatefulWidget {
  @override
  State<_FeedbackBody> createState() => _FeedbackBodyState();
}

class _FeedbackBodyState extends State<_FeedbackBody> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search by Name",
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
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
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No feedback received yet."));
              }

              var docs = snapshot.data!.docs;

              // Filter by Name
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['userName'] ?? data['passengerName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final comment = data['comment'] ?? data['feedback'] ?? '';
                  final rating = data['rating']?.toString() ?? 'N/A';
                  final name =
                      data['userName'] ?? data['passengerName'] ?? 'Anonymous';
                  // Hide ID, show only name or anonymous

                  DateTime? date;
                  if (data['timestamp'] is Timestamp) {
                    date = (data['timestamp'] as Timestamp).toDate();
                  }

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: const Icon(Icons.person,
                            color: AppTheme.primaryColor),
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          // Parse rating safely
                          double r = double.tryParse(rating) ?? 0;
                          return Icon(
                            i < r ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (date != null)
                            Text(DateFormat('MMM d').format(date),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          const Icon(Icons.arrow_forward_ios,
                              size: 12, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        // Show Details Dialog
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("$name's Feedback"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 20),
                                    const SizedBox(width: 8),
                                    Text("Rating: $rating/5",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text("Comment:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(comment.isEmpty
                                    ? "No comment provided."
                                    : comment),
                                const SizedBox(height: 16),
                                if (date != null)
                                  Text(
                                      "Submitted on: ${DateFormat('MMM d, y h:mm a').format(date)}",
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"))
                            ],
                          ),
                        );
                      },
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
