# Security

BusLink began as coursework. This page says plainly what is protected, what is not yet, and what to do before real money is involved.

## On this page

* [Reporting a problem](#reporting-a-problem)
* [What is protected](#what-is-protected)
* [What you must do after cloning](#what-you-must-do-after-cloning)
* [How the rules are tested](#how-the-rules-are-tested)
* [What still needs doing before real money](#what-still-needs-doing-before-real-money)

## Reporting a problem

Please do not post a security problem in a public issue. Use GitHub's **Report a vulnerability** button on the Security tab of this repository, or message [Hikki-dev](https://github.com/Hikki-dev) privately. Include what you found and how to repeat it.

## What is protected

These hold in the code in this repository, once the rules in `firestore.rules` are deployed. They are checked by automatic tests (see below).

* **Nobody picks their own role.** A person can create their own profile only as a customer, and can never change `role` afterwards. Only an admin can.
* **Passengers see only their own tickets and profile.** Conductors and admins can read tickets.
* **A passenger cannot rewrite their own ticket.** They can confirm payment and request a refund, but they cannot change who it belongs to, what it cost, which seats it covers, or whether it has boarded.
* **Seats cannot be double-booked.** Booking re-reads the trip and reserves seats in one Firestore transaction.
* **A ticket boards once, and the database enforces it.** Approving boarding checks and stamps the ticket in one transaction, and the rules only let a conductor set `boardedAt` and `boardedBy` once, as themselves. A boarding cannot be overwritten or cleared.
* **The web build holds no secrets.** `build_vercel.sh` puts only the Stripe publishable key into the web app. Card details go straight to Stripe.
* **The hidden debug login exists only in developer builds** (`kDebugMode`). It is not in release or web builds.
* **No admin credentials in the repository or README.**

## What you must do after cloning

1. **Deploy the rules, exactly as they are in the repository:** `firebase deploy --only firestore:rules`. They do nothing until you do. Do not deploy an older or hand-edited copy: a looser one leaves your database open, and a stricter one stops bookings working. See [Data and rules](docs/Data%20and%20rules.md).
2. **Use your own Firebase project and your own admin account.** If a password for your project ever appeared in a public place (an older README, a commit, a hidden login button), change it. The old demo logins used the password `123456`. If you ever created those accounts in your own project, change or delete them.
3. **Restrict the Firebase web API key** to your own domains in Google Cloud Console. See [Deploying](docs/Deploying.md#environment-variables). The same key is used by the Windows desktop build, which sends no web address, so restricting it will stop that build signing in. Use a separate key for it if you need it.
4. **Use Stripe test keys** until the list below is done.
5. **Never commit** `.env`, `service-account.json` or `lib/firebase_options.dart`.

## How the rules are tested

`tool/rules-test` runs 43 cases against `firestore.rules` in the Firebase emulator, as a passenger, a conductor, an admin and a signed-out visitor. Some cases must be allowed (booking, paying, asking for a refund, boarding a ticket) and some must be refused (becoming an admin, marking your own ticket boarded, boarding a ticket twice). They run on every pull request.

```bash
cd tool/rules-test
npm install
npm test        # needs Java
```

Change the rules only together with a test, and never deploy rules that fail it. A rules file that looks more secure can still break the app: an earlier copy in this repository refused the ticket update that confirms a payment, and would have stopped every booking.

## What still needs doing before real money

These are known and open. They are listed so nobody deploys the project without knowing.

| Problem | Why it matters | Fix |
|---|---|---|
| `STRIPE_SECRET_KEY` and `FIREBASE_SERVICE_ACCOUNT_BASE64` are read from `.env` by the **mobile and desktop** app code | Anything in `.env` is bundled into those apps and can be extracted | Move payment creation, refunds and push sending to Cloud Functions or the `api/` functions, and delete these keys from `.env` |
| Payment is confirmed by the app, not by Stripe | A passenger can set their own ticket to `confirmed` without paying, because the app does that update itself | Confirm tickets from a Stripe webhook on the server, and stop passengers changing `status` to `confirmed` |
| `api/refund.js` allows any website to call it and does not check who is calling | Anyone who finds the address could ask for refunds | Require a signed-in admin (verify the Firebase ID token) and limit the allowed origin |
| `api/checkout_session.js` allows any website to call it | Anyone can create unpaid Stripe sessions | Check the caller, and take the amount from the booking on the server instead of the request |
| `processRefund` in `functions/index.js` only checks that the caller is signed in | Any signed-in user could call it | Check that the caller is an admin, as the commented-out code intends |
| An admin email address (`admin@buslink.com`) is written into `firestore.rules` and `lib/main.dart` | Whoever controls that email is an admin, whatever their role field says | Remove it, and rely on the `role` field only |
| A conductor can still change the other fields of any ticket | A conductor could change an amount or an owner | Narrow conductor updates to the exact fields they need |
| There is no rule for `outbound_messages` | The text-message queue is refused by the database | Add a rule when the feature needs it |

The web demo avoids the first problem because its build contains no secret keys. The mobile and desktop builds do not.
