# Installing

How to run BusLink against your own Firebase and Stripe accounts.

## 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.38 or newer (Dart 3.x). The web deploy is pinned to 3.38.9.
- A [Firebase](https://console.firebase.google.com/) project
- A [Stripe](https://stripe.com) account (test mode is fine)
- Node.js 18+ for the seeding scripts, Cloud Functions and Vercel functions
- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup): `dart pub global activate flutterfire_cli`
- Xcode for iOS builds (macOS only)

## 2. Firebase

1. Create a project and register the platforms you need (Android, iOS, Web).
2. **Authentication > Sign-in method**: enable **Email/Password**, **Google** and **Phone**.
3. **Firestore Database**: create a database.
4. **Cloud Messaging**: enabled by default. For web push, generate a **Web Push certificate** (VAPID key).

## 3. Connect the app

```bash
flutter pub get
flutterfire configure
```

This writes `lib/firebase_options.dart` (git-ignored). Alternatively copy `lib/firebase_options_template.dart` to `lib/firebase_options.dart` and fill in your values.

Then deploy the rules and indexes from this repo:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

The rules do nothing until you deploy them, and they are tested: see [Data and rules](Data%20and%20rules.md#testing-the-rules). Deploy `firestore.rules` exactly as it is in the repository. A looser or older copy can leave your database open, and a stricter one can stop bookings working.

## 4. Create the `.env` file

`.env` is listed as an asset in `pubspec.yaml`, so **it must exist or the build fails**. It is git-ignored.

| Key | Needed for |
|---|---|
| `STRIPE_PUBLISHABLE_KEY` | Initialising Stripe (`pk_test_...`) |
| `OPENWEATHER_API_KEY` | Weather on the trip results list |
| `FIREBASE_PROJECT_ID` | FCM push sending |
| `FIREBASE_VAPID_KEY` | Web push |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Client-side FCM sending (see the warning below) |

```env
STRIPE_PUBLISHABLE_KEY=pk_test_...
OPENWEATHER_API_KEY=...
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_VAPID_KEY=...
FIREBASE_SERVICE_ACCOUNT_BASE64=...
```

> **Warning.** Everything in `.env` is bundled into the app and can be extracted. The Stripe **secret** key is deliberately not here: payments go through the server (step 5). Use a test-mode service account only. For production, move push sending to server code too (see [Security](../SECURITY.md#what-still-needs-doing-before-real-money)). Missing keys degrade the matching feature rather than crashing the whole app.

## 5. Stripe

The app never holds a Stripe secret key. Payments go through the small functions in `api/`, which run on Vercel:

- `api/checkout_session.js` (web) and `api/payment_intent.js` (phone) start a payment. The **price comes from the booking in the database**, and the caller must be signed in and own the booking.
- `api/confirm_booking.js` marks the booking confirmed, but only after asking Stripe whether it was paid.
- `api/stripe_webhook.js` lets Stripe confirm a booking itself, even if the passenger closed the page. See [Deploying](Deploying.md#the-stripe-webhook).
- `api/refund.js` sends money back to a card. Admins only.

They need `STRIPE_SECRET_KEY` and `FIREBASE_SERVICE_ACCOUNT_BASE64` as **Vercel environment variables**. The phone app uses the live site's address for them (set in `lib/services/payment_api.dart`). Currency is LKR; the app asks for at least LKR 150, and Stripe itself needs about 50 US cents (around LKR 165).

The Cloud Function `processRefund` (in `functions/`) is the older refund path and needs `STRIPE_SECRET_KEY` as a function secret or environment value.

More background in [STRIPE_SETUP.md](../STRIPE_SETUP.md).

## 6. Seed data

The app needs routes, schedules and trips. The Node scripts in `scripts/` use the Firebase Admin SDK and expect a **`service-account.json`** next to them (download from Firebase project settings > Service accounts). It is a secret: never commit it.

```bash
cd scripts
npm install
node seed_master_data.js   # routes and schedules
node generate_trips.js     # trips for the next 30 days
```

Re-run `generate_trips.js` regularly (for example with a scheduled job) to keep future trips available.

## 7. Roles

New accounts are created as `customer`. To make someone a conductor or admin, edit their document in the Firebase console: **Firestore > users > {uid} > `role`** set to `conductor` or `admin`. The app picks the change up live. Admins can also change roles from the in-app user management screen.

## 8. Platform notes

- **Android**: add your debug and release **SHA-1** to Firebase for Google and phone sign-in, then re-download `google-services.json` into `android/app/`.
- **iOS**: add `GoogleService-Info.plist` to `ios/Runner/` and the reversed client ID as a URL scheme in `Info.plist`.
- **Web**: add your domains under Authentication > Settings > Authorized domains. `cors.json` holds the Storage CORS config.

## 9. Run

```bash
flutter run             # Android / iOS
flutter run -d chrome   # Web
flutter run -d macos    # Desktop
```

## 10. Put the web build online

See [Deploying](Deploying.md): Vercel setup, every environment variable, the health check, and the free limits.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `unable to find asset .env` | Create the `.env` file (step 4). |
| `DefaultFirebaseOptions` not found | Create `lib/firebase_options.dart` (step 3). |
| No trips in search | Seed data (step 6). |
| Everyone lands on the customer screen | `role` is not exactly `admin` or `conductor` (step 7). |
| Google or phone sign-in fails on Android | Add SHA-1 and re-download `google-services.json` (step 8). |
| `Missing or insufficient permissions` | Deploy `firestore.rules` (step 3). |

## Next

* Learn the screens: [Passenger](Passenger%20guide.md), [Conductor](Conductor%20guide.md) and [Admin](Admin%20guide.md) guides.
* Something not working: [Fixing problems](Fixing%20problems.md).
