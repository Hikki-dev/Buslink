# BusLink

A cross-platform **bus booking and operations platform** built with Flutter and Firebase. Passengers search trips, pick seats and pay online. Conductors scan tickets and run their trips. Admins manage routes, schedules, users, refunds and analytics.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black)
![Stripe](https://img.shields.io/badge/Payments-Stripe-635BFF?logo=stripe&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey)

## Features

### Passengers
- Sign in with email/password, Google, or **phone number (OTP)**.
- Search trips by route and date, with a weather lookup on the results list.
- Interactive **bus seat layout** showing booked seats.
- **Bulk booking** across several dates in one flow.
- Pay with **Stripe** (PaymentIntents on mobile, Checkout Sessions on web).
- **QR-code tickets**, downloadable as PDF.
- **My Trips** with travel statistics, favourite routes, and a live **track my bus** map.
- **Refund requests** with status tracking.
- Push and local notifications, and trip reminders.
- Languages: **English, Sinhala, Tamil**. Light and dark themes.

### Conductors
- Dashboard of assigned trips and trip management (status, delays, platform).
- **QR scanner** to validate passenger tickets.
- Walk-up **offline bookings** for passengers without the app.

### Admins
- Manage **routes** and **schedules**. Trips are generated from schedules.
- **User management** (roles) and **feedback** inbox.
- **Booking** list and details, and **refund** review (approve, reject, process).
- Analytics: **revenue** and **late departures**.

## Roles

Each user has a `role` on `users/{uid}`: `customer` (default), `conductor` or `admin`. `RoleDispatcher` in `lib/main.dart` routes each signed-in user to the matching home screen and listens live, so a role change applies without a restart.

## Tech stack

| Area | Choice |
|---|---|
| App | Flutter (Material 3), `provider`, `get` |
| Auth | Firebase Auth (email, Google, phone) |
| Data | Cloud Firestore with offline persistence |
| Payments | `flutter_stripe`, Stripe Checkout |
| Notifications | `firebase_messaging`, `flutter_local_notifications` |
| Maps and location | `flutter_map`, `latlong2`, `geolocator`, `google_maps_flutter` |
| Tickets | `qr_flutter`, `mobile_scanner`, `pdf`, `printing` |
| Serverless | Firebase Cloud Functions (`functions/`), Vercel functions (`api/`) |
| i18n | Flutter `gen-l10n` (`lib/l10n/*.arb`) |
| Web hosting | Vercel (`vercel.json`, `build_vercel.sh`) |

## Quick start

```bash
git clone https://github.com/Hikki-dev/Buslink.git
cd Buslink
flutter pub get
```

Then, before the first run:

1. Create `lib/firebase_options.dart` for **your** Firebase project: `flutterfire configure` (or copy `lib/firebase_options_template.dart` and fill it in). The file is git-ignored.
2. Create a `.env` file in the repo root. It is declared as an asset, so the build fails without it. Keys are listed in [docs/SETUP.md](docs/SETUP.md).
3. Deploy `firestore.rules` and `firestore.indexes.json`, and seed some trips.

```bash
flutter run             # Android / iOS
flutter run -d chrome   # Web
```

The full walkthrough is in **[docs/SETUP.md](docs/SETUP.md)**.

## Repository layout

```
lib/
├── main.dart                 # Bootstrapping, auth gate, RoleDispatcher
├── controllers/              # TripController (ChangeNotifier)
├── models/                   # Trip, Ticket, Route, Schedule, Refund, User, ...
├── services/                 # auth, firestore, payment, stripe, refund,
│                             # notification, sms, location, cache, reminders
├── providers/                # language provider
├── l10n/                     # en, si, ta
├── data/                     # city and destination data
├── utils/                    # theme, constants, platform helpers
└── views/                    # auth, home, results, booking, ticket, tracking,
                              # profile, settings, conductor, admin, analytics, ...
api/                          # Vercel functions: checkout_session.js, refund.js
functions/                    # Firebase Cloud Function: processRefund
scripts/                      # Node seeding and migration scripts
integration_test/, test/      # Flutter tests
firestore.rules, firestore.indexes.json
```

Data model, booking flow and payment flow are described in **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**. Stripe notes are in [STRIPE_SETUP.md](STRIPE_SETUP.md).

## Testing

```bash
flutter analyze
flutter test                      # unit and widget tests
./run_automated_tests.sh          # browser-driven integration run (macOS, Chrome)
```

The main end-to-end test is `integration_test/full_system_test.dart` (admin, then conductor, then passenger).

## Security notes

This project started as a coursework build and several items need hardening before real-money use. They are listed so nobody deploys it unaware:

- **Secrets in the client.** `STRIPE_SECRET_KEY` and `FIREBASE_SERVICE_ACCOUNT_BASE64` are read from `.env`, which is bundled into app builds. Anyone can extract them. Move refunds and push sending to Cloud Functions or the Vercel API, and remove these keys from `.env`.
- **Unauthenticated refund endpoint.** `api/refund.js` allows any origin and does not check who is calling.
- **Refund function has no admin check.** `functions/index.js` only requires a signed-in user (the admin check is commented out).
- **Role escalation.** `firestore.rules` lets a user write their own `users/{uid}` document, including `role`. Restrict `role` to admins.
- **Hard-coded admin email** in `firestore.rules` and `lib/main.dart`.

Never commit `.env`, `service-account.json`, or `firebase_options.dart`.

## Contributing

1. Fork and create a branch: `git checkout -b feature/my-change`
2. Run `flutter analyze` and `flutter test`
3. Open a pull request

## Author

Built by [Yusuf (Hikki-dev)](https://github.com/Hikki-dev).
