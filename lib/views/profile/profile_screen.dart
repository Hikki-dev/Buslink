import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../support/support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final themeController = Provider.of<ThemeController>(context);
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const Center(
          child: Text("Please log in",
              style: TextStyle(fontFamily: 'Inter', color: Colors.grey)));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: firestoreService.getUserData(user.uid),
      builder: (context, snapshot) {
        // Default Data
        String name = user.displayName ?? "Traveller";
        String email = user.email ?? "No Email";
        String phone = user.phoneNumber ?? "No Phone Linked";
        String role = "Customer";
        String initial = name.isNotEmpty ? name[0].toUpperCase() : "T";

        // If Firestore Data Exists
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          email = data['email'] ?? email;
          phone = data['phone'] ?? phone;
          role = (data['role'] ?? "Customer").toString().toUpperCase();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Text(initial,
                                  style: const TextStyle(fontFamily: 'Outfit', 
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor)),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(name,
                            style: const TextStyle(fontFamily: 'Outfit', 
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(role,
                              style: const TextStyle(fontFamily: 'Inter', 
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 1)),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _infoRow(context, Icons.email_outlined, "Email", email),
                        _infoRow(context, Icons.phone_outlined, "Phone", phone),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Settings
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Dark Mode",
                              style: TextStyle(fontFamily: 'Inter', 
                                  fontWeight: FontWeight.w600)),
                          secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.dark_mode,
                                  color: Colors.purple)),
                          value: themeController.themeMode == ThemeMode.dark,
                          activeTrackColor: AppTheme.primaryColor,
                          onChanged: (val) {
                            themeController.setTheme(
                                val ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.blue)),
                          title: const Text("Notifications",
                              style: TextStyle(fontFamily: 'Inter', 
                                  fontWeight: FontWeight.w600)),
                          trailing: Switch(
                              value: true,
                              activeTrackColor: AppTheme.primaryColor,
                              onChanged: (v) {}),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Help & Logout
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.support_agent,
                                  color: Colors.orange)),
                          title: const Text("Help & Support",
                              style: TextStyle(fontFamily: 'Inter', 
                                  fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right,
                              size: 18, color: Colors.grey),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SupportScreen())),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child:
                                  const Icon(Icons.logout, color: Colors.red)),
                          title: const Text("Log Out",
                              style: TextStyle(fontFamily: 'Inter', 
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red)),
                          onTap: () => authService.signOut(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  Text("Version 1.0.0",
                      style: TextStyle(fontFamily: 'Inter', 
                          color: Colors.grey.shade400, fontSize: 12))
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontFamily: 'Inter', 
                        fontWeight: FontWeight.w500, fontSize: 15)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
