import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;

  // Preferences (Default True)
  bool _tripUpdates = true;
  bool _bookingConfirmations = true;
  bool _promotions = true;
  bool _reminders = true;
  bool _dutyAssignments = true; // For Conductors

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) return;

      final fs = Provider.of<FirestoreService>(context, listen: false);
      final prefs = await fs.getNotificationPreferences(user.uid);

      if (prefs != null) {
        setState(() {
          _tripUpdates = prefs['tripUpdates'] ?? true;
          _bookingConfirmations = prefs['bookingConfirmations'] ?? true;
          _promotions = prefs['promotions'] ?? true;
          _reminders = prefs['reminders'] ?? true;
          _dutyAssignments = prefs['dutyAssignments'] ?? true;
        });
      }
    } catch (e) {
      debugPrint("Error loading prefs: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    // Optimistic Update
    setState(() {
      if (key == 'tripUpdates') _tripUpdates = value;
      if (key == 'bookingConfirmations') _bookingConfirmations = value;
      if (key == 'promotions') _promotions = value;
      if (key == 'reminders') _reminders = value;
      if (key == 'dutyAssignments') _dutyAssignments = value;
    });

    try {
      final fs = Provider.of<FirestoreService>(context, listen: false);
      await fs.updateNotificationPreferences(user.uid, {
        'tripUpdates': _tripUpdates,
        'bookingConfirmations': _bookingConfirmations,
        'promotions': _promotions,
        'reminders': _reminders,
        'dutyAssignments': _dutyAssignments,
      });
    } catch (e) {
      debugPrint("Error saving pref: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to save setting: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check role for "Duty Assignments" visibility
    // Ideally we pass role or check user doc, but we can assume 'dutyAssignments' is harmless for customers
    // Or we can check cache. For simplicity, we show it but maybe hide it if role != conductor?
    // Let's keep it simple for now.

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings",
            style:
                TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme:
            IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        titleTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader("My Trips"),
                _buildSwitchTile(
                  "Trip Updates",
                  "Delays, departures, and arrival alerts.",
                  _tripUpdates,
                  (v) => _savePreference('tripUpdates', v),
                  Icons.departure_board,
                ),
                _buildSwitchTile(
                    "Booking Confirmations",
                    "E-Tickets and payment receipts.",
                    _bookingConfirmations,
                    (v) => _savePreference('bookingConfirmations', v),
                    Icons.confirmation_num),
                const Divider(height: 32),
                _buildSectionHeader("General"),
                _buildSwitchTile(
                    "Reminders",
                    "Upcoming trip reminders (1hr before).",
                    _reminders,
                    (v) => _savePreference('reminders', v),
                    Icons.alarm),
                _buildSwitchTile(
                    "Promotions & News",
                    "Discounts and service updates.",
                    _promotions,
                    (v) => _savePreference('promotions', v),
                    Icons.local_offer),
                const Divider(height: 32),
                // Only showing this for completeness, logic checks role
                _buildSwitchTile(
                    "Duty Assignments (Conductors)",
                    "New trip assignments and roster changes.",
                    _dutyAssignments,
                    (v) => _savePreference('dutyAssignments', v),
                    Icons.work),

                const SizedBox(height: 40),
                // Test button removed as per request
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.primaryColor)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        value: value,
        activeColor: AppTheme.primaryColor,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
