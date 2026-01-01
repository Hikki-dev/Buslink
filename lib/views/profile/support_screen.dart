import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../layout/custom_app_bar.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: Text("Support & Help",
            style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image or Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic,
                    size: 64, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 32),

            const Text("Emergency Contacts",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildContactCard(context, "Police Emergency", "119",
                Icons.local_police, Colors.blue),
            const SizedBox(height: 16),
            _buildContactCard(context, "Ambulance", "1990",
                Icons.medical_services, Colors.red),
            const SizedBox(height: 16),
            _buildContactCard(
                context, "Tourist Police", "1992", Icons.policy, Colors.orange),

            const SizedBox(height: 40),
            const Text("Customer Support",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildContactCard(context, "BusLink Support Hotline", "011-2345678",
                Icons.phone_in_talk, Colors.green),
            const SizedBox(height: 16),
            _buildContactCard(context, "Email Support", "support@buslink.com",
                Icons.email, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, String title, String contact,
      IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
                Text(contact,
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // In a real app, uses url_launcher to call
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text("Calling $contact...")));
            },
            icon: const Icon(Icons.call),
            color: Colors.green,
            style: IconButton.styleFrom(
                backgroundColor: Colors.green.withValues(alpha: 0.1)),
          )
        ],
      ),
    );
  }
}
