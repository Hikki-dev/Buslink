# Deploying

How the live web version is built and hosted, and how to do the same for your own copy. It all fits in free plans.

## On this page

* [What runs where](#what-runs-where)
* [Put the web app on Vercel](#put-the-web-app-on-vercel)
* [Environment variables](#environment-variables)
* [Deploy the database rules](#deploy-the-database-rules)
* [Sign-in on your own domain](#sign-in-on-your-own-domain)
* [Keep an eye on it](#keep-an-eye-on-it)
* [Staying inside the free limits](#staying-inside-the-free-limits)
* [Release checklist](#release-checklist)

## What runs where

| Piece | Where | Cost |
|---|---|---|
| The web app (static files) | Vercel | Free plan |
| `api/checkout_session.js` and `api/refund.js` | Vercel functions, same project | Free plan |
| Sign-in, database, push messages | Firebase (Auth, Firestore, FCM) | Free Spark plan |
| `processRefund` | Firebase Cloud Function | Needs the paid Blaze plan to deploy |
| Payments | Stripe | Test mode is free |

The demo uses everything except the Cloud Function. The web refund path goes through `api/refund.js` instead.

## Put the web app on Vercel

`vercel.json` serves the folder `build/web`, sends `/api/*` to the functions, and falls back to `index.html` so links to any screen work. `build_vercel.sh` does the build:

1. It installs **Flutter 3.38.9**. The version is pinned. An unpinned "stable" once changed under the build and left the live site blank.
2. It writes `lib/firebase_options.dart` from `lib/firebase_options_template.dart`, using the environment variables below.
3. It writes a `.env` that contains **only the Stripe publishable key**. No secret ever goes into the web build.
4. It runs `flutter build web --release`.
5. The script stops on the first error (`set -euo pipefail`), so a failed build can never replace a working site.

To set it up:

1. Import the GitHub repository into Vercel.
2. Make the **build command** run `build_vercel.sh`. The output folder, `build/web`, is already set in `vercel.json`.
3. Add the environment variables below, for both Production and Preview.
4. Deploy. Every push to a branch gets its own preview address. Merging to `main` updates the live site.

## Environment variables

| Name | What it is | Secret? |
|---|---|---|
| `FIREBASE_API_KEY_WEB` | Firebase web API key | No. It is public in any web app, but restrict it (see below) |
| `FIREBASE_APP_ID_WEB` | Firebase web app ID | No |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase sender ID | No |
| `FIREBASE_PROJECT_ID` | Firebase project ID | No |
| `FIREBASE_AUTH_DOMAIN` | `your-project.firebaseapp.com` | No |
| `FIREBASE_STORAGE_BUCKET` | Storage bucket | No |
| `FIREBASE_MEASUREMENT_ID` | Analytics ID | No |
| `STRIPE_PUBLISHABLE_KEY` | Starts with `pk_test_` in test mode | No |
| `STRIPE_SECRET_KEY` | Used only by the functions in `api/` | **Yes.** Use a `sk_test_` key |

If one of the first eight is missing, the build stops with "unbound variable" and names it.

**Restrict the Firebase web API key.** In Google Cloud Console, open APIs and Services, then Credentials, then the browser key, and limit it to your own domains (HTTP referrers). The key is not a password, but restricting it stops other sites using your quota.

## Deploy the database rules

The rules in `firestore.rules` are what keep passengers from reading each other's tickets or promoting themselves. **They do nothing until you deploy them.** They are tested on every change (see [Data and rules](Data%20and%20rules.md#testing-the-rules)); deploy the file exactly as it is in the repository.

```bash
firebase deploy --only firestore:rules
```

Check the result in the Firebase console under Firestore, then Rules. After a change, sign in as a passenger and confirm you can still book, and that you cannot open the admin screens.

## Sign-in on your own domain

Add your Vercel address (and your own domain, if you use one) in Firebase Console, Authentication, Settings, **Authorized domains**. Without it, Google sign-in shows an error on that address.

## Keep an eye on it

`.github/workflows/uptime.yml` is a tiny free job that runs every six hours (and on demand from the Actions tab). It checks two things:

1. The page loads.
2. The compiled app file `main.dart.js` exists and is larger than 1 MB. This catches a site that loads but is blank because the Flutter build failed.

The badge at the top of the [README](../README.md) shows the result. If a run fails, GitHub emails the repository owner.

## Caching and early connections

* `vercel.json` lets the browser reuse fonts, images and icons for a day (and show them while it checks for a new one for up to a week). The app itself, the page and the manifests are always checked, so a deploy shows up straight away. If you change a font or image with the same file name, people may see the old one for up to a day.
* `web/index.html` tells the browser to connect to Google's servers and fetch Firebase's scripts while the app is still downloading. The version in those lines (currently 12.7.0) should match `firebase_core_web` in `pubspec.lock`; if it drifts, nothing breaks, a little bandwidth is wasted.
* The page shows the start-up screen from its first paint. See [Starting up](Starting%20up.md).

## Staying inside the free limits

* The site is static, so visitors cost almost nothing. The only per-use cost is Firestore reads and writes, and the free daily allowance is far above demo traffic.
* The uptime job reads two files and never touches Firestore.
* Do not put a scheduled job in front of Firestore (for example a loop that reads trips every minute) on the free plan.
* Stripe test mode has no cost.

## Release checklist

Before telling anyone a release is live:

1. `flutter analyze` and `flutter test` pass (see [Testing](Testing.md)).
2. The Vercel build for the merge commit is green.
3. Open the live address. The sign-in page shows the logo, the language buttons and the red Log In button.
4. Sign in as a passenger and search a route.
5. The uptime badge is green.
6. If the rules changed, they are deployed.
