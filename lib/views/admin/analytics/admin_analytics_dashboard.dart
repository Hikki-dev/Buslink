import 'package:flutter/material.dart';
import '../../../utils/bl_colors.dart';
import '../../widgets/bl_widgets.dart';
import '../layout/admin_shell.dart';
import 'late_departures_screen.dart';
import 'revenue_analytics_screen.dart';

/// Analytics (mockups "Desktop-Analytics" and "Desktop-AdminLate"): pill tabs
/// for Revenue and Late Departures.
class AdminAnalyticsDashboard extends StatefulWidget {
  const AdminAnalyticsDashboard({super.key});

  @override
  State<AdminAnalyticsDashboard> createState() =>
      _AdminAnalyticsDashboardState();
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) =>
      AdminShell(selected: 6, child: _buildPage(context));

  Widget _pill(String label, bool on, VoidCallback onTap) => Semantics(
        button: true,
        selected: on,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? BL.crimson : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: on ? BL.crimson : BL.border, width: 1.5),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : BL.ink)),
          ),
        ),
      );

  Widget _buildPage(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          if (!isDesktop) const BlHeader(title: 'Analytics'),
          Padding(
            padding: EdgeInsets.fromLTRB(
                isDesktop ? 36 : 16, isDesktop ? 32 : 16, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    Text(_tab == 0 ? 'Revenue' : 'Late Departures',
                        style: const TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800)),
                    Text(
                        _tab == 0
                            ? 'How much money the buses brought in, after refunds.'
                            : 'Punctuality Overview',
                        style: const TextStyle(fontSize: 17, color: BL.muted)),
                    const SizedBox(height: 16),
                  ],
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _pill('Revenue', _tab == 0, () => setState(() => _tab = 0)),
                    _pill('Late Departures', _tab == 1,
                        () => setState(() => _tab = 1)),
                  ]),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [RevenueAnalyticsScreen(), LateDeparturesView()],
            ),
          ),
        ],
      ),
    );
  }
}
