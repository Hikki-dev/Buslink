import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/bl_colors.dart';
import '../layout/app_footer.dart';
import '../layout/desktop_navbar.dart';
import '../widgets/bl_widgets.dart';

/// "Help & Support" (mockups "Support" and "Desktop-Support").
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String? _error;

  static const _faqs = [
    (
      'How do I cancel a ticket?',
      "You can cancel your ticket from the 'My Trips' section up to 24 hours before departure."
    ),
    (
      'Where is my refund?',
      'Refunds are processed within 5-7 business days to your original payment method.'
    ),
    (
      'Can I change my seat?',
      'Seat changes are allowed depending on availability. Please contact support.'
    ),
  ];
  static const _hotlines = [
    ('Police Emergency', '119', Icons.local_police_outlined),
    ('Suwaseriya Ambulance', '1990', Icons.medical_services_outlined),
    ('Fire & Rescue', '110', Icons.fire_truck_outlined),
    ('NTC Hotline', '1955', Icons.directions_bus_outlined),
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri) && mounted) _snack('Could not start the call.');
  }

  Future<void> _mail({String? subject, String? body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@buslink.com',
      query: [
        if (subject != null) 'subject=${Uri.encodeComponent(subject)}',
        if (body != null) 'body=${Uri.encodeComponent(body)}',
      ].join('&'),
    );
    if (!await launchUrl(uri) && mounted) {
      _snack('Could not open your email app. Write to support@buslink.com.');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// The message goes out through the person's own email app, so it is only
  /// "sent" when they press send there.
  void _send() {
    final email = _email.text.trim();
    String? err;
    if (_name.text.trim().isEmpty) {
      err = 'Please enter your name so we know how to address you.';
    } else if (email.isEmpty) {
      err = 'Please enter your email address.';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      err = "That doesn't look like a valid email address. Please check again.";
    } else if (_subject.text.trim().isEmpty) {
      err = 'Please add a subject.';
    } else if (_message.text.trim().isEmpty) {
      err = 'Please describe your issue so we can help you.';
    }
    setState(() => _error = err);
    if (err != null) return;
    _mail(
      subject: _subject.text.trim(),
      body: '${_message.text.trim()}\n\n${_name.text.trim()}\n$email',
    );
  }

  Widget _faq(String q, String a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: BL.hairline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: BL.crimson,
              title: Text(q,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              children: [
                Text(a,
                    style: const TextStyle(
                        fontSize: 16, height: 1.45, color: BL.muted)),
              ],
            ),
          ),
        ),
      );

  Widget _hotline((String, String, IconData) h) => Semantics(
        button: true,
        label: 'Call ${h.$1} on ${h.$2}',
        child: InkWell(
          onTap: () => _call(h.$2),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: BL.hairline),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFDEEEE), shape: BoxShape.circle),
                  child: Icon(h.$3, color: BL.crimson, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(h.$1,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                Text(h.$2,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: BL.crimson)),
              ],
            ),
          ),
        ),
      );

  Widget _contactButtons() => Row(children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _call('+94112345678'),
              icon: const Icon(Icons.phone, size: 22),
              label: const Text('Call Support'),
              style: FilledButton.styleFrom(
                backgroundColor: BL.crimson,
                shape: const StadiumBorder(),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: () => _mail(),
              style: OutlinedButton.styleFrom(
                foregroundColor: BL.crimson,
                side: const BorderSide(color: BL.crimson, width: 2),
                shape: const StadiumBorder(),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              child: const Text('Email Us'),
            ),
          ),
        ),
      ]);

  Widget _field(String label, TextEditingController c, String hint,
      {int lines = 1, TextInputType? type}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          maxLines: lines,
          keyboardType: type,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: BL.muted),
            filled: true,
            fillColor: const Color(0xFFF5F3F4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BL.hairline, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BL.hairline, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BL.crimson, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _form() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: BL.hairline),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A660708), blurRadius: 24, offset: Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Send us a message',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _field('Your Name', _name, 'Full name'),
            const SizedBox(height: 12),
            _field('Email Address', _email, 'name@example.com',
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field('Subject', _subject, 'Refund / Booking / Other'),
            const SizedBox(height: 12),
            _field(
                'Message', _message, 'Describe your issue so we can help you.',
                lines: 4),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: Color(0xFF7F1D14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7F1D14))),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            BlPrimaryButton(
                label: 'Send message', color: BL.crimson, onTap: _send),
            const SizedBox(height: 6),
            const Text(
                'This opens your email app with the message ready to send.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: BL.muted)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final faqs = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequently Asked Questions',
            style: TextStyle(
                fontSize: isDesktop ? 22 : 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final f in _faqs) _faq(f.$1, f.$2),
      ],
    );
    final hotlines = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Emergency Hotlines',
            style: TextStyle(
                fontSize: isDesktop ? 22 : 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (isDesktop)
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final h in _hotlines) SizedBox(width: 260, child: _hotline(h)),
          ])
        else
          for (final h in _hotlines)
            Padding(
                padding: const EdgeInsets.only(bottom: 10), child: _hotline(h)),
      ],
    );

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          const BlHeader(title: 'Help & Support'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                faqs,
                const SizedBox(height: 14),
                const Text('Contact Us Directly',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _contactButtons(),
                const SizedBox(height: 22),
                hotlines,
                const SizedBox(height: 10),
                _form(),
              ],
            ),
          ),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DesktopNavBar(selectedIndex: -2),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Help & Support',
                          style: TextStyle(
                              fontSize: 34, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                faqs,
                                const SizedBox(height: 18),
                                hotlines,
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          SizedBox(
                            width: 500,
                            child: Column(
                              children: [
                                _form(),
                                const SizedBox(height: 14),
                                _contactButtons(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
