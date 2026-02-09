import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionHelper {
  /// Checks and requests location permission.
  /// Shows a rationale dialog if permissions are denied or required.
  /// Returns [true] if permission is granted, [false] otherwise.
  static Future<bool> checkAndRequestPermission(BuildContext context) async {
    if (const bool.fromEnvironment('IS_TESTING')) {
      return true; // Mock as granted for tests
    }
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
      if (context.mounted) {
        // Show "Modern" Pre-Prompt
        final bool userAgreed = await _showModernPermissionHeader(context);
        if (!userAgreed) {
          return false; // User declined our custom prompt
        }
      }

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

  static Future<bool> _showModernPermissionHeader(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(ctx).cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Image/Icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).primaryColor.withValues(alpha: 0.1),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Icon(Icons.location_on_rounded,
                      size: 64, color: Theme.of(ctx).primaryColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        "Location Access Required",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(ctx).textTheme.bodyLarge?.color),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "BusLink needs your location to track trips and provide real-time updates to passengers. Please approve access to continue.",
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(ctx).textTheme.bodyMedium?.color),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Decline"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(ctx).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Approve",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ) ??
        false;
  }
}
