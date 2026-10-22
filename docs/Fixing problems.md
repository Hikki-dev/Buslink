# Fixing problems

| What you see | What to do |
|---|---|
| The build fails with an error about `.env` | `.env` is a declared asset in `pubspec.yaml`, so it must exist. Create it (see the [Setup guide](SETUP.md#4-create-the-env-file)), or run `bash demo/prepare.sh` for a demo one |
| `lib/firebase_options.dart` is missing | Run `flutterfire configure`, or copy `lib/firebase_options_template.dart`. For a demo, run `bash demo/prepare.sh` |
| `CupertinoPageTransitionsBuilder` not found on a new Flutter | Fixed in `lib/utils/app_theme.dart` by importing Cupertino. Pull the latest code |
| "Failed to load font Inter" in the console | `assets/fonts/Inter-Variable.ttf` is a web page, not a font. Replace it with the real Inter from <https://rsms.me/inter/>. The app works without it |
| A blank white page on the web | Open the browser's developer tools and read the console. Most often Firebase could not start (wrong keys in `firebase_options.dart`), or `.env` is missing |
| No buses are found | There are no trips for that date. Run `node scripts/generate_trips.js` (needs `service-account.json`), or `bash demo/seed.sh` for the demo |
| "Seat is already booked" | Someone else got that seat first. Pick another |
| Payments do nothing | Stripe is not set up. Check `STRIPE_PUBLISHABLE_KEY` in `.env`. On the web the Vercel function needs `STRIPE_SECRET_KEY`, see [Stripe setup](../STRIPE_SETUP.md) |
| The weather box shows a default | `OPENWEATHER_API_KEY` is missing from `.env`. Everything else still works |
| Google sign-in fails | Enable the Google provider in Firebase Authentication, and add your SHA-1 fingerprint for Android |
| Phone sign-in fails | Enable the Phone provider, and add a test number or a billing plan in Firebase |
| Push messages do not arrive on the web | Generate a Web Push certificate and put the key in `FIREBASE_VAPID_KEY` |
| The demo says the emulator port is taken | Another program uses port 8080 or 9099. Stop it, or change the ports in `firebase.json` and in `lib/main.dart` |
| The demo seed is very slow | Restart the emulators first. They keep nothing, so a fresh start is clean |
| The demo shows the "Stay Updated" pop-up again and again | Start the app with `--dart-define=IS_TESTING=true` |
| `flutter test` fails | `test/widget_test.dart` needs Firebase. It fails without a Firebase project. `flutter analyze` is the check that works |
| `flutter pub get` changes `pubspec.lock` or `analysis_options.yaml` | Normal when your Flutter version differs. Do not commit that by accident |

## Still stuck?

Open an issue and use the **Problem** template. Say what you ran, what you expected and what happened, and paste the console text. Never paste your `.env`.
