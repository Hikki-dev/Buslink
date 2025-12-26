# Stripe Payment Integration Guide

This project integrates Stripe for payments. Below is the step-by-step guide to configure the backend and environment variables required for processing real payments.

## 1. Prerequisites
- **Stripe Account**: Create one at [stripe.com](https://stripe.com).
- **Stripe API Keys**: Get your `Publishable Key` and `Secret Key` from the Stripe Dashboard > Developers > API Keys.

## 2. Front-End Configuration (Flutter)

### Environment Variables (.env)
Create or update the `.env` file in the root of your Flutter project:

```env
# Stripe Publishable Key (Visible to users)
STRIPE_PUBLISHABLE_KEY=pk_test_...

# Backend API URL (For creating PaymentIntents)
PAYMENT_API_URL=https://your-backend-api.com/create-payment-intent

# (Optional) Test Secret for Demo Mode WITHOUT Backend
STRIPE_TEST_CLIENT_SECRET=
```

### Main.dart
Ensure Stripe is initialized in your `main.dart` before `runApp`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Stripe.instance.applySettings();
  
  runApp(const MyApp());
}
```

## 3. Back-End Configuration (Required)
Stripe requires a backend to create a `PaymentIntent`. This prevents your Secret Key from being exposed in the app.

### Option A: Node.js / Firebase Cloud Functions (Recommended)
1. **Initialize Project**: `firebase init functions`
2. **Install Dependencies**: `npm install stripe`
3. **Deploy Function**:

```javascript
const functions = require('firebase-functions');
const stripe = require('stripe')('sk_test_...'); // Your Secret Key

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  try {
    const { amount, currency } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: parseInt(amount), // Amount in smallest unit (e.g., cents/cents)
      currency: currency,
    });

    res.status(200).json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```
4. **Update .env**: Set `PAYMENT_API_URL` to your deployed function URL.

### Option B: PHP (Laravel/Standard)
```php
Route::post('/create-payment-intent', function (Request $request) {
    \Stripe\Stripe::setApiKey(env('STRIPE_SECRET_KEY'));

    $paymentIntent = \Stripe\PaymentIntent::create([
        'amount' => $request->amount,
        'currency' => $request->currency,
    ]);

    return response()->json(['clientSecret' => $paymentIntent->client_secret]);
});
```

## 4. Testing
- Use Stripe Test Cards (e.g., `4242 4242 4242 4242`) to simulate successful payments.
- Check the Stripe Dashboard > Payments to see the transactions.

## 5. Security & Terms
- The app now includes a **Terms & Conditions** section on the payment screen.
- **SSL**: Ensure your backend uses HTTPS.
- **PCI Compliance**: Stripe handles the sensitive card data; never send card numbers to your own server directly.
