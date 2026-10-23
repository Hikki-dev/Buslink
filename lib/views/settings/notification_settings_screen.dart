import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save setting: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: BL.crimson)),
        );
    Widget row(String title, String sub, bool value, String key) => InkWell(
          onTap: () => _savePreference(key, !value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0E8E9)))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(sub,
                          style:
                              const TextStyle(fontSize: 15, color: BL.muted)),
                    ],
                  ),
                ),
                Semantics(
                  toggled: value,
                  label: '$title ${value ? 'on' : 'off'}',
                  child: ExcludeSemantics(
                    child: Switch(
                      value: value,
                      activeTrackColor: BL.crimson,
                      onChanged: (v) => _savePreference(key, v),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const BlHeader(title: 'Notification Settings'),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: BL.crimson))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        children: [
                          section('MY TRIPS'),
                          row(
                              'Trip Updates',
                              'Delays, departures, and arrival alerts.',
                              _tripUpdates,
                              'tripUpdates'),
                          row(
                              'Booking Confirmations',
                              'E-Tickets and payment receipts.',
                              _bookingConfirmations,
                              'bookingConfirmations'),
                          section('GENERAL'),
                          row(
                              'Reminders',
                              'Upcoming trip reminders (1hr before).',
                              _reminders,
                              'reminders'),
                          row(
                              'Promotions & News',
                              'Discounts and service updates.',
                              _promotions,
                              'promotions'),
                          section('DUTY ASSIGNMENTS (CONDUCTORS ONLY)'),
                          row(
                              'Duty Assignments',
                              'New trip assignments and roster changes.',
                              _dutyAssignments,
                              'dutyAssignments'),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
