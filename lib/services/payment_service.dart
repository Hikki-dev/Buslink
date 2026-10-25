import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'payment_api.dart';

/// Taking a card payment. The server works out the price and checks with
/// Stripe afterwards (see [PaymentApi]); the app never holds a Stripe secret
/// key and never decides that a payment happened.
class PaymentService {
  final PaymentApi _api;
  PaymentService({PaymentApi? api}) : _api = api ?? PaymentApi();

  /// Phone: opens Stripe's payment sheet for these bookings. Returns the
  /// PaymentIntent id when the card was charged (the server confirms the
  /// bookings from it), or null if it was cancelled or failed.
  Future<String?> processPaymentMobile(BuildContext context,
      {required List<String> bookingIds}) async {
    try {
      final intent = await _api.paymentIntent(bookingIds);

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'BusLink',
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: false, // Force simpler UI
          appearance: const stripe.PaymentSheetAppearance(
            colors: stripe.PaymentSheetAppearanceColors(
              primary: Color(0xFFD32F2F),
            ),
          ),
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();
      debugPrint('Payment sheet completed');
      return intent.id;
    } on stripe.StripeException catch (e) {
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment Failed: ${e.error.localizedMessage}')),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Payment error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  /// Web: the address of Stripe's Checkout page for these bookings.
  Future<String> createCheckoutSession({
    required List<String> bookingIds,
    required String successUrl,
    required String cancelUrl,
  }) =>
      _api.checkoutUrl(
          bookingIds: bookingIds, successUrl: successUrl, cancelUrl: cancelUrl);
}
