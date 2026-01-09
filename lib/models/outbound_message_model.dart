import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { queued, sent, delivered, failed }

class OutboundMessage {
  final String id;
  final String? userId; // Nullable for guest/unknown
  final String? bookingId;
  final String channel; // 'SMS' for now
  final String phoneNumber;
  final String messageBody;
  final MessageStatus status;
  final String? providerMessageId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? sentAt;

  OutboundMessage({
    required this.id,
    this.userId,
    this.bookingId,
    this.channel = 'SMS',
    required this.phoneNumber,
    required this.messageBody,
    this.status = MessageStatus.queued,
    this.providerMessageId,
    this.errorMessage,
    required this.createdAt,
    this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookingId': bookingId,
      'channel': channel,
      'phoneNumber': phoneNumber,
      'messageBody': messageBody,
      'status': status.name,
      'providerMessageId': providerMessageId,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    };
  }

  factory OutboundMessage.fromMap(String id, Map<String, dynamic> map) {
    return OutboundMessage(
      id: id,
      userId: map['userId'],
      bookingId: map['bookingId'],
      channel: map['channel'] ?? 'SMS',
      phoneNumber: map['phoneNumber'] ?? '',
      messageBody: map['messageBody'] ?? '',
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.queued,
      ),
      providerMessageId: map['providerMessageId'],
      errorMessage: map['errorMessage'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      sentAt: (map['sentAt'] as Timestamp?)?.toDate(),
    );
  }
}
