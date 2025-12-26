import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text("Oop!",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Okay",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
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
        title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        content: Text(
          "Message Sent Successfully! We'll allow you to track it soon.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(),
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
            child: Text("Great",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: Colors.green)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text("Contact Us Directly",
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
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
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: Text("Help & Support",
                  style: GoogleFonts.outfit(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
              leading: const BackButton(color: Colors.black),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Frequently Asked Questions",
            style:
                GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Send us a message",
            style:
                GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white,
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
                child: Text("SEND MESSAGE",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor)),
        filled: true,
        fillColor: Colors.grey.shade50);
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
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
              style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text("Our team is available 24/7 to assist you.",
              style: GoogleFonts.inter(
                  fontSize: isDesktop ? 16 : 14,
                  color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(question,
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer,
                  style: GoogleFonts.inter(
                      color: Colors.grey.shade600, height: 1.5)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 250),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
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
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle,
              style: GoogleFonts.inter(color: Colors.grey.shade500)),
          trailing:
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}
