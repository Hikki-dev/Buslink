# Questions and answers

**Is this a real bus company's app?**
No. It is a portfolio and learning project. The routes and prices are sample data, and no bus will take you anywhere.

**Can I try it without a Firebase project?**
Yes. See [Demo mode](Demo%20mode.md). It needs Flutter, Node and Java.

**Do I need Stripe?**
Only to pay. Everything else works without it. Use test mode, and the test card `4242 4242 4242 4242`.

**How does it stop two people booking the same seat?**
The seats are checked and held in one Firestore transaction (`createPendingBooking`). If a seat was taken a moment before, the transaction fails and the passenger is asked to choose again.

**What happens to a seat if someone never pays, or gets a refund?**
Nothing: the seat stays taken. The code only ever adds seats to a trip's `bookedSeatNumbers` (`FieldValue.arrayUnion`) and never takes them off, so an abandoned payment keeps its seats held, and a refunded ticket does not free its seats. There is no clean-up job yet. That is a known gap, and a good first fix.

**How are trips made?**
An admin makes a route and a schedule (the days of the week and the time). The script `scripts/generate_trips.js` makes a trip for every schedule on each of the next 30 days. Run it on a timer.

**How do I make someone an admin or a conductor?**
An admin opens **Roles** and changes the user's role. The role is stored on `users/{uid}`, and the app opens the matching screens straight away.

**Which currency?**
Sri Lankan rupees (LKR). The mobile payment sheet needs a minimum of LKR 150.

**Does it work offline?**
Partly. Firestore keeps a local copy of what you have seen, and the app shows your profile from a cache while it starts.

**What is an "offline booking"?**
A walk-up booking: a conductor books a seat for a passenger who does not have the app. It still needs a connection, because it writes to Firestore.

**Can I use the code?**
There is no licence file yet, so all rights are reserved for now. Ask first.
