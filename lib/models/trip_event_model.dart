import 'package:cloud_firestore/cloud_firestore.dart';

enum TripStatus { scheduled, delayed, departed, arrived, cancelled }

class TripEvent {
  final String id;
  final String tripId;
  final TripStatus status;
  final DateTime eventTime;
  final int? delayMinutes;
  final String? reason;
  final String? updatedBy; // User ID of conductor/admin
  final DateTime createdAt;

  TripEvent({
    required this.id,
    required this.tripId,
    required this.status,
    required this.eventTime,
    this.delayMinutes,
    this.reason,
    this.updatedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'status': status.name, // Store as string
      'eventTime': Timestamp.fromDate(eventTime),
      'delayMinutes': delayMinutes,
      'reason': reason,
      'updatedBy': updatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TripEvent.fromMap(String id, Map<String, dynamic> map) {
    return TripEvent(
      id: id,
      tripId: map['tripId'] ?? '',
      status: TripStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TripStatus.scheduled,
      ),
      eventTime: (map['eventTime'] as Timestamp).toDate(),
      delayMinutes: map['delayMinutes'],
      reason: map['reason'],
      updatedBy: map['updatedBy'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
