# How it works

This page is for people who want to read or change the code. For what the app does, read [How everything fits](How%20everything%20fits.md) first.

## On this page

* [The big picture](#the-big-picture)
* [The folders](#the-folders)
* [Start-up](#start-up)
* [The layers](#the-layers)
* [How the code is made easy to test](#how-the-code-is-made-easy-to-test)
* [The pieces you will touch most](#the-pieces-you-will-touch-most)
* [Recipes](#recipes)
* [Things to know before you change something](#things-to-know-before-you-change-something)

## The big picture

One Flutter app runs on phones, the web and desktop. It talks straight to Firebase for sign-in, data and push messages. Two small server pieces exist only for things that must not run in a browser: the Vercel functions in `api/` and one Firebase Cloud Function in `functions/`, both for Stripe.

There is no separate backend to run. The rules in `firestore.rules` are the server-side protection, which is why they matter so much. See [Data and rules](Data%20and%20rules.md).

## The folders

| Folder | What is in it |
|---|---|
| `lib/` | The app |
| `lib/views/` | Screens, grouped by who uses them: `auth`, `home`, `results`, `booking`, `ticket`, `tracking`, `profile`, `settings`, `conductor`, `admin`, `analytics` and shared `layout` and `widgets` |
| `lib/controllers/` | `TripController`, the one `ChangeNotifier` for search, the selected trip and seats |
| `lib/services/` | Everything that talks to the outside: Firebase, Stripe, notifications, location, SMS |
| `lib/models/` | Plain data classes (`Trip`, `Ticket`, `RouteModel`, `Refund`, ...) and `boarding_result.dart` |
| `lib/data/` | Fixed lists: cities and their map positions |
| `lib/l10n/` | English, Sinhala and Tamil words |
| `lib/utils/` | The theme, constants and platform helpers |
| `api/` | Vercel functions: `checkout_session.js`, `refund.js` |
| `functions/` | Firebase Cloud Function `processRefund` |
| `scripts/` | Node scripts that seed and generate data |
| `test/` | The tests |
| `tool/` | Tools for the docs: the picture maker and the docs checker |
| `docs/` | The written help |
| `.github/` | Issue and pull request templates, and the checks that run on every pull request |

## Start-up

`lib/main.dart` does this, in order: read `.env`, start Firebase, turn on Firestore's offline cache, set up local notifications, then Stripe and Google Sign-In. The screen draws early from a cached profile, so the app does not sit on a blank page while Firebase finishes.

After sign-in, `RoleDispatcher` watches `users/{uid}.role` live and shows the matching home: the passenger screens, the conductor dashboard or the admin dashboard.

## The layers

```
Screens (views)  ->  TripController  ->  Services  ->  Firebase / Stripe
                          |
                       Models
```

* **Screens** show data and call the controller or a service. They hold only what the screen needs.
* **`TripController`** keeps the search results, the chosen trip and the chosen seats, and exposes `verifyTicket` and `approveBoarding`.
* **Services** are the only code that calls Firebase or Stripe. `FirestoreService` holds every database read and write, including the two safety transactions (`createPendingBooking` and `recordBoarding`).
* **Models** turn database documents into Dart objects and back (`fromMap`, `fromFirestore`, `toJson`).

## How the code is made easy to test

Much of the app's value is in small rules, so the rules are kept apart from the screens and from the database:

* **Rules as plain functions.** `decideBoarding` (can this ticket board?), `TripEta.compute` (how long is left?), `busDuration` and `seatsLevel` (how a bus card reads) take plain values and return plain values. They need no database.
* **Cards take their data as arguments.** `TicketVerifiedCard` accepts a `seatStream`, `BusLayoutWidget` accepts a `tripStream`, and `BoardingPassCard` accepts `shouldListen`. A test passes a stream and never touches Firebase.
* **Firebase objects are created lazily.** `FirestoreService` reads `FirebaseFirestore.instance` through a getter and `TripController` creates `FirebaseAuth` only when first used, so a test can build them without starting Firebase.
* **Status wording lives in one place.** `statusStyle` in `lib/views/admin/widgets/status_chip.dart` maps a status to its icon, word and colour.

When you add a rule, put it in a small function like these and test that. See [Testing](Testing.md).

## The pieces you will touch most

| Piece | File |
|---|---|
| Booking and boarding transactions | `lib/services/firestore_service.dart` |
| The boarding rule | `lib/models/boarding_result.dart` |
| Search and the selected trip | `lib/controllers/trip_controller.dart` |
| Bus card, duration, seats left | `lib/views/results/bus_list_screen.dart` |
| Seat map | `lib/views/booking/bus_layout_widget.dart` |
| My Trips card | `lib/views/booking/my_trips_screen.dart` |
| Conductor check and approve | `lib/views/conductor/conductor_dashboard.dart` |
| Scanner and typed code | `lib/views/conductor/qr_scan_screen.dart` |
| Delay dialog and trip status | `lib/views/conductor/conductor_trip_management_screen.dart` |
| Tracking map and time left | `lib/views/tracking/track_bus_screen.dart` |
| Trip form (three steps) | `lib/views/admin/admin_screen.dart` |
| Status chip and step strip | `lib/views/admin/widgets/status_chip.dart` |
| Theme and colours | `lib/utils/app_theme.dart` |

## Recipes

### Add a status

1. Add its case to `statusStyle` in `status_chip.dart` with an icon, a word and a colour.
2. Add it to the table in the [Admin guide](Admin%20guide.md#reading-the-status-chips).
3. Add a line to the test in `test/admin_visuals_test.dart`.

### Add a language

1. Copy `lib/l10n/app_en.arb` to `app_xx.arb` and translate the values.
2. Add the language to the language buttons in `lib/views/widgets/language_selector.dart`. `lib/providers/language_provider.dart` stores the chosen language code.
3. Run `flutter gen-l10n`. `generate: true` in `pubspec.yaml` also does it on every build.

### Add a rule to the database

1. Edit `firestore.rules`.
2. Check it with the Firebase rules validator or the emulator.
3. Update the table in [Data and rules](Data%20and%20rules.md#who-can-do-what).
4. Deploy it, then try the app as a passenger, a conductor and an admin. See [Contributing](../CONTRIBUTING.md#changing-the-database-rules).

### Add a screen

1. Put it under the folder for who uses it, in `lib/views/`.
2. Follow the rules in [Design](Design.md#the-rules): big targets, words with colour, plain errors, real names.
3. If it has a decision in it, make that a small function and test it.

### Change a picture in the docs

Do not edit the PNG files by hand. Change the widget, then redraw: see [Testing](Testing.md#remake-the-pictures-in-the-docs).

## Things to know before you change something

* **Seat reservation is a transaction.** If you change how seats are reserved, keep the check and the write together. Otherwise two people can get the same seat.
* **Boarding is a transaction too.** Keep the read, the `decideBoarding` call and the write in `recordBoarding` together.
* **Do not put secrets in the app.** Anything in `.env` is bundled into mobile and desktop builds. See [Security](../SECURITY.md).
* **A conductor's phone location feeds tracking.** If you change what the conductor screen sends, check the tracking screen.
* **`test/widget_test.dart` is expected to fail.** It was failing before the redesign. See [Testing](Testing.md).
