import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  // 1. Create Payment Intent (Direct via Stripe API)
  Future<String> createPaymentIntent(String amount, String currency) async {
    try {
      // 1. Try Direct Stripe API (Client-Side) - Prototype Mode
      final stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'];

      if (stripeSecretKey == null || stripeSecretKey.isEmpty) {
        throw Exception("Missing STRIPE_SECRET_KEY in .env");
      }

      debugPrint("Creating PaymentIntent via Direct Stripe API...");

      // Convert amount to smallest unit (e.g., LKR 100.00 -> 10000 cents)
      final double amountVal = double.parse(amount);
      final int amountCents = (amountVal * 100).toInt();

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'amount': amountCents.toString(),
          'currency': currency.toLowerCase(),
          'payment_method_types[]': 'card',
          // 'automatic_payment_methods[enabled]': 'true', // Optional, better for modern sheets
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['client_secret']; // Note: Snake case from Stripe API
      } else {
        final error = jsonDecode(response.body)['error'];
        final message = error?['message'] ?? response.body;
        debugPrint("Stripe API Error: $message");
        throw Exception("Stripe API Error: $message");
      }
    } catch (e) {
      debugPrint("Payment Creation Failed: $e");
      rethrow;
    }
  }

  // 2. Mobile Payment Flow (Payment Sheet)
  Future<bool> processPaymentMobile(BuildContext context,
      {required String amount, required String currency}) async {
    try {
      String paymentIntentClientSecret =
          await createPaymentIntent(amount, currency);

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: 'BusLink',
          style: ThemeMode.light,
          appearance: const stripe.PaymentSheetAppearance(
            colors: stripe.PaymentSheetAppearanceColors(
              primary: Color(0xFFD32F2F),
            ),
          ),
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();
      debugPrint("Payment Sheet Completed Successfully");
      return true;
    } on stripe.StripeException catch (e) {
      debugPrint('Stripe Error: ${e.error.localizedMessage}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment Failed: ${e.error.localizedMessage}')),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Error: $e');
      if (context.mounted) {
        // Strip "Exception:" prefix if present for cleaner UI
        final message = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  // 3. Web Payment Flow (Confirm Payment with Card Element)
  Future<bool> processPaymentWeb(BuildContext context,
      {required String amount, required String currency}) async {
    try {
      String paymentIntentClientSecret =
          await createPaymentIntent(amount, currency);

      // On Web, we assume the CardField is already rendered in the UI.
      // We explicitly confirm the payment using the method details from the CardElement.
      await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: const stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(),
        ),
      );

      return true;
    } on stripe.StripeException catch (e) {
      debugPrint('Stripe Web Error: ${e.error.localizedMessage}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment Failed: ${e.error.localizedMessage}'),
              backgroundColor: Colors.red),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Web Error: $e');
      if (context.mounted) {
        final message = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
      return false;
    }
  }
}
