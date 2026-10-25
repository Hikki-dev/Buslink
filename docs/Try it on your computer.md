# Try it on your computer

Run the whole app on your own computer, with a pretend Firebase, so you can sign in as a passenger, a conductor or an admin without making accounts or touching real data. This is how the pictures in this guide were taken.

Nothing here talks to your real Firebase project. The pretend one lives in memory and is gone when you stop it.

## On this page

* [What you need](#what-you-need)
* [Start the pretend Firebase](#start-the-pretend-firebase)
* [Fill it with people and trips](#fill-it-with-people-and-trips)
* [Run the app](#run-the-app)
* [The people to sign in as](#the-people-to-sign-in-as)
* [Taking the pictures again](#taking-the-pictures-again)
* [Good to know](#good-to-know)

## What you need

* Everything in [Installing](Installing.md), up to the point where you can run the app. You need your `lib/firebase_options.dart` and your `.env` file, but not a live database.
* The [Firebase command line tool](https://firebase.google.com/docs/cli) (`firebase`), which needs Java.
* Python 3 for the small script that fills the pretend database.

## Start the pretend Firebase

This starts only the two parts the app needs, sign-in and the database. It uses a little over half a gigabyte of memory.

```bash
firebase emulators:start --only auth,firestore --project buslink-416e1
```

Leave it running. The rules in `firestore.rules` are loaded too, so the pretend database refuses the same things the real one does.

## Fill it with people and trips

In another window:

```bash
python3 scripts/seed_emulator.py
```

It empties the pretend database first, so you can run it again whenever you want to start fresh. It adds the people below, a Colombo to Kandy route, a daily bus with platform 4, five trips, and some tickets, refunds, feedback, notifications and favourite routes, so that every screen has something to show.

## Run the app

```bash
flutter run -d chrome --dart-define=USE_EMULATOR=true
```

The flag `USE_EMULATOR=true` points sign-in and the database at the pretend Firebase on `localhost`. Without the flag, the app uses your real project as usual. A red line at the bottom of the page says when the pretend Firebase is in use.

To make a web build instead:

```bash
flutter build web --release --dart-define=USE_EMULATOR=true
```

## The people to sign in as

The password for all of them is `Test1234!`. They exist only in the pretend Firebase.

| Email | Role | What to try |
|---|---|---|
| `customer@test.local` | Passenger | Search Colombo to Kandy, choose seats, open My Trips, track the bus, ask for a refund |
| `conductor@test.local` | Conductor | Type the ticket code `K7M2`, press **Approve Boarding**, then try it again to see "Already boarded" |
| `admin@test.local` | Admin | Add a trip, look at bookings, review the pending refund, change someone's role |
| `newcomer@test.local` | Passenger with nothing yet | See the empty My Trips, Favourites and Notifications |
| `nimali@`, `kasun@`, `dilani@`, `ruwan@` `test.local` | Passengers | Fill the admin lists with other people's bookings |

Paying needs Stripe, which the pretend Firebase does not replace. To go through the payment page, put your Stripe **test** keys in `.env` as described in [Stripe setup](../STRIPE_SETUP.md), and use the test card `4242 4242 4242 4242`.

## Taking the pictures again

Every picture in the README and in these guides comes from two small tools, so they can be remade after the design changes.

* **The real app, from a browser.** The scripts in `tool/live-shots` open a build made with `USE_EMULATOR=true`, sign in as each person, click through every screen, and save a sharp picture of each one, twice as sharp as a normal screen, at computer size and at phone size. See the README in that folder.
* **The small pieces.** Cards, dialogs and states that are awkward to reach, such as "Already boarded", are drawn by the real widgets in `tool/doc_screenshots_test.dart`, at three times the sharpness. See [Testing](Testing.md#remake-the-pictures-in-the-docs).

## Good to know

* **Sign out between people**, or open a private window for each, because the app remembers who is signed in.
* **The map** on the tracking page may be grey when you are offline. The rest of the page still works.
* **Dates move.** The seed script makes trips for the coming days, so run it again on a new day.
* **It is not the live app.** Changes you make here disappear when you stop the pretend Firebase.
