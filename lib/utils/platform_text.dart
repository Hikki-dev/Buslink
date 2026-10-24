/// The boarding platform saved with a ticket or trip, or "" when none was set.
/// Old data used the word "TBD" for "not set yet"; that counts as not set.
String platformOf(Map<String, dynamic> tripData) {
  final s = (tripData['platformNumber'] ?? '').toString().trim();
  return s.toUpperCase() == 'TBD' ? '' : s;
}
