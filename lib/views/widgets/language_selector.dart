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
      onPressed: () => showLanguageDialog(context),
    );
  }

  static void showLanguageDialog(BuildContext context) {
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

  static Widget _buildLanguageOption(
      BuildContext context, String code, String label) {
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

/// Three always-visible language buttons, so nobody has to find a globe icon.
class LanguagePills extends StatelessWidget {
  const LanguagePills({super.key});

  static const _options = [
    ('en', 'English'),
    ('si', 'සිංහල'),
    ('ta', 'தமிழ்'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: AppLocalizations.of(context)!.selectLanguage,
      child: Row(
        children: [
          for (final (code, label) in _options) ...[
            Expanded(
              child: _Pill(
                label: label,
                selected: provider.currentLocale.languageCode == code,
                color: primary,
                onTap: () => provider.changeLanguage(code),
              ),
            ),
            if (code != _options.last.$1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? color : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 18, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
