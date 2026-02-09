import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:buslink/l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language),
      tooltip: AppLocalizations.of(context)!.selectLanguage,
      onPressed: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.selectLanguage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, 'en', 'English'), // Simple letters
              _buildLanguageOption(context, 'si', 'Sinhala'),
              _buildLanguageOption(context, 'ta', 'Tamil'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String code, String label) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isSelected = languageProvider.currentLocale.languageCode == code;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        languageProvider.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }
}
