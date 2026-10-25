import 'package:flutter/foundation.dart' show debugPrint;

import 'payment_api.dart';

class StripeService {
  /// Sends money back to a card through the server (admins only; the server
  /// checks). Returns the Stripe refund id.
  static Future<String?> processRefund(String paymentIntentId, double amount,
      {PaymentApi? api}) async {
    try {
      final amountInCents = (amount * 100).round();
      final id =
          await (api ?? PaymentApi()).refund(paymentIntentId, amountInCents);
      debugPrint('Refund successful: $id');
      return id;
    } catch (e) {
      throw Exception('Stripe Refund Error: $e');
    }
  }
}
