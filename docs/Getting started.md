# Getting started

A walk through BusLink from the first screen to a boarded ticket, as each person would meet it. Pick your role, or read all three to see how they fit together. Every picture is drawn by the real app code.

## On this page

* [Before you begin](#before-you-begin)
* [As a passenger: book a seat](#as-a-passenger-book-a-seat)
* [As a conductor: check a ticket](#as-a-conductor-check-a-ticket)
* [As an admin: run the buses](#as-an-admin-run-the-buses)
* [What happens behind the scenes](#what-happens-behind-the-scenes)
* [Where to go next](#where-to-go-next)

## Before you begin

* **Using the live demo?** Open [buslink-eta.vercel.app](https://buslink-eta.vercel.app) and press **Sign Up**. A new account is always a passenger.
* **Running your own copy?** Follow [Installing](Installing.md) first, then come back.
* **Need a conductor or admin account?** An admin sets the role. See [Roles](Installing.md#7-roles).

## As a passenger: book a seat

**1. Sign in.** Choose English, Sinhala or Tamil with the three buttons at the top, then sign in with email, Google or your phone number.

**2. Search.** Choose where from, where to and the date. Press **Search**.

**3. Choose a bus.** Each card shows the operator, the times, how long it takes and how many seats are left. A late bus says so in words.

<img src="images/bus-card-delayed.png" alt="A bus card with a banner saying the bus is running 30 minutes late" width="360">

**4. Choose seats.** White seats are free, grey seats with a cross are taken, and your seats show a tick.

<img src="images/seat-map.png" alt="The seat map with two selected seats" width="360">

**5. Pay.** Pay by card. The card details go straight to Stripe.

**6. Keep your ticket.** It has a QR code and a 4-digit code, and it is always in **My Trips**.

<img src="images/my-trips-card.png" alt="A trip card with View, Track bus and Refund" width="360">

**7. Board.** Show the QR code or say the 4-digit code to the conductor.

Everything about each screen is in the [Passenger guide](Passenger%20guide.md).

## As a conductor: check a ticket

**1. Open the scanner** and point the camera at the passenger's QR code. If the camera will not work, type the ticket code instead.

**2. Check three things:** the name, the seats, and that the 4-digit code matches the passenger's own screen.

<img src="images/conductor-verified.png" alt="A valid ticket with the passenger's name, seats and a large 4-digit code" width="360">

**3. Press Approve Boarding.** It saves the boarding on the ticket.

**4. If the same ticket comes back,** the app refuses it and says when it was checked in.

<img src="images/conductor-already-boarded.png" alt="Already boarded: this ticket was already checked in at 6:31 AM" width="360">

**5. If the bus is late,** report the delay so passengers are told.

<img src="images/delay-dialog.png" alt="Report Delay with quick choices of minutes" width="300">

More in the [Conductor guide](Conductor%20guide.md).

## As an admin: run the buses

**1. Add a trip** in three steps: Route, Schedule, then Fare and bus.

<img src="images/trip-form-steps.png" alt="The three steps of the trip form" width="360">

**2. Watch bookings.** Every row has a status you can read at a glance.

<img src="images/status-chips.png" alt="Status chips for bookings, refunds and trips" width="360">

**3. Process refunds.** Approve or reject each request. The passenger sees the result on a three-step line.

<img src="images/refund-progress.png" alt="Refund progress: Sent, In review, Decision" width="360">

**4. Manage roles,** read the revenue and late-departure reports, and read feedback.

More in the [Admin guide](Admin%20guide.md).

## What happens behind the scenes

<p align="center"><img src="images/booking-flow.svg" alt="The six steps from picking a seat to boarding" width="100%"></p>

Two safety checks protect everyone, and both run on the server in a single step:

* **No double booking.** When you continue, the seats are checked and reserved together. If someone else was a moment faster, you are told and can choose again.
* **One boarding per ticket.** Approving boarding checks and stamps the ticket together. A second try is refused.

The full explanation is in [How everything fits](How%20everything%20fits.md).

## Where to go next

| If you want to | Read |
|---|---|
| Run your own copy | [Installing](Installing.md) |
| Put it online | [Deploying](Deploying.md) |
| Understand the data and the rules | [Data and rules](Data%20and%20rules.md) |
| Change the code | [How it works](How%20it%20works.md) and [Contributing](../CONTRIBUTING.md) |
| Fix a problem | [Fixing problems](Fixing%20problems.md) |
