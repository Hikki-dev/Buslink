# Security

## Reporting a problem

Please do not open a public issue for a security problem. Use the **Report a vulnerability** button on the Security tab of this project on GitHub. Say what you found and how to repeat it.

## What this project does to protect people

1. Sign-in is done by Firebase Auth. The app never stores a password.
2. Seats are checked and held in one Firestore transaction, so a seat cannot be sold twice at the same moment.
3. `firestore.rules` limits who can read and write each collection.
4. Secrets are read from `.env`, `service-account.json` and `firebase_options.dart`, which are git-ignored.
5. A development-only login shortcut with well-known passwords exists only in debug builds (`kDebugMode`).

## Known weaknesses

These are written down so nobody deploys the project without knowing about them. They are also listed in the [README](README.md#known-issues-and-security-notes).

1. **Secrets in the client.** `STRIPE_SECRET_KEY` and `FIREBASE_SERVICE_ACCOUNT_BASE64` are read from `.env`, which is bundled into app builds and can be extracted. Use test-mode keys only.
2. **Unauthenticated refund endpoint.** `api/refund.js` allows any origin and does not check who is calling.
3. **Refund function without an admin check.** `functions/index.js` only requires a signed-in user.
4. **Role escalation.** `firestore.rules` lets a user write their own `users/{uid}`, including `role`.
5. **Hard-coded admin email** in `firestore.rules` and `lib/main.dart`.
6. **Old debug accounts.** Earlier builds had a hidden login for `admin@buslink.com`, `conductor@buslink.com` and `test@test.com` with the password `123456`. If any of these exist in your Firebase project, change their passwords or delete them.

## For people running a copy

1. Never commit `.env`, `service-account.json` or `firebase_options.dart`.
2. Use Stripe test mode until the weaknesses above are fixed.
3. Use the emulators (see [Demo mode](docs/Demo%20mode.md)) for development and screenshots.
4. Restrict your Firebase web keys in the Firebase and Google Cloud consoles.
