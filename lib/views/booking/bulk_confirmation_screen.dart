import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_view_model.dart'; // EnrichedTrip
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import 'payment_screen.dart';
import '../../utils/translations.dart';
import '../../utils/language_provider.dart';

class BulkConfirmationScreen extends StatefulWidget {
  final EnrichedTrip trip;
  const BulkConfirmationScreen({super.key, required this.trip});

  @override
  State<BulkConfirmationScreen> createState() => _BulkConfirmationScreenState();
}

class _BulkConfirmationScreenState extends State<BulkConfirmationScreen> {
  bool _isProcessing = false;

  void _processBulkBooking() async {
    setState(() => _isProcessing = true);
    final tripCtrl = Provider.of<TripController>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to continue")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // 1. Create Pending Bookings for ALL dates
      // Logic inside TripController handling loop
      final bookingIds = await tripCtrl.createPendingBookingFromState(user);

      if (bookingIds.isNotEmpty && mounted) {
        // 2. Navigate to Payment
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              bookingId: bookingIds, // Comma separated IDs
              amount: tripCtrl.calculateBulkTotal(widget.trip.price),
              trip: widget.trip,
              isBulk: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripCtrl = Provider.of<TripController>(context);
    final total = tripCtrl.calculateBulkTotal(widget.trip.price);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Provider.of<LanguageProvider>(context).currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            Translations.translate('bulk_booking_summary', languageCode),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Bus Details Card
            _buildDetailCard(
              context,
              title: Translations.translate('selected_route', languageCode),
              content: Column(
                children: [
                  _buildRow(Translations.translate('operator', languageCode),
                      widget.trip.operatorName),
                  const SizedBox(height: 8),
                  _buildRow(Translations.translate('route', languageCode),
                      "${widget.trip.fromCity} - ${widget.trip.toCity}"),
                  const SizedBox(height: 8),
                  _buildRow(Translations.translate('time', languageCode),
                      DateFormat('hh:mm a').format(widget.trip.departureTime)),
                ],
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // 2. Dates List
            _buildDetailCard(
              context,
              title:
                  "${Translations.translate('travel_dates', languageCode)} (${tripCtrl.bulkDates.length} ${Translations.translate('days', languageCode)})",
              content: Column(
                children: tripCtrl.bulkDates.map((date) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.event,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, d MMMM y').format(date),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // 3. Price Breakdown
            _buildDetailCard(
              context,
              title: Translations.translate('price_breakdown', languageCode),
              content: Column(
                children: [
                  _buildRow(
                      Translations.translate('price_per_ticket', languageCode),
                      "LKR ${widget.trip.price.toStringAsFixed(2)}"),
                  const SizedBox(height: 8),
                  _buildRow(Translations.translate('passengers', languageCode),
                      "${tripCtrl.seatsPerTrip}"),
                  const SizedBox(height: 8),
                  _buildRow(Translations.translate('total_days', languageCode),
                      "${tripCtrl.bulkDates.length}"),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Translations.translate('total_amount', languageCode),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        "LKR ${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
              isDark: isDark,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration:
            BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processBulkBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(Translations.translate('proceed_payment', languageCode),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context,
      {required String title, required Widget content, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.0)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
