import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { tripStatus, delay, cancellation, refundStatus, general }

class AppNotification {
  final String id;
  final String userId;
  final String? tripId;
  final String? bookingId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime sentAt;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.userId,
    this.tripId,
    this.bookingId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.sentAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tripId': tripId,
      'bookingId': bookingId,
      'type': type.name,
      'title': title,
      'message': message,
      'isRead': isRead,
      'sentAt': Timestamp.fromDate(sentAt),
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
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }
}
