# Testing

## On this page

* [Run the tests](#run-the-tests)
* [What runs on every pull request](#what-runs-on-every-pull-request)
* [What is covered](#what-is-covered)
* [What is not covered](#what-is-not-covered)
* [Writing a test](#writing-a-test)
* [Remake the pictures in the docs](#remake-the-pictures-in-the-docs)

## Run the tests

```bash
flutter analyze
flutter test
```

Nothing needs Firebase, Stripe or the internet. The tests build the real screens and cards from fake data.

`test/widget_test.dart` is an old test that was already failing before the redesign (it fakes Firebase in a way that no longer matches). The other files pass and are the ones to trust. Run any one on its own, for example:

```bash
flutter test test/boarding_test.dart
```

## What runs on every pull request

`.github/workflows/checks.yml` runs on every pull request and every push to `main`:

1. `python3 tool/check_docs.py`: every link and picture in the docs exists, every heading link lands on a heading, and the README links to every page in `docs/`.
2. `flutter analyze`.
3. `flutter test`, on every file in `test/` except `widget_test.dart` (see above).
4. In a second job, the Firestore rules tests (below).

It uses Flutter 3.38.9, the same version as the live site. `lib/firebase_options.dart` and `.env` are git-ignored because they hold your own keys, so the workflow creates placeholder copies. The tests only need them to exist.

Run the same three commands yourself before opening a pull request. The **Checks** badge in the README shows the result for `main`.

## The rules tests

`tool/rules-test` runs `firestore.rules` in the Firebase emulator, with 43 cases for a passenger, a conductor, an admin and a signed-out visitor. It needs Node and Java.

```bash
cd tool/rules-test
npm install
npm test
```

It runs on every pull request as the `rules` job. See [Data and rules](Data%20and%20rules.md#testing-the-rules).

## What is covered

| File | What it checks |
|---|---|
| `test/boarding_test.dart` | The boarding rule: a fresh ticket boards, a missing one is not found, an already-boarded one is refused with its time, a cancelled one cannot board. Ticket parsing. The Approve button taps and shows a spinner. |
| `test/conductor_visuals_test.dart` | The valid-ticket card (name, seats, the 4-character code), a missing code, the rejected card |
| `test/passenger_visuals_test.dart` | Bus cards (city names, times, delayed, full, cancelled, and long names on a 390 px phone), My Trips cards (when Track bus and Refund show), the seat map's spoken labels |
| `test/admin_trip_form_test.dart` | The real three-step trip form: Next blocked until required fields are filled, Back keeps text, the last step shows Save |
| `test/admin_visuals_test.dart` | Status chips and the step indicator |
| `test/delay_dialog_test.dart` | The delay dialog: quick choices, typed minutes, limits |
| `test/refund_progress_test.dart` | The Sent, In review, Decision line |
| `test/tracking_eta_test.dart` | The arrival-time and progress maths, and how a time left is written |
| `test/startup_test.dart` | The start-up runner: steps run at the same time, `after` is respected, an optional step can fail, a critical failure is reported with its name, dependent work is not started after a failure, "slow" fires only when it should, and it gives up after the limit |
| `test/splash_test.dart` | The start-up screens: the timeline of the animation, the status and slow messages, reduce motion (nothing moves), what a screen reader hears, the failure screen's button, and the whole bootstrapper journey: loading, slow, failed and Try again |
| `test/google_logo_test.dart` | The bundled Google "G" is a real, square image |

`integration_test/` holds slower, browser-driven end-to-end tests (admin, then conductor, then passenger). They need a real Firebase project. See `run_automated_tests.sh`.

## Measuring start-up speed

The tests prove the start-up rules, not how fast it feels. To measure speed, follow [Starting up](Starting%20up.md#how-to-measure-it-yourself).

## What is not covered

* **The Firestore transaction that stamps a boarding.** Its decision logic is tested on its own, but the transaction itself needs a database. Check it by hand: open the same ticket on two conductor accounts and press **Approve Boarding** on both. Exactly one should succeed.
* **Payments and refunds.** These need Stripe.
* **Push notifications and the camera scanner.** These need a real device.

## Writing a test

* Build the widget with `MaterialApp(theme: AppTheme.lightTheme, ...)`.
* Call `setUpAll(loadAppFonts)` from `test/helpers/app_fonts.dart`. Without it, every letter is a full-width box and layouts overflow in ways they never do on a phone.
* Use a phone-sized window: `tester.view.physicalSize = const Size(780, 1600); tester.view.devicePixelRatio = 2;` and `addTearDown(tester.view.reset)`.
* For things that read Firebase, pass a stream or a fake. The cards take their data as arguments (for example `TicketVerifiedCard(seatStream: ...)`) so tests do not need a database.
* `TripController` and `AuthService` create Firebase objects. Use a small subclass or a fake that implements the type, as `test/admin_trip_form_test.dart` does.

## Remake the pictures in the docs

There are two kinds of picture in `docs/images/`, and each has its own tool.

**Whole screens, taken from the running app.** The files named `passenger-…`, `conductor-…`, `admin-…`, `bulk-…` and `empty-…` (and their `-phone` twins) are real screenshots, twice as sharp as a normal screen: 3200 by 2000 pixels for the computer view and 1170 by 2532 for the phone view. The tool in `tool/live-shots` makes them. It needs [Try it on your computer](Try%20it%20on%20your%20computer.md) running first:

```bash
firebase emulators:start --only auth,firestore --project buslink-416e1
python3 scripts/seed_emulator.py
flutter build web --release --dart-define=USE_EMULATOR=true -o /tmp/bl_web
cd /tmp/bl_web && python3 -m http.server 5055      # in another window
cd tool/live-shots && npm install && node capture.js desktop passenger   # then the other scenes
python3 finish.py ../../docs/images
```

`finish.py` saves each picture as a lossless PNG, and as a very high quality JPEG only when a photo makes the PNG larger than about 1.3 MB. The scenes and the files they make are listed in the README of that folder.

**Small pieces.** The bus card, the seat map, the conductor's answers, the refund steps and the like are drawn by the real widgets, with the app's own fonts at three times the sharpness:

```bash
flutter test tool/doc_screenshots_test.dart --update-goldens
python3 tool/trim_screenshots.py
python3 tool/make_story_images.py
```

The second command needs Python with Pillow (`python3 -m pip install pillow`). It cuts the empty white space around each piece. The third makes the animated tour `journey.gif` and `social-preview.png` from the pictures above.

`tool/check_docs.py` is the checker for the written docs. It needs only Python, no packages.
