# Fixing problems

Start with the line that matches what you see.

## On this page

* [Running the app](#running-the-app)
* [Signing in](#signing-in)
* [Booking and paying](#booking-and-paying)
* [Conductor screens](#conductor-screens)
* [The live demo](#the-live-demo)
* [Tests](#tests)

## Running the app

| You see | Do this |
|---|---|
| `unable to find asset .env` | Create a `.env` file in the project folder. It is listed as an asset, so the build needs it. See [Installing](Installing.md#4-create-the-env-file). |
| `DefaultFirebaseOptions` not found | Create `lib/firebase_options.dart` with `flutterfire configure`. See [Installing](Installing.md#3-connect-the-app). |
| `Missing or insufficient permissions` | The database rules are not deployed. Run `firebase deploy --only firestore:rules`. |
| No trips appear in search | There is no data yet. Run the seed scripts. See [Installing](Installing.md#6-seed-data). |
| A screen is blank after a Flutter upgrade | Use the Flutter version the project is built with, 3.38. The web build is pinned to 3.38.9 for this reason. |

## Signing in

| You see | Do this |
|---|---|
| Everyone lands on the passenger screens | The user's `role` is not exactly `admin` or `conductor`. Check it in Firestore, `users`, the user's document. |
| Google sign-in fails on Android | Add your SHA-1 fingerprints in Firebase and download `google-services.json` again. |
| Google sign-in fails on the web | Add the site's address under Authorized domains. See [Deploying](Deploying.md#sign-in-on-your-own-domain). |
| The Google button has no picture | It should always show the Google "G". The picture is bundled with the app (`assets/images/google_g.png`). If it is missing, run `flutter pub get` and rebuild. |
| Phone sign-in does not send a code | Turn on Phone sign-in in Firebase, and add your SHA-1 on Android. |

## Booking and paying

| You see | Do this |
|---|---|
| "Seat N is already booked" when continuing | Someone else just booked that seat. Pick another. This is the safety check working. |
| Payment fails on the web | Check `STRIPE_SECRET_KEY` is set in Vercel and is a test key if you use test mode. |
| Stripe says the amount is too small | Stripe needs at least about 50 US cents (around LKR 165). The app's own minimum of LKR 150 is a little too low. |
| A refund stays "In review" | An admin has not processed it yet. Admins process refunds from the refund list. |

## Conductor screens

| You see | Do this |
|---|---|
| The scanner shows an error and no camera | Camera permission is off. Allow it in the phone's settings, or type the ticket code in the box under the scanner. |
| "Ticket not found" | The code was typed wrong, or the ticket was cancelled. Check the code with the passenger. |
| "Already boarded" | The ticket was already checked in. The message shows when. This is correct: a ticket boards once. |
| "Ticket not accepted: Trip expired" | The trip left more than 12 hours ago. |
| "Could not record boarding" | No internet on the conductor's phone. The card stays open. Press **Approve Boarding** again when you are back online. |

## The live demo

| You see | Do this |
|---|---|
| A white page | Open the **Actions** tab on GitHub and look at the latest **Demo health check**. A red run means the build failed. Open the latest Vercel deployment's build log to see why. |
| The badge in the README is red | Same as above. |
| The build stops with `FIREBASE_... unbound variable` | A Vercel environment variable is missing. The message names it. See [Deploying](Deploying.md#environment-variables). |
| Sign-in works locally but not on the demo | The demo's address is missing from Firebase Authorized domains. |

## Tests

| You see | Do this |
|---|---|
| `test/widget_test.dart` fails | It is an old test that was already failing before the redesign work (it mocks Firebase in a way that no longer matches). The other test files are the ones to trust. See [Testing](Testing.md). |
| A test fails with boxes instead of letters | Load the app fonts with `loadAppFonts()` from `test/helpers/app_fonts.dart`, as the other tests do. |
