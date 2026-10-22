# Questions and answers

Short answers. Follow the links for the long ones.

## On this page

* [Using the app](#using-the-app)
* [Running your own copy](#running-your-own-copy)
* [Money](#money)
* [Safety](#safety)

## Using the app

**Can two people book the same seat?**
No. When you continue, the app checks the seats and reserves them in one step on the server. If someone was a moment faster, you are told and can pick another seat. See [How everything fits](How%20everything%20fits.md#booking-and-payment-flow).

**Can a ticket be used twice?**
No. When a conductor approves boarding, the ticket is stamped with the time and the conductor. Showing it again is refused with "Already boarded" and the time of the first boarding.

**The passenger's phone is dead. Can they still board?**
If they know the 4-digit code on their ticket, or the ticket code, the conductor can type it in. The ticket is also in My Trips on any device they sign in to.

**What do the three language buttons do?**
They switch the whole app between English, Sinhala and Tamil. The choice is remembered.

**Why does a bus card say "Running 30 minutes late"?**
The conductor reported a delay. Passengers with a ticket also got a notification.

**Why can't I press Select on a bus?**
The bus is either cancelled or full. The button is grey, and pressing it explains which.

**What does Track bus show?**
The bus on a map, using the location the conductor's phone reports, and how long is left, from the timetable plus any delay.

**Why is there no Track bus button on my trip?**
It only appears when the bus is on its way, is running late, or leaves within three hours.

**Which emergency numbers does Support list?**
Sri Lankan numbers: Police 119, ambulance 1990, Fire and Rescue 110, NTC hotline 1955.

## Running your own copy

**Do I need to pay for anything?**
No. Firebase's free plan, Vercel's free plan and Stripe's test mode are enough. Deploying the optional `processRefund` Cloud Function needs Firebase's pay-as-you-go plan. See [Deploying](Deploying.md#what-runs-where).

**Why does the build need a `.env` file?**
It is declared as an asset in `pubspec.yaml`, so Flutter looks for it. Keep it out of Git. See [Installing](Installing.md#4-create-the-env-file).

**How do I make someone a conductor or admin?**
Change `role` on their `users` document in Firestore, or use **Roles** in the admin menu. See [Installing](Installing.md#7-roles).

**Why are there no trips?**
Trips are made from timetables by a script. See [Installing](Installing.md#6-seed-data).

**Which Flutter version?**
3.38. The web deploy is pinned to 3.38.9.

**Is there a licence?**
Not yet. Until the owner adds one, the code is all rights reserved. See [Contributing](../CONTRIBUTING.md).

## Money

**Which currency?**
Sri Lankan rupees (LKR). The smallest card payment is LKR 150.

**Does BusLink store card numbers?**
No. Card details go to Stripe.

**Can I try a payment without a real card?**
In test mode, use `4242 4242 4242 4242` with any future date and any three digits.

**How does a refund reach the passenger?**
An admin approves it, and the money goes back to the card through Stripe. See the [Admin guide](Admin%20guide.md#refunds).

## Safety

**Can someone make themselves an admin?**
Not with the rules in this repository: a user cannot create or change their own role. Make sure those rules are deployed. See [Security](../SECURITY.md).

**What is still not safe enough for real money?**
The honest list is in [Security](../SECURITY.md#what-still-needs-doing-before-real-money).
