# Changes

## Docs, demo mode and two fixes

1. New README with a hero picture, a tour of the passenger, conductor and admin screens, two diagrams and an honest list of known issues.
2. New guides: Demo mode, Using the app, Fixing problems and Questions and answers, next to the existing Setup and Architecture guides.
3. **Demo mode:** run the real app against the Firebase emulators with 40 routes, 12,000 trips, demo accounts and bookings, with no Firebase project or card. It adds `demo/`, an emulator section in `firebase.json`, and an off-by-default `USE_FIREBASE_EMULATORS` flag in `lib/main.dart`.
4. **Fixed:** the app did not compile on the latest Flutter, because `app_theme.dart` used `CupertinoPageTransitionsBuilder` without importing Cupertino.
5. **Security fix:** a hidden debug login that signed in as admin, conductor or user with the password `123456` was part of release builds. It is now debug-only.
6. A Checks workflow, CONTRIBUTING, SECURITY and issue and pull request templates.

## Setup and architecture documentation (October 2026)

1. The README was rewritten, and the Setup guide and the Architecture guide were added.

## Web payments (February 2026)

1. Fixed Stripe Checkout CORS on the web by adding a Vercel function.
2. Expanded and stabilised the integration tests.

## Admin, refunds and favourites (January 2026)

1. Admin screens recover the user profile, show real emails and search across all refund statuses.
2. A rebuilt favourites system that saves routes, with animations, and favourites on the home screen and ticket.
3. Dynamic travel insights and analytics, a month picker, and the refund details with the passenger's email.
4. Notifications with preferences, FCM push messages and automated SMS.
5. A conductor location permission flow, live tracking improvements, and secure credentials moved to `.env`.
6. Sprints 3 and 6: analytics, refunds and Stripe, booking management, and Vercel automation.
7. Localisation, lint clean-up and Patrol automated tests.

## Conductor, bulk booking and admin tools (December 2025 and early January 2026)

1. Bulk booking, route management for admins, a persistent preview mode, and a refactored conductor dashboard with logout and fixed offline booking.
2. Four-digit short ticket codes, optimistic conductor updates, and visual polish with Sri Lanka Transport Board pictures.
3. A 12 hour buffer in My Trips, sorted trips, dark mode fixes and a better search button.
