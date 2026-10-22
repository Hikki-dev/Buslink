import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

enum BoardingStatus { recorded, alreadyBoarded, notFound, cancelled, failed }

/// Outcome of trying to check a passenger in.
class BoardingResult {
  final BoardingStatus status;

  /// When the ticket was (or has just been) checked in.
  final DateTime? boardedAt;

  const BoardingResult(this.status, {this.boardedAt});

  bool get isRecorded => status == BoardingStatus.recorded;
}

/// The rule for "may this ticket board now?", on its own so it can be tested
/// without a database. [ticket] is the ticket document's data, or null if the
/// ticket does not exist. The Firestore transaction in
/// `FirestoreService.recordBoarding` calls this on the freshly read ticket, so
/// two conductors scanning at the same moment cannot both succeed.
BoardingResult decideBoarding(Map<String, dynamic>? ticket) {
  if (ticket == null) return const BoardingResult(BoardingStatus.notFound);
  if (ticket['status'] == 'cancelled') {
    return const BoardingResult(BoardingStatus.cancelled);
  }
  final at = ticket['boardedAt'];
  if (at is Timestamp) {
    return BoardingResult(BoardingStatus.alreadyBoarded,
        boardedAt: at.toDate());
  }
  if (at is DateTime) {
    return BoardingResult(BoardingStatus.alreadyBoarded, boardedAt: at);
  }
  return const BoardingResult(BoardingStatus.recorded);
}
