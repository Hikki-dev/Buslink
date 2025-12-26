class RouteModel {
  final String id;
  final String fromCity;
  final String toCity;
  final int departureHour;
  final int departureMinute;
  final int arrivalHour;
  final int arrivalMinute;
  final double price;
  final String operatorName;
  final String busNumber;
  final String busType;
  final String platformNumber;
  final List<String> stops;
  final List<String> features;
  final List<int> recurrenceDays; // 1 = Mon, 7 = Sun

  RouteModel({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.departureHour,
    required this.departureMinute,
    required this.arrivalHour,
    required this.arrivalMinute,
    required this.price,
    required this.operatorName,
    required this.busNumber,
    required this.busType,
    required this.platformNumber,
    required this.stops,
    required this.features,
    required this.recurrenceDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromCity': fromCity,
      'toCity': toCity,
      'departureHour': departureHour,
      'departureMinute': departureMinute,
      'arrivalHour': arrivalHour,
      'arrivalMinute': arrivalMinute,
      'price': price,
      'operatorName': operatorName,
      'busNumber': busNumber,
      'busType': busType,
      'platformNumber': platformNumber,
      'stops': stops,
      'features': features,
      'recurrenceDays': recurrenceDays,
    };
  }
}
