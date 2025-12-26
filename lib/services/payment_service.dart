import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  // 1. Create Payment Intent (Shared)
  Future<String?> createPaymentIntent(String amount, String currency) async {
    try {
      final backendUrl = dotenv.env['PAYMENT_API_URL'];

      if (backendUrl != null && backendUrl.isNotEmpty) {
        try {
          debugPrint("Creating PaymentIntent via Backend: $backendUrl");
          final response = await http.post(
            Uri.parse(backendUrl),
            body: {
              'amount': amount,
              'currency': currency,
            },
          );
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            return json['clientSecret'];
          } else {
            debugPrint("Backend error: ${response.body}");
          }
        } catch (e) {
          debugPrint("Network error calling backend: $e");
        }
      }

      // Fallback for Demo/Testing
      final secret = dotenv.env['STRIPE_TEST_CLIENT_SECRET'];
      if (secret != null && secret.isNotEmpty) {
        debugPrint("Using STRIPE_TEST_CLIENT_SECRET from .env");
        return secret;
      }

      debugPrint(
          "No Payment Configuration Found (API URL or Test Secret). Payment will be simulated.");
      return null;
    } catch (e) {
      debugPrint("Error creating payment intent: $e");
      return null;
    }
  }

  // 2. Mobile Payment Flow (Payment Sheet)
  Future<bool> processPaymentMobile(BuildContext context,
      {required String amount, required String currency}) async {
    try {
      String? paymentIntentClientSecret =
          await createPaymentIntent(amount, currency);

      if (paymentIntentClientSecret == null) {
        // DEMO MODE: Simulate success if no keys are configured
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text("Demo Mode: Payment Simulated (No Keys Configured)")));
        }
        return true;
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return false;
    }
  }

  // 3. Web Payment Flow (Confirm Payment with Card Element)
  Future<bool> processPaymentWeb(BuildContext context,
      {required String amount, required String currency}) async {
    try {
      String? paymentIntentClientSecret =
          await createPaymentIntent(amount, currency);

      if (paymentIntentClientSecret == null) {
        // DEMO MODE
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text("Demo Mode: Payment Simulated (No Keys Configured)")));
        }
        return true;
      }

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
              content: Text('Payment Failed: ${e.error.localizedMessage}')),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Web Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    }
  }
}
