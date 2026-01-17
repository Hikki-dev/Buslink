import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  tripStatus,
  delay,
  cancellation,
  refundStatus,
  booking,
  general
}

class AppNotification {
  final String id;
  final String userId;
  final String? tripId;
  final String? bookingId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.userId,
    this.tripId,
    this.bookingId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tripId': tripId,
      'bookingId': bookingId,
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      tripId: map['tripId'],
      bookingId: map['bookingId'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      title: map['title'] ?? '',
      body: map['body'] ?? map['message'] ?? '', // Fallback for safety
      isRead: map['isRead'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    return AppNotification.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
