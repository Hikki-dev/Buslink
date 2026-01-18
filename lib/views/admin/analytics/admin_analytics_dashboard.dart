import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_theme.dart';
import '../../../../utils/language_provider.dart';
import 'package:provider/provider.dart';
import 'late_departures_screen.dart';
import 'revenue_analytics_screen.dart';

class AdminAnalyticsDashboard extends StatelessWidget {
  const AdminAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              Provider.of<LanguageProvider>(context).translate('analytics_hub'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Theme.of(context).cardColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(
                  text: Provider.of<LanguageProvider>(context)
                      .translate('tab_revenue')),
              Tab(
                  text: Provider.of<LanguageProvider>(context)
                      .translate('tab_late_departures')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RevenueAnalyticsScreen(),
            LateDeparturesView(), // Reusing the view from existing file
          ],
        ),
      ),
    );
  }
}
