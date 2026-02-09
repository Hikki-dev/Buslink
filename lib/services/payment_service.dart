import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class PaymentService {
  static final http.Client _client = http.Client();

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

      // MINIMUM AMOUNT CHECK (Approx $0.50 USD)
      // LKR 150 is roughly $0.50.
      if (currency.toLowerCase() == 'lkr' && amountVal < 150) {
        throw Exception("Amount must be at least LKR 150 for online payment.");
      }

      final response = await _client.post(
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
          allowsDelayedPaymentMethods: false, // Force simpler UI
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
        String message = e.toString().replaceAll("Exception: ", "");
        if (message.contains("XMLHttpRequest") ||
            message.contains("ClientException")) {
          message = "Network blocked: Please disable Ad Blockers.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
      return false;
    }
  }

  // 4. Stripe Checkout Session (Redirect Flow)
  Future<String?> createCheckoutSession({
    required String amount,
    required String currency,
    required String successUrl,
    required String cancelUrl,
    required String bookingId, // To track which booking this is for
  }) async {
    try {
      final double amountVal = double.parse(amount);
      final int amountCents = (amountVal * 100).toInt();

      if (currency.toLowerCase() == 'lkr' && amountVal < 150) {
        throw Exception("Amount must be at least LKR 150 for online payment.");
      }

      debugPrint("Creating Checkout Session... Success: $successUrl");

      // WEB: Use Vercel Serverless Function Proxy to avoid CORS
      if (kIsWeb) {
        // 1. Determine API Base URL
        // 1. Determine API Base URL
        String apiBase = Uri.base.origin; // e.g. https://buslink-eta.vercel.app

        if (Uri.base.host.contains('localhost') ||
            Uri.base.host.contains('127.0.0.1')) {
          // Debugging locally: Point to Production API
          apiBase = 'https://buslink-eta.vercel.app';
          debugPrint("Running on Localhost: redirecting API calls to $apiBase");
        }

        final uri = Uri.parse('$apiBase/api/checkout_session');

        try {
          debugPrint("Calling Backend API: $uri");
          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amountCents,
              'currency': currency.toLowerCase(),
              'bookingId': bookingId,
              'successUrl': successUrl,
              'cancelUrl': cancelUrl,
            }),
          );

          if (response.statusCode == 200) {
            try {
              final json = jsonDecode(response.body);
              return json['url'];
            } catch (e) {
              debugPrint("JSON Decode Error: ${response.body}");
              throw Exception("Invalid JSON response from server");
            }
          } else {
            // Attempt to parse error, but fallback to raw body if not JSON (e.g. 404 HTML)
            String errorMsg =
                "Failed to create session on backend (Status: ${response.statusCode})";
            try {
              final errorJson = jsonDecode(response.body);
              if (errorJson['error'] != null) errorMsg = errorJson['error'];
            } catch (_) {
              // Not JSON, probably HTML error page
              debugPrint("Backend Error Body: ${response.body}");
              if (response.statusCode == 404) {
                errorMsg =
                    "API Endpoint not found. Did you deploy the latest code to Vercel? (api/checkout_session.js)";
              }
            }
            throw Exception(errorMsg);
          }
        } catch (e) {
          debugPrint("Network/CORS Error: $e");
          if (e.toString().contains("Failed to create session")) rethrow;
          throw Exception(
              "Localhost Connection Failed. Please ensure you have DEPLOYED the backend to Vercel (vercel --prod). Error: $e");
        }
      }

      // MOBILE: Direct Call (Legacy/Existing flow)
      // Note: Ideally mobile should also use backend to hide secrets,
      // but keeping as-is to minimize regression risk on mobile per task scope.
      else {
        final stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'];
        if (stripeSecretKey == null || stripeSecretKey.isEmpty) {
          throw Exception("Missing STRIPE_SECRET_KEY in .env");
        }

        final response = await _client.post(
          Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
          headers: {
            'Authorization': 'Bearer $stripeSecretKey',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: {
            'payment_method_types[]': 'card',
            'mode': 'payment',
            'success_url': successUrl,
            'cancel_url': cancelUrl,
            'line_items[0][price_data][currency]': currency.toLowerCase(),
            'line_items[0][price_data][product_data][name]':
                'Bus Ticket Booking',
            'line_items[0][price_data][unit_amount]': amountCents.toString(),
            'line_items[0][quantity]': '1',
            'client_reference_id': bookingId,
          },
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['url'];
        } else {
          final error = jsonDecode(response.body)['error'];
          final message = error?['message'] ?? response.body;
          debugPrint("Stripe Checkout Error: $message");
          throw Exception("Stripe Checkout Error: $message");
        }
      }
    } catch (e) {
      debugPrint("Checkout Session Create Failed: $e");
      String errorMsg = e.toString();
      if (errorMsg.contains('XMLHttpRequest') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('ClientException')) {
        throw Exception(
            "Network Error: Please disable Ad Blockers or Privacy Extensions which may be blocking Stripe.");
      }
      rethrow;
    }
  }
}
