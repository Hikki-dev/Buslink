import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Something the payment server refused or could not do. [message] is already
/// in plain words and safe to show.
class PaymentApiException implements Exception {
  final String message;
  final int? status;
  PaymentApiException(this.message, {this.status});

  @override
  String toString() => message;
}

/// Talks to the payment functions in `api/`. The server works out the price,
/// asks Stripe whether a payment really happened, and is the only thing that
/// marks a ticket confirmed. This class only asks, signed in as the passenger.
class PaymentApi {
  final http.Client _client;
  final Future<String?> Function() _idToken;
  final String _base;

  PaymentApi({
    http.Client? client,
    Future<String?> Function()? idToken,
    String? apiBase,
  })  : _client = client ?? http.Client(),
        _idToken = idToken ?? _firebaseToken,
        _base = apiBase ?? defaultBase();

  // Coming back from Stripe the app has just started, so the signed-in person
  // may still be loading. Wait a moment for them rather than saying "sign in".
  static Future<String?> _firebaseToken() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ??
        await auth
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
    return user?.getIdToken();
  }

  /// The site that serves `/api`. The web app uses its own address, except
  /// when it runs on this computer, where the live site is used.
  static String defaultBase() {
    const live = 'https://buslink-eta.vercel.app';
    if (!kIsWeb) return live;
    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1') return live;
    return Uri.base.origin;
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final token = await _idToken();
    if (token == null) {
      throw PaymentApiException('Please sign in to continue.', status: 401);
    }
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_base/api/$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      throw PaymentApiException(
          'Could not reach the payment server. Check the connection (and turn off ad blockers) and try again.');
    }
    Map<String, dynamic> json = {};
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    if (response.statusCode != 200) {
      throw PaymentApiException(
        (json['error'] as String?) ??
            'The payment server could not do that (${response.statusCode}).',
        status: response.statusCode,
      );
    }
    return json;
  }

  /// The address of the Stripe Checkout page for these bookings.
  Future<String> checkoutUrl({
    required List<String> bookingIds,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final json = await _post('checkout_session', {
      'bookingIds': bookingIds,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });
    return json['url'] as String;
  }

  /// A PaymentIntent for the phone's payment sheet.
  Future<({String clientSecret, String id})> paymentIntent(
      List<String> bookingIds) async {
    final json = await _post('payment_intent', {'bookingIds': bookingIds});
    return (
      clientSecret: json['clientSecret'] as String,
      id: json['id'] as String,
    );
  }

  /// Asks the server to confirm bookings once Stripe says they were paid.
  Future<void> confirm(List<String> bookingIds,
      {String? sessionId, String? paymentIntentId}) async {
    await _post('confirm_booking', {
      'bookingIds': bookingIds,
      if (sessionId != null) 'sessionId': sessionId,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
    });
  }

  /// Sends money back to a card (admins only). [amountCents] is in cents.
  Future<String?> refund(String paymentIntentId, int amountCents) async {
    final json = await _post('refund', {
      'paymentIntentId': paymentIntentId,
      'amount': amountCents,
    });
    return json['id'] as String?;
  }
}
