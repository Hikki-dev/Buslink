# Demo mode

Demo mode runs the **real app** on your computer with **no Firebase project, no Stripe account and no card**. It talks to the Firebase **emulators**, which are pretend copies of Firebase Auth and Cloud Firestore that run locally. It is how the screenshots in the README were taken.

## What you get

* The real app, with its real screens and its real Firestore security rules (`firestore.rules` is loaded by the emulator).
* 40 routes, 400 schedules and 12,000 trips for the next 30 days, made by the project's own seed scripts.
* Four accounts. The password for all of them is `demo-password`:

| Account | Role |
|---|---|
| `customer@buslink.demo` | Customer (Nimali Perera), with three upcoming bookings and a refund request |
| `kasun@buslink.demo` | Customer (Kasun Silva) |
| `conductor@buslink.demo` | Conductor, driving tomorrow's 8:00 Colombo to Kandy bus |
| `admin@buslink.demo` | Admin |

* Seats taken on the busiest routes, one pending refund and one processed refund, and some feedback.

What it does **not** have: payments (Stripe is switched off), weather, push messages, and map tiles in a locked-down network. Everything else works.

## What you need

* The [Flutter SDK](https://docs.flutter.dev/get-started/install).
* Node 18 or newer, and `npx`.
* Java 11 or newer. The Firestore emulator is a Java program (`java -version` shows yours).
* `openssl` and `python3`, which most computers already have.

## Run it

**1. Make the two files the app needs to build.** They are git-ignored, and this fills them with fake values. It never overwrites a file you already have.

```bash
bash demo/prepare.sh
```

**2. Start the emulators** and leave this terminal open:

```bash
npx firebase-tools emulators:start --only auth,firestore --project demo-buslink
```

The settings (ports 9099 and 8080, on `127.0.0.1`) are in `firebase.json`.

**3. Fill them with data**, in a second terminal:

```bash
bash demo/seed.sh
```

It takes about a minute. It refuses to run unless it is pointed at your own computer, because the master seed script wipes routes, schedules and trips before it writes them.

**4. Start the app:**

```bash
flutter run -d chrome \
  --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=IS_TESTING=true
```

Sign in with one of the accounts above.

## What the two flags do

| Flag | What it does |
|---|---|
| `USE_FIREBASE_EMULATORS=true` | After Firebase starts, `lib/main.dart` points Firestore and Auth at `127.0.0.1` (ports 8080 and 9099). Without the flag, nothing changes. Set `EMULATOR_HOST` too if the emulators run on another machine |
| `IS_TESTING=true` | A flag the app already had. It skips the "Stay Updated" notification pop-up, which would otherwise come back again and again |

## Good to know

* The emulators keep nothing. When you stop them, the data is gone. Start them fresh and run `demo/seed.sh` again. Running the seed on an emulator that was already seeded works but is slow, so restart the emulator first.
* The demo shows photographs (the hero picture, destination cards) loaded from Unsplash and Flickr, as the real app does. Map tiles come from OpenStreetMap. A computer that cannot reach them shows plain boxes there.
* On the web, Firebase's own JavaScript is fetched from Google's servers. On a computer with no internet it will not start.
* Never point the demo accounts at a real project. They have a known password.

## Taking your own screenshots

Run the app on the web, start the emulators and the seed, and drive the app with [Playwright](https://playwright.dev) or by hand. Flutter draws on a canvas, so turn on the accessibility tree first (click the hidden "Enable accessibility" button) to find buttons by name.
