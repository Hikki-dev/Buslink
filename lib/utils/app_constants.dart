// lib/utils/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // Fixes error in home_screen.dart
  static const List<String> cities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Jaffna',
    'Matara',
    'Anuradhapura',
    'Polonnaruwa',
    'Trincomalee',
    'Batticaloa',
    'Nuwara Eliya',
  ];

  // Fixes error in bus_details_screen.dart
  static IconData getBusFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'ac':
        return Icons.ac_unit;
      case 'wifi':
        return Icons.wifi;
      case 'power outlet':
        return Icons.power;
      case 'refreshment':
        return Icons.local_drink;
      case 'tv':
        return Icons.tv;
      default:
        return Icons.check_circle_outline;
    }
  }
}
