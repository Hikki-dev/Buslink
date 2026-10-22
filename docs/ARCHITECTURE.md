# Architecture

## Overview

A Flutter client talks directly to Firebase (Auth, Firestore, FCM). Two small server-side pieces handle Stripe operations that must not run in a browser: Vercel functions in `api/` and a Firebase Cloud Function in `functions/`.

```
Flutter app ──▶ Firebase Auth
     │      ──▶ Cloud Firestore  (rules in firestore.rules)
     │      ──▶ FCM / local notifications
     │      ──▶ Stripe (PaymentIntents on mobile)
     └─ web ──▶ Vercel  /api/checkout_session, /api/refund ──▶ Stripe
             Firebase Cloud Function processRefund ──▶ Stripe + Firestore
```

## App layers

| Layer | Location | Role |
|---|---|---|
| Views | `lib/views/` | Screens by area: auth, home, results, booking, ticket, tracking, profile, settings, conductor, admin, analytics |
| Controller | `lib/controllers/trip_controller.dart` | `ChangeNotifier` holding search results, selected trip and seats |
| Services | `lib/services/` | `auth`, `firestore`, `payment`, `stripe`, `refund`, `notification`, `sms`, `location`, `cache`, `trip_reminder` |
| Models | `lib/models/` | `Trip`, `Ticket`, `RouteModel`, `Schedule`, `Refund`, `RefundTransaction`, `UserModel`, `NotificationModel`, `TripEvent` |

## Start-up and routing

`main.dart` bootstraps in this order: load `.env`, initialise Firebase, enable Firestore offline persistence, set up local notifications, then Stripe and Google Sign-In. The UI renders early from a cached profile while Firebase finishes.

```
signed out        -> LoginScreen (email, Google, phone OTP)
signed in         -> RoleDispatcher, streams users/{uid}.role
   admin          -> admin screens
   conductor      -> ConductorDashboard
   customer/other -> CustomerMainScreen
```

## Firestore data model

| Collection | Purpose | Notable fields |
|---|---|---|
| `users/{uid}` | Profile and role | `role`, `email`, `displayName`; subcollection `favorite_routes` |
| `routes` | A city-to-city route | `originCity`, `destinationCity`, `via`, `stops[]`, `distanceKm`, `estimatedDurationMins`, `isActive` |
| `schedules` | Recurring timetable for a route | `routeId`, `busNumber`, `operatorName`, `busType`, `amenities[]`, `recurrenceDays[]` (1 = Mon ... 7 = Sun), `departureTime` (`HH:mm`), `basePrice`, `totalSeats`, `conductorId` |
| `trips` | One operating run on one date | `scheduleId`, `date`, `originCity`, `destinationCity`, `departureDateTime`, `arrivalDateTime`, `price`, `status`, `totalSeats`, `delayMinutes`, `bookedSeatNumbers[]`, `conductorId`, `via` |
| `tickets` | A booking | `userId`, `tripId`, `seatNumbers[]`, `status`, `totalAmount`, `paymentIntentId`, `shortId`, `tripData{}` |
| `refunds` | Refund requests | `status` (pending, approved, rejected, processed, failed), `ticketId`, `refundAmount` |
| `refund_transactions` | Admin-only audit of Stripe refunds | status (pending, success, failed) |
| `notifications` | In-app notifications | `userId`, type |
| `feedback` | User feedback | admin-readable |
| `outbound_messages` | Queue of SMS messages | status (queued, sent, delivered, failed) |

Trips are generated from schedules by `scripts/generate_trips.js`, so the live seat map on a trip (`bookedSeatNumbers`) is the source of truth for availability.

Indexes are in `firestore.indexes.json` and security rules in `firestore.rules`.

## Booking and payment flow

1. The user picks a trip and seats in the bus layout.
2. `createPendingBooking` runs a **Firestore transaction**: it re-reads the trip, checks the seats are still free, adds them to `bookedSeatNumbers` and writes a ticket with `status: 'pending'`. Two people cannot take the same seat. Bulk booking repeats this per trip under a shared `batchId`.
3. The user pays:
   - **Mobile**: a Stripe PaymentIntent is created and confirmed with the Payment Sheet.
   - **Web**: the app calls `/api/checkout_session`, which creates a Stripe Checkout Session, then redirects back to a success URL.
4. `confirmBooking` sets the ticket to `confirmed` and stores the `paymentIntentId`.
5. The ticket screen shows a QR code. The conductor scans it in `qr_scan_screen.dart`.

Conductors can also create **offline bookings** (`createOfflineBooking`) for walk-up passengers.

## Refund flow

1. The passenger files a refund request (`refunds`, status `pending`).
2. An admin reviews it in the refund screens.
3. On approval the refund is sent to Stripe, either by the Cloud Function `processRefund` (which sets the refund to `approved` and the ticket to `refunded` in one Firestore transaction) or through `api/refund.js` on web, and recorded in `refund_transactions`.

## Notifications

`notification_service.dart` handles FCM tokens, foreground and background messages and local notifications. `trip_reminder_service.dart` schedules reminders before departure. SMS is sent by opening the device SMS app with a prefilled message, and queued in `outbound_messages`.

## Localisation

`l10n.yaml` and `lib/l10n/app_{en,si,ta}.arb` generate `AppLocalizations`. `LanguageProvider` stores the chosen language.

## Known limitations

See [Security notes](../README.md#security-notes) in the README. In short: Stripe secret key and a service account are read from a client-bundled `.env`, the refund endpoint is unauthenticated, the refund function lacks an admin check, and `users/{uid}` rules allow self-edited roles.
