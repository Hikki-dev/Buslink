// lib/models/route_model.dart

class RouteModel {
  final String id;
  final String originCity; // Renamed from fromCity
  final String destinationCity; // Renamed from toCity
  final String via; // Optional variant
  final List<String> stops; // Ordered list of stops
  final double distanceKm;
  final int estimatedDurationMins;
  final bool isActive;

  RouteModel({
    required this.id,
    required this.originCity,
    required this.destinationCity,
    this.via = '',
    required this.stops,
    required this.distanceKm,
    required this.estimatedDurationMins,
    required this.isActive,
  });

  // Compatibility Getters
  String get fromCity => originCity;
  String get toCity => destinationCity;

  // Stubs for RouteManagementScreen legacy fields
  // In real app, these should be in ScheduleModel
  double get price => 0.0;
  String get operatorName => 'Standard';
  String get busNumber => 'BUS-000';
  String get platformNumber => '1';
  int get departureHour => 8;
  int get departureMinute => 0;
  int get arrivalHour => 10;
  int get arrivalMinute => 0;
  List<int> get recurrenceDays => [1, 2, 3, 4, 5, 6, 7];
  String get busType => 'Standard';
  List<String> get features => ['AC', 'Wifi'];

  // CopyWith
  RouteModel copyWith({
    String? id,
    String? originCity,
    String? destinationCity,
    String? via,
    List<String>? stops,
    double? distanceKm,
    int? estimatedDurationMins,
    bool? isActive,
  }) {
    return RouteModel(
      id: id ?? this.id,
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      via: via ?? this.via,
      stops: stops ?? this.stops,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMins:
          estimatedDurationMins ?? this.estimatedDurationMins,
      isActive: isActive ?? this.isActive,
    );
  }

  // To Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'originCity': originCity,
      'destinationCity': destinationCity,
      'via': via,
      'stops': stops,
      'distanceKm': distanceKm,
      'estimatedDurationMins': estimatedDurationMins,
      'isActive': isActive,
    };
  }

  // From Map (JSON)
  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    return RouteModel(
      id: id,
      originCity: map['originCity'] ?? map['fromCity'] ?? '',
      destinationCity: map['destinationCity'] ?? map['toCity'] ?? '',
      via: map['via'] ?? '',
      stops: List<String>.from(map['stops'] ?? []),
      distanceKm: (map['distanceKm'] ?? 0).toDouble(),
      estimatedDurationMins: (map['estimatedDurationMins'] ?? 0).toInt(),
      isActive: map['isActive'] ?? true,
    );
  }
}
