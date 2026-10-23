# How everything fits

## Overview

<p align="center"><img src="images/how-it-fits.svg" alt="Diagram of the app, Firebase, the payment functions and Stripe" width="100%"></p>

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

`main.dart` draws the start-up screen straight away, then `AppStartup` runs everything the app needs **at the same time**: the settings saved on the device, date names, the `.env` file, Firebase (with its offline cache) and "who is signed in". Only Firebase can stop the app; if it fails, there is a "We couldn't start BusLink" screen with a Try again button. Push notifications, Stripe and Google sign-in start after the first screen. The full story, and how fast it is, is in [Starting up](Starting%20up.md).

```
signed out        -> LoginScreen (email, Google, phone OTP)
signed in         -> RoleDispatcher: the role remembered on this device shows at once,
                     then users/{uid}.role is checked
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
| `tickets` | A booking | `userId`, `tripId`, `seatNumbers[]`, `status`, `totalAmount`, `paymentIntentId`, `shortId`, `tripData{}`, and once boarded `boardedAt`, `boardedBy` |
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

<p align="center"><img src="images/booking-flow.svg" alt="The six steps from picking a seat to boarding" width="100%"></p>

## Boarding flow

1. The conductor scans the QR code or types the ticket code. `TripController.verifyTicket` reads `tickets/{id}`. It returns nothing if the ticket is missing or cancelled.
2. The dashboard refuses a ticket whose trip left more than 12 hours ago, and a ticket that already has `boardedAt` ("Already boarded", with the time).
3. Otherwise it shows the ticket: passenger, seats, the 4-digit code and the seat map.
4. **Approve Boarding** calls `TripController.approveBoarding`, which calls `FirestoreService.recordBoarding`. That runs one **Firestore transaction**: read the ticket, ask `decideBoarding` (a small pure function in `lib/models/boarding_result.dart`) whether it may board, and if yes write `boardedAt` and `boardedBy`.
5. Because the read and the write are one transaction, two conductors approving at once cannot both succeed: the second sees `boardedAt` and gets "Already boarded".
6. If the write fails (for example no connection), the card stays open and says so. Nothing is shown as boarded unless it was saved.

## Tracking

`track_bus_screen.dart` shows the bus on a map from `LocationService.getBusLocationStream(tripId)`, the position the conductor's phone reports for that trip. The time left comes from `TripEta.compute`, a plain function of the departure time, the arrival time, any reported delay and the current time. City positions for the map are in `lib/data/city_coords.dart`.

## Statuses on screen

`lib/views/admin/widgets/status_chip.dart` turns a status word (`confirmed`, `cancelled`, `pending`, `delayed` and so on) into an icon, a label and a colour, so admin lists never rely on colour alone.

## Refund flow

1. The passenger files a refund request (`refunds`, status `pending`).
2. An admin reviews it in the refund screens.
3. On approval the refund is sent to Stripe, either by the Cloud Function `processRefund` (which sets the refund to `approved` and the ticket to `refunded` in one Firestore transaction) or through `api/refund.js` on web, and recorded in `refund_transactions`.

## Notifications

`notification_service.dart` handles FCM tokens, foreground and background messages and local notifications. `trip_reminder_service.dart` schedules reminders before departure. SMS is sent by opening the device SMS app with a prefilled message, and queued in `outbound_messages`.

## Localisation

`l10n.yaml` and `lib/l10n/app_{en,si,ta}.arb` generate `AppLocalizations`. `LanguageProvider` stores the chosen language.

## Known limitations

See [Security](../SECURITY.md) for the full, current list. In short: on mobile and desktop a Stripe secret key and a service account can be read from the bundled `.env`, the web refund endpoint is unauthenticated, and the refund function lacks an admin check. The web demo build contains no secrets.
