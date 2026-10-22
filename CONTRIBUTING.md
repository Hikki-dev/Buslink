# Contributing

Thank you for helping. This page explains how to make a change that is easy to accept.

## What we ask of every change

1. Never put a password, an API key, a service account or a real person's details in the code, the docs, a test or a screenshot. Secrets belong in `.env`, which is not committed.
2. Never ship a shortcut with a well-known password. Anything meant only for development goes behind `kDebugMode`.
3. Keep every role in its lane. A passenger, a conductor and an admin each get their own screens, and `firestore.rules` must back that up.
4. Anything a person reads, in the app or in the docs, should be in plain English with short sentences. Strings that a passenger sees go in `lib/l10n/*.arb` for all three languages.
5. Add or update a test when you change behaviour.

## Where things are

1. `lib/` is the app. Start with [Architecture](docs/ARCHITECTURE.md).
2. `functions/` and `api/` are the server pieces for Stripe.
3. `scripts/` makes routes, schedules and trips.
4. `demo/` is [demo mode](docs/Demo%20mode.md).
5. `docs/` is the written help, and `docs/images` holds the screenshots and diagrams.

## Running the checks

```bash
bash demo/prepare.sh        # only if you have no .env and firebase_options.dart yet
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build web --release --no-web-resources-cdn
```

The same two checks run on every pull request: no analyzer errors, and the web build compiles. `test/widget_test.dart` needs a Firebase project, so it is not part of the checks.

## Trying a change safely

Use the [demo mode](docs/Demo%20mode.md) emulators, never a real Firebase project or live Stripe keys. Seed them with `bash demo/seed.sh`.

## Taking screenshots

Take them from demo mode so no real person's data is ever in a picture.

## Sending a change

1. Make a branch.
2. Keep the change small and about one thing.
3. Run the checks.
4. Open a pull request. Say what changed, why, and how you tested it.

## Reporting a problem

Open an issue and choose the right form. Say what you expected and what happened. Never paste your `.env`, passwords or keys.
