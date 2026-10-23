# Data and rules

What BusLink keeps in its database, who is allowed to read and change each part, and which scripts fill it. For the story of how a booking moves through it, see [How everything fits](How%20everything%20fits.md).

## On this page

* [The collections](#the-collections)
* [Who can do what](#who-can-do-what)
* [A rule that is not there yet](#a-rule-that-is-not-there-yet)
* [Indexes](#indexes)
* [Roles](#roles)
* [The scripts that fill the database](#the-scripts-that-fill-the-database)
* [Deploying the rules](#deploying-the-rules)

## The collections

| Collection | One document is | Key fields |
|---|---|---|
| `users/{uid}` | A person | `role`, `email`, `displayName`. Has a subcollection `favorite_routes` |
| `routes` | A city-to-city line | `originCity`, `destinationCity`, `via`, `stops[]`, `distanceKm`, `estimatedDurationMins`, `isActive` |
| `schedules` | A bus on a route, weekly | `routeId`, `busNumber`, `operatorName`, `busType`, `recurrenceDays[]`, `departureTime`, `basePrice`, `totalSeats`, `conductorId` |
| `trips` | One run on one date | `scheduleId`, `date`, `originCity`, `destinationCity`, `departureDateTime`, `arrivalDateTime`, `price`, `status`, `delayMinutes`, `totalSeats`, `bookedSeatNumbers[]`, `blockedSeats[]`, `conductorId`, `via` |
| `tickets` | A booking | `userId`, `tripId`, `seatNumbers[]`, `status`, `totalAmount`, `paymentIntentId`, `shortId`, `tripData{}`, and once boarded `boardedAt`, `boardedBy` |
| `refunds` | A refund request | `status` (pending, approved, rejected, processed, failed), `ticketId`, `userId`, `refundAmount` |
| `refund_transactions` | An admin record of a refund sent to Stripe | `status` (pending, success, failed) |
| `notifications` | A message to one person | `userId`, type |
| `feedback` | A message to the admins | text |
| `outbound_messages` | A queued text message | `status` (queued, sent, delivered, failed) |

`recurrenceDays` uses 1 for Monday up to 7 for Sunday. A ticket's `tripData` is a copy of the trip as it was when booked, so the ticket still reads correctly if the trip changes.

A ticket's `status` starts as `pending` when the seats are reserved, becomes `confirmed` after payment, and may later become `cancelled` or `refunded`. **Boarded is not a status.** A boarded ticket is one that has a `boardedAt` time, and the admin screens show it as the **Boarded** chip.

## Who can do what

These are the rules in `firestore.rules`.

| Collection | Read | Create | Update | Delete |
|---|---|---|---|---|
| `users/{uid}` | The person, or an admin | The person, only as a customer. An admin may create any role | The person, but never their own `role`. An admin may change anything | Admin |
| `users/{uid}/...` | The person, or an admin | The person, or an admin | The person, or an admin | The person, or an admin |
| `routes`, `schedules` | Anyone | Admin | Admin | Admin |
| `trips` | Anyone | Admin | Admin or conductor. Any signed-in user may change **only** `bookedSeatNumbers` and `blockedSeats` (that is how a booking reserves seats) | Admin |
| `tickets` | The owner, a conductor or an admin | The signed-in user, for themselves | Conductor or admin | Nobody |
| `refunds` | The owner, or an admin | The signed-in user, for themselves | Admin | Nobody |
| `refund_transactions` | Admin | Admin | Admin | Admin |
| `notifications` | The owner, or an admin | The owner for themselves, or an admin for anyone | The owner, or an admin | Nobody |
| `feedback` | Admin | Any signed-in user | Nobody | Nobody |

Anything not listed is refused.

Two points to know:

* **A conductor can change any field of a ticket.** That is how boarding is saved, but it is wider than it needs to be. `firestore.rules.proposed` narrows boarding so it can be stamped once. See [Security](../SECURITY.md#the-proposed-boarding-rule).
* **An admin is a person whose `role` is `admin`,** or whose email is the one written into the rules. That email is a leftover from early development and is on the list in [Security](../SECURITY.md#what-still-needs-doing-before-real-money).

## A rule that is not there yet

There is no rule for `outbound_messages`, so the database refuses every read and write to it from the app. The code that queues text messages will fail against these rules until a rule is added. The text message feature opens the phone's own messaging app instead, so nothing visible breaks, but the queue is not recorded.

## Indexes

`firestore.indexes.json` holds one index: tickets by `userId` and then `bookingTime`, newest first. It makes My Trips load a person's tickets in order. Deploy it with the rules.

## Roles

| Role | Lands on | Can |
|---|---|---|
| `customer` (the default) | The passenger screens | Book, pay, view their tickets, ask for refunds |
| `conductor` | The conductor dashboard | Everything a passenger can, plus check tickets, approve boarding, report delays, change trip status |
| `admin` | The admin dashboard | Everything, plus trips, routes, bookings, refunds, roles, reports, feedback |

The app watches the signed-in person's `role` live, so a change shows up without signing out. To change a role, edit `users/{uid}.role` in the Firebase console, or use **Roles** in the admin menu.

## The scripts that fill the database

They live in `scripts/`, use the Firebase Admin SDK and need a `service-account.json` next to them. That file is a secret and is never committed.

| Script | What it does |
|---|---|
| `seed_master_data.js` | Creates routes and schedules |
| `generate_trips.js` | Creates trips for the next 30 days from the schedules. Run it again from time to time |
| `migrate.js` | Moves older data into the current shape |
| `patch_routes.js` | One-off fixes to routes |

```bash
cd scripts
npm install
node seed_master_data.js
node generate_trips.js
```

## Deploying the rules

The rules do nothing until you deploy them:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

After a change, sign in as a passenger and check that you can still book, and that you cannot open the admin screens. See also [Deploying](Deploying.md#deploy-the-database-rules).
