import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/language_provider.dart';
import '../../utils/app_theme.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('language')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLanguageOption(
            context,
            'English',
            'en',
            currentLang == 'en',
            languageProvider,
          ),
          const SizedBox(height: 16),
          _buildLanguageOption(
            context,
            'සිංහල (Sinhala)',
            'si',
            currentLang == 'si',
            languageProvider,
          ),
          const SizedBox(height: 16),
          _buildLanguageOption(
            context,
            'தமிழ் (Tamil)',
            'ta',
            currentLang == 'ta',
            languageProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String name, String code,
      bool isSelected, LanguageProvider provider) {
    return InkWell(
      onTap: () {
        provider.setLanguage(code);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
