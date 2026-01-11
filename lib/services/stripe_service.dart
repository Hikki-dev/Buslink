import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class StripeService {
  // Key now loaded from .env for security (Note: Exposed in client builds)
  static String get _secretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  static Future<String?> processRefund(
      String paymentIntentId, double amount) async {
    try {
      final amountInCents = (amount * 100).toInt();

      if (kIsWeb) {
        // WEB: Use Vercel Serverless Function Proxy to avoid CORS
        // Relative path works because the API is on the same domain
        final url = Uri.parse('/api/refund');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'paymentIntentId': paymentIntentId,
            'amount': amountInCents,
          }),
        );

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Refund failed via Proxy');
        }
        debugPrint("Refund successful (Web Proxy): ${response.body}");
        final data = jsonDecode(response.body);
        return data['id']; // Return Refund ID
      } else {
        // MOBILE/DESKTOP: Direct Call (No CORS issues)
        final url = Uri.parse('https://api.stripe.com/v1/refunds');

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $_secretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'payment_intent': paymentIntentId,
            'amount': amountInCents.toString(),
          },
        );

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          throw Exception(error['error']['message'] ?? 'Refund failed');
        }
        debugPrint("Refund successful (Direct): ${response.body}");
        final data = jsonDecode(response.body);
        return data['id']; // Return Refund ID
      }
    } catch (e) {
      throw Exception('Stripe Refund Error: $e');
    }
  }
}
