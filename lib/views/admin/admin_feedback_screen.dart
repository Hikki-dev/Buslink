import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';

class AdminFeedbackScreen extends StatelessWidget {
  const AdminFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Feedback"),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedback') // As found in grep search
            .orderBy('date', descending: true) // Assuming 'date' or 'createdAt'
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No feedback received yet."));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final comment = data['comment'] ?? data['feedback'] ?? '';
              final rating = data['rating']?.toString() ?? 'N/A';
              final userId = data['userId'] ?? 'Anonymous';
              // final date = data['date'] ...

              // Try to parse date
              DateTime? date;
              if (data['date'] is Timestamp)
                date = (data['date'] as Timestamp).toDate();

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(rating,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                  ),
                  title: Text(comment,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("User: $userId",
                          style: const TextStyle(fontSize: 12)),
                      if (date != null)
                        Text(DateFormat('MMM d, y h:mm a').format(date),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
