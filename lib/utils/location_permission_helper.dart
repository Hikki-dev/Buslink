import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'language_provider.dart';
import 'package:provider/provider.dart';

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
          if (shouldRetry == true) {
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
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    return showDialog(
      context: context,
      builder: (cnx) => AlertDialog(
        title: Text(lp.translate('location_services_disabled')),
        content: Text(lp.translate('location_services_disabled_desc')),
        actions: [
          TextButton(
            child: Text(lp.translate('ok')),
            onPressed: () => Navigator.of(cnx).pop(),
          )
        ],
      ),
    );
  }

  static Future<bool?> _showPermissionRationaleDialog(
      BuildContext context) async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    return showDialog<bool>(
      context: context,
      builder: (cnx) => AlertDialog(
        icon: const Icon(Icons.location_on, size: 40, color: Colors.blue),
        title: Text(lp.translate('location_needed_title')),
        content: Text(lp.translate('location_needed_desc')),
        actions: [
          TextButton(
            child: Text(lp.translate('cancel')),
            onPressed: () => Navigator.of(cnx).pop(false),
          ),
          ElevatedButton(
            child: Text(lp.translate('allow_location')),
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
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    return showDialog(
      context: context,
      builder: (cnx) => AlertDialog(
        icon: const Icon(Icons.settings, size: 40, color: Colors.orange),
        title: Text(lp.translate('permission_denied_forever')),
        content: Text(lp.translate('permission_denied_forever_desc')),
        actions: [
          TextButton(
            child: Text(lp.translate('cancel')),
            onPressed: () => Navigator.of(cnx).pop(),
          ),
          TextButton(
            child: Text(lp.translate('open_settings')),
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
