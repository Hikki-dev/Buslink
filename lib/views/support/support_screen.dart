import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Oops!",
            style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        content: Text(message,
            style: TextStyle(
                fontFamily: 'Inter',
                color: Theme.of(context).colorScheme.onSurface)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Okay",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
          )
        ],
      ),
    );
  }

  void _validateAndSubmit() {
    // 1. Validate Name
    if (_nameController.text.trim().isEmpty) {
      _showErrorPopup("Please enter your name so we know how to address you.");
      return;
    }

    // 2. Validate Email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorPopup("Please enter your email address.");
      return;
    }
    final emailRegex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(email)) {
      _showErrorPopup(
          "That doesn't look like a valid email address. Please check again.");
      return;
    }

    // 3. Validate Subject
    if (_subjectController.text.trim().isEmpty) {
      _showErrorPopup("Please verify the subject of your query.");
      return;
    }

    // 4. Validate Message
    if (_messageController.text.trim().isEmpty) {
      _showErrorPopup("Please describe your issue so we can help you.");
      return;
    }

    // Success
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        content: Text(
          "Message Sent Successfully! We'll allow you to track it soon.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Inter',
              color: Theme.of(context).colorScheme.onSurface),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Clear fields
              _nameController.clear();
              _emailController.clear();
              _subjectController.clear();
              _messageController.clear();
            },
            child: const Text("Great",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 800;

        // Common Content
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDesktop),
            const SizedBox(height: 32),

            // Layout: Desktop has Side-by-Side (FAQ + Form), Mobile has stacked
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildFAQSection(context)),
                  const SizedBox(width: 40),
                  Expanded(flex: 3, child: _buildContactForm(context)),
                ],
              )
            else ...[
              _buildFAQSection(context),
              const SizedBox(height: 32),
              _buildContactForm(context),
            ],

            const SizedBox(height: 32),
            Text("Emergency Hotlines",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildContactCard(
                    context,
                    Icons.local_police,
                    "Police Emergency",
                    "119",
                    () => launchUrl(Uri.parse("tel:119"))),
                _buildContactCard(
                    context,
                    Icons.medical_services,
                    "Suwaseriya Ambulance",
                    "1990",
                    () => launchUrl(Uri.parse("tel:1990"))),
                _buildContactCard(context, Icons.fire_truck, "Fire & Rescue",
                    "110", () => launchUrl(Uri.parse("tel:110"))),
                _buildContactCard(context, Icons.directions_bus, "NTC Hotline",
                    "1955", () => launchUrl(Uri.parse("tel:1955"))),
              ],
            ),
            const SizedBox(height: 32),
            Text("Contact Us Directly",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildContactCard(
                    context, Icons.phone, "Call Support", "+94 11 234 5678",
                    () async {
                  final Uri launchUri =
                      Uri(scheme: 'tel', path: '+94112345678');
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  }
                }),
                _buildContactCard(context, Icons.email_outlined, "Email Us",
                    "support@buslink.com", () async {
                  final Uri launchUri =
                      Uri(scheme: 'mailto', path: 'support@buslink.com');
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  }
                }),
              ],
            ),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Column(
              children: [
                const DesktopNavBar(selectedIndex: -1), // No active tab
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 40),
                            child: content,
                          ),
                        ),
                        const SizedBox(height: 60),
                        const AppFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile View
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text("Help & Support",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      color: textColor,
                      fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).cardColor,
              centerTitle: true,
              elevation: 0,
              iconTheme: IconThemeData(color: textColor),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: content,
            ),
          );
        }
      },
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Frequently Asked Questions",
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor)),
        const SizedBox(height: 16),
        _buildFAQItem(context, "How do I cancel a ticket?",
            "You can cancel your ticket from the 'My Trips' section up to 24 hours before departure."),
        _buildFAQItem(context, "Where is my refund?",
            "Refunds are processed within 5-7 business days to your original payment method."),
        _buildFAQItem(context, "Can I change my seat?",
            "Seat changes are allowed depending on availability. Please contact support."),
      ],
    );
  }

  Widget _buildContactForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2126) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Send us a message",
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildTextField("Your Name", _nameController),
              const SizedBox(height: 16),
              _buildTextField("Email Address", _emailController),
              const SizedBox(height: 16),
              _buildTextField("Subject", _subjectController),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 4,
                style: TextStyle(
                    fontFamily: 'Inter', color: textColor), // Input text color
                decoration: _inputDecoration("Describe your issue..."),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0),
                child: const Text("SEND MESSAGE",
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return TextField(
      controller: controller,
      style:
          TextStyle(fontFamily: 'Inter', color: textColor), // Input text color
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputColor = isDark ? const Color(0xFF2B2D33) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Inter', color: hintColor),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor)),
        filled: true,
        fillColor: inputColor);
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    // Header stays Red, always.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          const Icon(Icons.headset_mic_rounded, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          Text("How can we help you?",
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text("Our team is available 24/7 to assist you.",
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isDesktop ? 16 : 14,
                  color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2126) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black;
    final answerColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(question,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: textColor)),
          iconColor: textColor,
          collapsedIconColor: textColor,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer,
                  style: TextStyle(
                      fontFamily: 'Inter', color: answerColor, height: 1.5)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2126) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 250),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          title: Text(title,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: textColor)),
          subtitle: Text(subtitle,
              style: TextStyle(fontFamily: 'Inter', color: subTextColor)),
          trailing: Icon(Icons.chevron_right, size: 16, color: subTextColor),
          onTap: onTap,
        ),
      ),
    );
  }
}
