import 'dart:convert';

import 'package:buslink/services/payment_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

PaymentApi _api(MockClientHandler handler, {String? token = 'tok'}) =>
    PaymentApi(
      client: MockClient(handler),
      idToken: () async => token,
      apiBase: 'https://site.test',
    );

void main() {
  test('asks for a checkout page with the passenger signed in, and no price',
      () async {
    late http.Request seen;
    final api = _api((req) async {
      seen = req;
      return http.Response(jsonEncode({'url': 'https://checkout.test/s'}), 200);
    });
    final url = await api.checkoutUrl(
        bookingIds: ['a', 'b'],
        successUrl: 'https://x/ok',
        cancelUrl: 'https://x/no');
    expect(url, 'https://checkout.test/s');
    expect(seen.url.toString(), 'https://site.test/api/checkout_session');
    expect(seen.headers['Authorization'], 'Bearer tok');
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(body['bookingIds'], ['a', 'b']);
    expect(body.containsKey('amount'), isFalse); // the server decides the price
  });

  test('gets a payment intent for the phone sheet', () async {
    final api = _api((req) async => http.Response(
        jsonEncode({'clientSecret': 'pi_1_secret_x', 'id': 'pi_1'}), 200));
    final intent = await api.paymentIntent(['a']);
    expect(intent.id, 'pi_1');
    expect(intent.clientSecret, 'pi_1_secret_x');
  });

  test('confirm sends the session or payment id, nothing about being paid',
      () async {
    late Map<String, dynamic> body;
    final api = _api((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{"confirmed":1}', 200);
    });
    await api.confirm(['a'], sessionId: 'cs_1');
    expect(body, {
      'bookingIds': ['a'],
      'sessionId': 'cs_1'
    });
  });

  test('a refusal from the server comes back in its own words', () async {
    final api = _api((req) async => http.Response(
        jsonEncode({'error': 'That booking is not yours.'}), 403));
    expect(
        api.confirm(['a'], sessionId: 'cs_1'),
        throwsA(isA<PaymentApiException>()
            .having((e) => e.message, 'message', 'That booking is not yours.')
            .having((e) => e.status, 'status', 403)));
  });

  test('not signed in stops before anything is sent', () async {
    var called = false;
    final api = _api((req) async {
      called = true;
      return http.Response('{}', 200);
    }, token: null);
    await expectLater(api.confirm(['a'], sessionId: 'cs_1'),
        throwsA(isA<PaymentApiException>()));
    expect(called, isFalse);
  });

  test('a network failure becomes a friendly message', () async {
    final api = _api((req) async => throw http.ClientException('offline'));
    expect(api.confirm(['a'], sessionId: 'cs_1'),
        throwsA(isA<PaymentApiException>()));
  });
}
