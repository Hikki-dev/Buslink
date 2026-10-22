# Security

BusLink began as coursework. This page says plainly what is protected, what is not yet, and what to do before real money is involved.

## On this page

* [Reporting a problem](#reporting-a-problem)
* [What is protected](#what-is-protected)
* [What you must do after cloning](#what-you-must-do-after-cloning)
* [What still needs doing before real money](#what-still-needs-doing-before-real-money)
* [The proposed boarding rule](#the-proposed-boarding-rule)

## Reporting a problem

Please do not post a security problem in a public issue. Use GitHub's **Report a vulnerability** button on the Security tab of this repository, or message [Hikki-dev](https://github.com/Hikki-dev) privately. Include what you found and how to repeat it.

## What is protected

These hold in the code in this repository, once the rules in `firestore.rules` are deployed:

* **Nobody picks their own role.** A user can create their own profile only as a customer, and cannot change `role` afterwards. Only an admin can.
* **Passengers see only their own tickets and profile.** Conductors and admins can read tickets.
* **Seats cannot be double-booked.** Booking re-reads the trip and reserves seats in one Firestore transaction.
* **A ticket boards once.** Approving boarding checks and stamps the ticket in one Firestore transaction, so two conductors cannot both succeed.
* **The web build holds no secrets.** `build_vercel.sh` puts only the Stripe publishable key into the web app. Card details go straight to Stripe.
* **The hidden debug login exists only in developer builds** (`kDebugMode`). It is not in release or web builds.
* **No admin credentials in the repository or README.**

## What you must do after cloning

1. **Deploy the rules.** They do nothing until you do: `firebase deploy --only firestore:rules,firestore:indexes`.
2. **Use your own Firebase project and your own admin account.** Never reuse a password that appeared in an older version of the README.
3. **Restrict the Firebase web API key** to your own domains in Google Cloud Console. See [Deploying](docs/Deploying.md#environment-variables).
4. **Use Stripe test keys** until the list below is done.
5. **Never commit** `.env`, `service-account.json` or `lib/firebase_options.dart`.

## What still needs doing before real money

These are known and open. They are listed so nobody deploys the project without knowing.

| Problem | Why it matters | Fix |
|---|---|---|
| `STRIPE_SECRET_KEY` and `FIREBASE_SERVICE_ACCOUNT_BASE64` are read from `.env` by the **mobile and desktop** app code | Anything in `.env` is bundled into those apps and can be extracted | Move payment creation, refunds and push sending to Cloud Functions or the `api/` functions, and delete these keys from `.env` |
| `api/refund.js` allows any website to call it and does not check who is calling | Anyone who finds the address could ask for refunds | Require a signed-in admin (verify the Firebase ID token) and limit the allowed origin |
| `processRefund` in `functions/index.js` only checks that the caller is signed in | Any signed-in user could call it | Check that the caller is an admin, as the commented-out code intends |
| An admin email address is written into `firestore.rules` and `lib/main.dart` | Whoever controls that email is an admin, whatever their role field says | Remove it, and rely on the `role` field only |
| A conductor can update any ticket field | A conductor could change a ticket's amount or owner | Apply the proposed rule below, then narrow it further to the exact fields conductors may change |

The web demo avoids the first problem because its build contains no secret keys. The mobile and desktop builds do not.

## The proposed boarding rule

`firestore.rules.proposed` is a copy of `firestore.rules` with one change, left separate so it can be reviewed first. The current rule lets a conductor update any field of a ticket. The proposal keeps everything conductors can do today, but adds this: `boardedAt` and `boardedBy` can be set **once**, and `boardedBy` must be the conductor's own account. A boarding cannot be overwritten or cleared from a client.

To see exactly what changes:

```bash
diff firestore.rules firestore.rules.proposed
```

To adopt it, replace `firestore.rules` with the proposed file, then:

```bash
firebase deploy --only firestore:rules
```

The boarding feature works with the current rules too. The proposal only makes it harder to tamper with.
