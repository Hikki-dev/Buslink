// lib/models/schedule_model.dart

class ScheduleModel {
  final String id;
  final String routeId; // Reference to routes collection
  final String busNumber;
  final String operatorName;
  final String busType; // e.g., 'AC', 'Luxury'
  final List<String> amenities; // e.g., ['WiFi', 'USB']
  final List<int> recurrenceDays; // 1=Mon, 7=Sun
  final String departureTime; // 24hr string "HH:mm"
  final double basePrice;
  final int totalSeats;
  final String? conductorId; // Nullable, as it might not be assigned yet

  ScheduleModel({
    required this.id,
    required this.routeId,
    required this.busNumber,
    required this.operatorName,
    required this.busType,
    required this.amenities,
    required this.recurrenceDays,
    required this.departureTime,
    required this.basePrice,
    required this.totalSeats,
    this.conductorId,
  });

  // CopyWith
  ScheduleModel copyWith({
    String? id,
    String? routeId,
    String? busNumber,
    String? operatorName,
    String? busType,
    List<String>? amenities,
    List<int>? recurrenceDays,
    String? departureTime,
    double? basePrice,
    int? totalSeats,
    String? conductorId,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      busNumber: busNumber ?? this.busNumber,
      operatorName: operatorName ?? this.operatorName,
      busType: busType ?? this.busType,
      amenities: amenities ?? this.amenities,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      departureTime: departureTime ?? this.departureTime,
      basePrice: basePrice ?? this.basePrice,
      totalSeats: totalSeats ?? this.totalSeats,
      conductorId: conductorId ?? this.conductorId,
    );
  }

  // To Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'busNumber': busNumber,
      'operatorName': operatorName,
      'busType': busType,
      'amenities': amenities,
      'recurrenceDays': recurrenceDays,
      'departureTime': departureTime,
      'basePrice': basePrice,
      'totalSeats': totalSeats,
      'conductorId': conductorId,
    };
  }

  // From Map (JSON)
  factory ScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    return ScheduleModel(
      id: id,
      routeId: map['routeId'] ?? '',
      busNumber: map['busNumber'] ?? '',
      operatorName: map['operatorName'] ?? '',
      busType: map['busType'] ?? '',
      amenities: List<String>.from(map['amenities'] ?? []),
      recurrenceDays: List<int>.from(map['recurrenceDays'] ?? []),
      departureTime: map['departureTime'] ?? '',
      basePrice: (map['basePrice'] ?? 0).toDouble(),
      totalSeats: (map['totalSeats'] ?? 0).toInt(),
      conductorId: map['conductorId'],
    );
  }
}
