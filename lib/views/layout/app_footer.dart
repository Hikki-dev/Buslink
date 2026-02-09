import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import 'package:buslink/l10n/app_localizations.dart';

//

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      color: const Color(0xFF0B090A),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _brandColumn(context)),
                    Expanded(
                        child: _linksColumn(
                            AppLocalizations.of(context)!.company,
                            [
                              AppLocalizations.of(context)!.aboutUs,
                              AppLocalizations.of(context)!.careers,
                              AppLocalizations.of(context)!.blog,
                              AppLocalizations.of(context)!.partners
                            ],
                            context)),
                    Expanded(
                        child: _linksColumn(
                            AppLocalizations.of(context)!.support,
                            [
                              AppLocalizations.of(context)!.helpCenter,
                              AppLocalizations.of(context)!.termsOfService,
                              AppLocalizations.of(context)!.privacyPolicy,
                              AppLocalizations.of(context)!.faqs
                            ],
                            context)),
                    Expanded(flex: 1, child: _contactColumn(context)),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _brandColumn(context),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 40,
                      runSpacing: 40,
                      children: [
                        _linksColumn(
                            AppLocalizations.of(context)!.company,
                            [
                              AppLocalizations.of(context)!.aboutUs,
                              AppLocalizations.of(context)!.careers,
                              AppLocalizations.of(context)!.blog,
                              AppLocalizations.of(context)!.partners
                            ],
                            context),
                        _linksColumn(
                            AppLocalizations.of(context)!.support,
                            [
                              AppLocalizations.of(context)!.helpCenter,
                              AppLocalizations.of(context)!.termsOfService,
                              AppLocalizations.of(context)!.privacyPolicy,
                              AppLocalizations.of(context)!.faqs
                            ],
                            context),
                        _contactColumn(context),
                      ],
                    )
                  ],
                ),
              const SizedBox(height: 60),
              Divider(color: Colors.grey.shade800),
              const SizedBox(height: 30),
              if (isWide)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.rightsReserved,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.grey.shade500,
                            fontSize: 14)),
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.madeWithLove,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey.shade500,
                                fontSize: 14)),
                      ],
                    )
                  ],
                )
              else
                Column(
                  children: [
                    Text(AppLocalizations.of(context)!.rightsReserved,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.grey.shade500,
                            fontSize: 14)),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.madeWithLove,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.grey.shade500,
                            fontSize: 14)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_bus, color: Colors.white, size: 30),
            SizedBox(width: 8),
            Text("BusLink",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Your smart journey starts here.",
          style: TextStyle(
              fontFamily: 'Inter', color: Colors.grey.shade400, height: 1.6),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _socialIcon(Icons.facebook),
            _socialIcon(Icons.camera_alt),
            _socialIcon(Icons.alternate_email),
          ],
        )
      ],
    );
  }

  Widget _linksColumn(String title, List<String> links, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 20),
        ...links.map((icon) => _footerLink(icon)),
      ],
    );
  }

  Widget _contactColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.contact,
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 20),
        _contactRow(Icons.email, "support@buslink.lk"),
        _contactRow(Icons.phone, "+94 11 234 5678"),
        _contactRow(Icons.location_on, "Colombo 03, Sri Lanka"),
      ],
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Inter', color: Colors.grey.shade400, fontSize: 14)),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
