import 'package:latlong2/latlong.dart';

/// Approximate city-centre coordinates, used to frame the live-tracking map
/// and draw the (straight-line) route. Cities not listed simply get no route.
const Map<String, LatLng> kCityCoords = {
  'Colombo': LatLng(6.9271, 79.8612),
  'Kandy': LatLng(7.2906, 80.6337),
  'Galle': LatLng(6.0535, 80.2210),
  'Matara': LatLng(5.9549, 80.5550),
  'Jaffna': LatLng(9.6615, 80.0255),
  'Trincomalee': LatLng(8.5874, 81.2152),
  'Anuradhapura': LatLng(8.3114, 80.4037),
  'Polonnaruwa': LatLng(7.9403, 81.0188),
  'Kurunegala': LatLng(7.4863, 80.3647),
  'Negombo': LatLng(7.2008, 79.8737),
  'Batticaloa': LatLng(7.7102, 81.6924),
  'Badulla': LatLng(6.9934, 81.0550),
  'Ratnapura': LatLng(6.6828, 80.3992),
  'Nuwara Eliya': LatLng(6.9497, 80.7891),
  'Dambulla': LatLng(7.8567, 80.6518),
  'Sigiriya': LatLng(7.9570, 80.7603),
  'Ella': LatLng(6.8667, 81.0466),
  'Hikkaduwa': LatLng(6.1395, 80.1063),
  'Hambantota': LatLng(6.1246, 81.1185),
  'Kegalle': LatLng(7.2513, 80.3464),
};
