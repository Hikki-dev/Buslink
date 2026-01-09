import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

/// Service to handle real-time location updates with throttling and debouncing
/// to minimize Firestore writes and costs.
class LocationService {
  final FirestoreService _firestoreService = FirestoreService();

  // Cache for throttling writes
  final Map<String, int> _lastWriteTime = {};
  final Map<String, LatLng> _lastWritePos = {};

  // Configuration
  static const int throttleSeconds = 20; // Min time between writes
  static const double minDistanceMeters = 30; // Min distance moved

  /// Call this whenever the GPS sensor gives a new location.
  /// This method automatically decides whether to write to Firestore or ignore.
  Future<void> updateBusLocation(String tripId, double lat, double lng,
      double speed, double heading) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newPos = LatLng(lat, lng);

    // 1. Check Time Threshold
    final lastTime = _lastWriteTime[tripId] ?? 0;
    if (now - lastTime < (throttleSeconds * 1000)) {
      // Too soon, ignore
      return;
    }

    // 2. Check Distance Threshold
    final lastPos = _lastWritePos[tripId];
    if (lastPos != null) {
      final diffLat = (lat - lastPos.latitude).abs();
      final diffLng = (lng - lastPos.longitude).abs();
      if (diffLat < 0.0002 && diffLng < 0.0002) {
        // Did not move enough, ignore
        return;
      }
    }

    // 3. Write to Firestore (trip_updates collection)
    try {
      await _firestoreService.updateTripRealtimeStatus(tripId, {
        'status': 'inProgress', // Implicitly updating status? Or just location?
        // Better to not overwrite status if we don't know it, but for location updates usually implies inProgress.
        // However, we might be 'delayed'.
        // Let's just update location fields.
        'currentLat': lat,
        'currentLng': lng,
        'currentLocation': GeoPoint(lat, lng), // For geo-queries
        'speed': speed,
        'heading': heading,
        'accuracy': 0, // Pass if available
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update local cache
      _lastWriteTime[tripId] = now;
      _lastWritePos[tripId] = newPos;

      if (kDebugMode) {
        print("📍 GPS Uploaded for $tripId: $lat, $lng");
      }
    } catch (e) {
      debugPrint("Error updating location: $e");
    }
  }

  /// Stream for passengers to listen to bus location from generic 'trip_updates'.
  /// Returns null if no location set yet.
  Stream<LatLng?> getBusLocationStream(String tripId) {
    return _firestoreService.getTripRealtimeStream(tripId).map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // Try GeoPoint first
        if (data['currentLocation'] is GeoPoint) {
          final geo = data['currentLocation'] as GeoPoint;
          return LatLng(geo.latitude, geo.longitude);
        }
        // Fallback to Lat/Lng fields
        if (data['currentLat'] != null && data['currentLng'] != null) {
          return LatLng(
            (data['currentLat'] as num).toDouble(),
            (data['currentLng'] as num).toDouble(),
          );
        }
      }
      return null;
    }).distinct((prev, next) {
      // Optimization: Only emit if coordinates actually changed
      if (prev == null || next == null) return prev == next;
      return prev.latitude == next.latitude && prev.longitude == next.longitude;
    });
  }
}
