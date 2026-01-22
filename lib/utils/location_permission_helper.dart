import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionHelper {
  /// Checks and requests location permission.
  /// Shows a rationale dialog if permissions are denied or required.
  /// Returns [true] if permission is granted, [false] otherwise.
  static Future<bool> checkAndRequestPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showLocationServiceDisabledDialog(context);
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Show rationale BEFORE requesting if we want, or request then explain.
      // The user wants "ensure it pops once again if the conductor chose not to allow location"
      // So we generally Ask. safely.

      // We can show a pre-dialog here if we want to explain WHY before system dialog
      // For now, let's request it.
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // User denied. Show Rationale and ask to try again.
        if (context.mounted) {
          final shouldRetry = await _showPermissionRationaleDialog(context);
          if (shouldRetry == true && context.mounted) {
            return checkAndRequestPermission(context); // Recursive retry
          }
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      if (context.mounted) {
        _showPermissionPermanentlyDeniedDialog(context);
      }
      return false;
    }

    // When we reach here, permissions are granted
    return true;
  }

  static Future<void> _showLocationServiceDisabledDialog(
      BuildContext context) async {
    return showDialog(
      context: context,
      builder: (cnx) => AlertDialog(
        title: Text("location_services_disabled"),
        content: Text("location_services_disabled_desc"),
        actions: [
          TextButton(
            child: Text(
              "decline",
              style: const TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(cnx).pop(),
          ),
          ElevatedButton(
            child: Text("allow_location"),
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.of(cnx).pop();
            },
          )
        ],
      ),
    );
  }

  static Future<bool?> _showPermissionRationaleDialog(
      BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (cnx) => AlertDialog(
        icon: const Icon(Icons.location_on, size: 40, color: Colors.blue),
        title: Text("location_needed_title"),
        content: Text("location_needed_desc"),
        actions: [
          TextButton(
            child: Text("cancel"),
            onPressed: () => Navigator.of(cnx).pop(false),
          ),
          ElevatedButton(
            child: Text("allow_location"),
            onPressed: () {
              Navigator.of(cnx).pop(true);
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _showPermissionPermanentlyDeniedDialog(
      BuildContext context) async {
    return showDialog(
      context: context,
      builder: (cnx) => AlertDialog(
        icon: const Icon(Icons.settings, size: 40, color: Colors.orange),
        title: Text("permission_denied_forever"),
        content: Text("permission_denied_forever_desc"),
        actions: [
          TextButton(
            child: Text("cancel"),
            onPressed: () => Navigator.of(cnx).pop(),
          ),
          TextButton(
            child: Text("open_settings"),
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.of(cnx).pop();
            },
          ),
        ],
      ),
    );
  }
}
