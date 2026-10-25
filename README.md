# BusLink

[![Checks](https://github.com/Hikki-dev/Buslink/actions/workflows/checks.yml/badge.svg)](https://github.com/Hikki-dev/Buslink/actions/workflows/checks.yml)
[![Demo status](https://github.com/Hikki-dev/Buslink/actions/workflows/uptime.yml/badge.svg)](https://github.com/Hikki-dev/Buslink/actions/workflows/uptime.yml)
[![Live demo](https://img.shields.io/badge/live-demo-BA181B)](https://buslink-eta.vercel.app)
[![Licence: MIT](https://img.shields.io/github/license/Hikki-dev/Buslink)](LICENSE)

Book a bus seat, pay, and show a ticket on your phone. One app for passengers, conductors and the people who run the buses.

<p align="center"><img src="docs/images/journey.gif" alt="A short tour: sign in, find a bus, choose a bus, pick seats, keep your ticket, the conductor checks it, and a second try is refused" width="100%"></p>

<p align="center"><sub>One trip, from sign-in to boarding, in seven scenes. <b><a href="https://buslink-eta.vercel.app">Open the live app</a></b> and follow along.</sub></p>

A passenger finds a trip, picks seats on a live seat map, pays by card and gets a ticket with a QR code. The conductor scans it when the passenger boards, and the ticket can never be used twice. Admins plan the trips, watch the bookings and handle refunds.

You do not need to know how any of it works. Every screen uses big buttons and plain words, never shows a status by colour alone, and speaks three languages: English, Sinhala and Tamil.

## On this page

* [What you get](#what-you-get): who it is for, and what it is built with
* [How everything fits together](#how-everything-fits-together)
* [Try it first](#try-it-first): the live app, or your own copy with test accounts
* [The story, step by step](#the-story-step-by-step)
  * [Part 1: The passenger](#part-1-the-passenger)
    * [1. Sign in](#1-sign-in)
    * [2. Find a bus](#2-find-a-bus)
    * [3. Your favourite routes](#3-your-favourite-routes)
    * [4. Choose a bus](#4-choose-a-bus)
    * [5. About the bus](#5-about-the-bus)
    * [6. Choose your seats](#6-choose-your-seats)
    * [7. Pay](#7-pay)
    * [8. Your ticket](#8-your-ticket)
    * [9. Follow the bus](#9-follow-the-bus)
    * [10. My Trips](#10-my-trips)
    * [11. If plans change](#11-if-plans-change)
    * [12. Your travel numbers](#12-your-travel-numbers)
    * [13. Notifications](#13-notifications)
    * [14. Profile and settings](#14-profile-and-settings)
    * [15. Help and support](#15-help-and-support)
  * [Part 2: The conductor](#part-2-the-conductor)
    * [16. The conductor's home](#16-the-conductors-home)
    * [17. Check a ticket](#17-check-a-ticket)
    * [18. Once only](#18-once-only)
    * [19. Find a trip and report a delay](#19-find-a-trip-and-report-a-delay)
  * [Part 3: The admin](#part-3-the-admin)
    * [20. Upcoming trips](#20-upcoming-trips)
    * [21. Add a trip](#21-add-a-trip)
    * [22. Routes and schedules](#22-routes-and-schedules)
    * [23. Bookings](#23-bookings)
    * [24. Refunds](#24-refunds)
    * [25. Feedback and analytics](#25-feedback-and-analytics)
    * [26. Users and roles](#26-users-and-roles)
* [Every screen in one place](#every-screen-in-one-place)
* [What keeps it safe](#what-keeps-it-safe)
* [Run it yourself](#run-it-yourself)
* [Tests](#tests)
* [Your privacy and safety](#your-privacy-and-safety)
* [Help and more reading](#help-and-more-reading)
* [Legal and responsibility](#legal-and-responsibility)

## What you get

One app, three people. Each one sees only the screens they need.

| Who | What they do |
|---|---|
| **Passengers** | Search by route and date, pick seats on a live map, pay by card, keep tickets in My Trips, track the bus, ask for refunds, save favourite routes and book several dates at once |
| **Conductors** | Scan a ticket or type its code, approve boarding, report a delay, change a trip's status and book walk-up passengers who have no app |
| **Admins** | Add trips and timetables, browse bookings, review refunds, manage who is a conductor or admin, and read the revenue and late-departure reports |

It also signs people in with email, Google or a phone number, sends push notifications and trip reminders, and works in light and dark themes. Tickets can be saved as a PDF.

### What it is built with

<table>
<tr><td width="64"><img src="docs/images/icons/flutter.png" alt="Flutter logo" width="48"></td><td width="170"><b>Flutter</b></td><td>One app for phones, the web and desktop</td></tr>
<tr><td><img src="docs/images/icons/dart.png" alt="Dart logo" width="48"></td><td><b>Dart</b></td><td>The language Flutter is written in</td></tr>
<tr><td><img src="docs/images/icons/firebase.png" alt="Firebase logo" width="48"></td><td><b>Firebase</b></td><td>Sign-in, the database (Firestore) and push messages</td></tr>
<tr><td><img src="docs/images/icons/google.png" alt="Google logo" width="48"></td><td><b>Google Sign-In</b></td><td>"Continue with Google" on the sign-in page</td></tr>
<tr><td><img src="docs/images/icons/stripe.png" alt="Stripe logo" width="48"></td><td><b>Stripe</b></td><td>Card payments and refunds. Card details never touch BusLink</td></tr>
<tr><td><img src="docs/images/icons/vercel.png" alt="Vercel logo" width="48"></td><td><b>Vercel</b></td><td>Hosts the web app and the two small payment functions</td></tr>
</table>

## How everything fits together

A trip is one story with two halves. The passenger books, and later the conductor boards them.

<p align="center"><a href="docs/images/booking-flow.svg"><img src="docs/images/booking-flow.svg" alt="The six steps from picking a seat to boarding the bus" width="100%"></a></p>

Behind the screens, the app talks to Firebase for sign-in, data and push messages. Payments go to Stripe, from the phone directly or through two small functions on the web.

<p align="center"><a href="docs/images/how-it-fits.svg"><img src="docs/images/how-it-fits.svg" alt="Diagram: the BusLink app talks to Firebase Authentication, Cloud Firestore and Cloud Messaging, to Vercel functions and a Cloud Function for payments, and those talk to Stripe" width="100%"></a></p>

The full story, including every collection in the database, is in [How everything fits](docs/How%20everything%20fits.md). The walk through below follows the same steps.

## Try it first

**[Open the live demo](https://buslink-eta.vercel.app).** It is the real app running on the web.

* Press **Sign Up** to make a passenger account. New accounts are always passengers.
* To pay, use Stripe's test card `4242 4242 4242 4242`, any future date and any three digits. The demo is built with Stripe **test** keys. Never type a real card number into it.
* Conductor and admin screens need an account that the owner has given that role. See [Roles](docs/Installing.md#7-roles).

The **Demo status** badge at the top of this page turns red if the demo goes down. A small check runs every six hours (see [Deploying](docs/Deploying.md)). The **Checks** badge shows that the code and the docs pass their tests.

### Or try every role on your own computer

You can run the whole app against a pretend Firebase on your own computer. Nothing is sent anywhere, and it comes with a customer, a conductor and an admin to sign in as. This is how every picture on this page was taken. The steps are in [Try it on your computer](docs/Try%20it%20on%20your%20computer.md).

## The story, step by step

Every picture is the real app, taken from the running web version at twice the usual sharpness. Click a picture to see it full size. The wide picture is the computer view, and the tall ones below it are the phone view. The full walk through, with a little more detail for each screen, is in [Getting started](docs/Getting%20started.md), and [Every screen in one place](#every-screen-in-one-place) lists them all.

### Part 1: The passenger

It starts with someone who wants to get from Colombo to Kandy.

#### 1. Sign in

<p align="center"><a href="docs/images/passenger-1-sign-in.jpg"><img src="docs/images/passenger-1-sign-in.jpg" alt="The sign-in page: three language buttons, email and password boxes, Continue with Google and Log in with phone number, beside a photo of the Nine Arches Bridge" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-1-sign-in-phone.png"><img src="docs/images/passenger-1-sign-in-phone.png" alt="The sign-in page on a phone" width="31%"></a>
<a href="docs/images/passenger-1-sign-up-phone.png"><img src="docs/images/passenger-1-sign-up-phone.png" alt="The sign-up page on a phone" width="31%"></a>
<a href="docs/images/passenger-1-phone-phone.png"><img src="docs/images/passenger-1-phone-phone.png" alt="Phone login on a phone: enter a phone number and press Send Code" width="31%"></a>
</p>

While the app opens, a short scene plays: a bus drives from Colombo through Kandy to Ella, and a line says what is happening (more in [Starting up](docs/Starting%20up.md)).

Choose English, Sinhala or Tamil with the three buttons at the top. Sign in with email, with Google, or with a phone number: you type your number, and a six-digit code arrives by text. **Sign Up** makes a new account. A new account is always a passenger. Nobody can pick a higher role for themselves.

#### 2. Find a bus

<p align="center"><a href="docs/images/passenger-2-search.jpg"><img src="docs/images/passenger-2-search.jpg" alt="The home page: a photo of the tea hills, the search card with Leaving from, Going to and Day of travel, and Your Favorites below" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-2-search-phone.png"><img src="docs/images/passenger-2-search-phone.png" alt="The home page on a phone, with the search card and the favourite routes" width="31%"></a>
</p>

Choose where from, where to and the day, then press **Search Buses**. The little arrows swap the two cities. Tick **Bulk booking** to book several days in one go. Below the search, your favourite routes and your next trips are one tap away.

**Booking several days at once.** Tick **Bulk booking**, press the box that now says "days chosen", and tap each day you travel. Press **Search Buses**, choose a bus, and say how many people are travelling each day. A summary lists every date, the price per ticket and the total before you pay once. Each day gets its own ticket.

<p align="center"><a href="docs/images/bulk-2-dates.jpg"><img src="docs/images/bulk-2-dates.jpg" alt="Choosing several days on a calendar: three days are selected" width="100%"></a></p>

<p align="center">
<a href="docs/images/bulk-2-dates-phone.png"><img src="docs/images/bulk-2-dates-phone.png" alt="The calendar on a phone" width="31%"></a>
<a href="docs/images/bulk-3-passengers-phone.png"><img src="docs/images/bulk-3-passengers-phone.png" alt="Choosing how many people travel each day, with the total price" width="31%"></a>
<a href="docs/images/bulk-4-summary-phone.png"><img src="docs/images/bulk-4-summary-phone.png" alt="The bulk booking summary: the dates, the price per ticket, the number of passengers and the total" width="31%"></a>
</p>

#### 3. Your favourite routes

<p align="center"><a href="docs/images/passenger-3-favourites.png"><img src="docs/images/passenger-3-favourites.png" alt="My favourites: a card for each saved route with a Book again button" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-3-favourites-phone.png"><img src="docs/images/passenger-3-favourites-phone.png" alt="My favourites on a phone" width="31%"></a>
</p>

Press the heart on any trip to keep the route. **Book again** fills in the search for you.

#### 4. Choose a bus

<p align="center"><a href="docs/images/passenger-4-results.png"><img src="docs/images/passenger-4-results.png" alt="Search results: the filters on the left and one bus card with its times, price, seats left and a Book Now button" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-4-results-phone.png"><img src="docs/images/passenger-4-results-phone.png" alt="Search results on a phone" width="31%"></a>
</p>

Each result is one card: who runs the bus, the times in plain 12-hour format, how long it takes and how many seats are left. The filters narrow the list by time of day and hide full buses. If something is wrong, the card says so in words.

<img src="docs/images/bus-card-delayed.png" alt="A bus card with a warning that the bus is running 30 minutes late" width="360">

A cancelled or full bus has a grey button that cannot be pressed, and pressing it explains why. Otherwise, press **Book Now**, or the red line under the bus name to see what is on it first.

#### 5. About the bus

<p align="center"><a href="docs/images/passenger-5-bus-details.png"><img src="docs/images/passenger-5-bus-details.png" alt="Bus details: departure, arrival and platform, what is on the bus, and the stops on the way" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-5-bus-details-phone.png"><img src="docs/images/passenger-5-bus-details-phone.png" alt="Bus details on a phone" width="31%"></a>
</p>

You see the times, the **platform** when the operator has set one, what is on the bus (air conditioning, WiFi) and every stop on the way. Press **Choose seats** to carry on.

#### 6. Choose your seats

<p align="center"><a href="docs/images/passenger-6-seats-chosen.png"><img src="docs/images/passenger-6-seats-chosen.png" alt="Choosing seats: the seat map with two seats chosen, and a summary with the total price" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-6-seats-phone.png"><img src="docs/images/passenger-6-seats-phone.png" alt="The seat map on a phone" width="31%"></a>
<a href="docs/images/passenger-6-seats-chosen-phone.png"><img src="docs/images/passenger-6-seats-chosen-phone.png" alt="Two seats chosen on a phone, with the total at the bottom" width="31%"></a>
</p>

The seat map is live. Seats someone else has taken are grey with a cross. Your seats show a tick. You can choose up to six. Every seat can be read out by a screen reader ("Seat 9, selected"), and every seat can be chosen with one, too.

<img src="docs/images/seat-map.png" alt="The seat map with two selected seats and several taken seats" width="360">

When you continue, the seats are checked and reserved together in one step, so two people can never get the same seat. If someone was a moment faster, you are told and can choose again.

#### 7. Pay

<p align="center"><a href="docs/images/passenger-7-payment.png"><img src="docs/images/passenger-7-payment.png" alt="Payment: the booking summary on the right and a Proceed to Pay button" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-7-payment-phone.png"><img src="docs/images/passenger-7-payment-phone.png" alt="Payment on a phone" width="31%"></a>
</p>

Check the summary, then press **Proceed to Pay**. On the phone a payment sheet opens. On the web you are taken to Stripe's secure page and sent back. Card details go straight to Stripe. If a payment fails or is cancelled, a card says what happened and offers the way on.

<img src="docs/images/payment-states.png" alt="Payment states: processing, paid, cancelled and failed, each with a clear next step" width="360">

#### 8. Your ticket

<p align="center"><a href="docs/images/passenger-8-ticket.png"><img src="docs/images/passenger-8-ticket.png" alt="The ticket: a QR code, a 4-character code, the trip, platform, seats and total, with Download PDF and Track bus buttons" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-8-ticket-phone.png"><img src="docs/images/passenger-8-ticket-phone.png" alt="The ticket on a phone" width="31%"></a>
</p>

You are shown **Payment Confirmed** and your ticket: a **QR code** for the conductor to scan, and a **4-character code** to read out if scanning does not work. The ticket is also kept in **My Trips**, and can be saved as a PDF.

Straight after paying you land on **Booking Confirmed**, with the same QR code and code, a button to save the ticket as a PDF, one to send it by text message, and a link to keep the route in your favourites.

<p align="center"><a href="docs/images/passenger-8-confirmed.png"><img src="docs/images/passenger-8-confirmed.png" alt="Booking Confirmed: the trip, the platform, the seats and a QR code with the code beside it" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-8-confirmed-phone.png"><img src="docs/images/passenger-8-confirmed-phone.png" alt="Booking Confirmed on a phone" width="31%"></a>
</p>

#### 9. Follow the bus

<p align="center"><a href="docs/images/passenger-9-tracking.jpg"><img src="docs/images/passenger-9-tracking.jpg" alt="Tracking: a map with the bus, a card saying how long is left and the next stop" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-9-tracking-phone.jpg"><img src="docs/images/passenger-9-tracking-phone.jpg" alt="Tracking on a phone" width="31%"></a>
</p>

**Track bus** opens a full-screen map. The bus shows as a pulsing dot, using the location the conductor's phone reports for that trip. One card says how long is left, worked out from the timetable plus any delay, and names the next stop. When there is no live location yet, it says so and uses the timetable. Within five minutes of arriving it turns into "Your bus is almost here", with a **Show my ticket** button.

#### 10. My Trips

<p align="center"><a href="docs/images/passenger-10-my-trips.png"><img src="docs/images/passenger-10-my-trips.png" alt="My tickets: a list of trips on the left, and the chosen ticket with its QR code on the right" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-10-my-trips-phone.png"><img src="docs/images/passenger-10-my-trips-phone.png" alt="My Trips on a phone" width="31%"></a>
<a href="docs/images/empty-trips-phone.png"><img src="docs/images/empty-trips-phone.png" alt="My Trips for someone with no tickets yet: a friendly message" width="31%"></a>
</p>

Every ticket is one card with one big **View ticket** button. Before the first booking, a short message says what to do. The tabs sort them into Upcoming, Completed, Cancelled and Delayed. **Track bus** appears only when it is useful: the bus is on its way, is running late, or leaves within three hours. **Refund** is a small link, kept quiet on purpose so it is not pressed by accident.

<img src="docs/images/my-trips-card.png" alt="A trip card with a View button, a Track bus button and a Refund link" width="360">

#### 11. If plans change

<p align="center"><a href="docs/images/passenger-11-refund.png"><img src="docs/images/passenger-11-refund.png" alt="Request a refund: the refund policy, a reason to choose, and how much you receive" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-11-refund-phone.png"><img src="docs/images/passenger-11-refund-phone.png" alt="Request a refund on a phone" width="31%"></a>
</p>

Press **Refund**, read how much you get back (the earlier you cancel, the more), choose a reason and send it. A three-step line then shows where it is: Sent, In review, then Approved or Rejected.

<img src="docs/images/refund-progress.png" alt="Refund progress shown as Sent, In review and Decision, in three states" width="360">

#### 12. Your travel numbers

<p align="center"><a href="docs/images/passenger-12-travel-numbers.png"><img src="docs/images/passenger-12-travel-numbers.png" alt="Travel Trends: how many trips are upcoming, arrived, delayed and cancelled, and the total spent" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-12-travel-numbers-phone.png"><img src="docs/images/passenger-12-travel-numbers-phone.png" alt="Travel Trends on a phone" width="31%"></a>
</p>

A friendly summary of your trips: how many are coming up, how many you have taken, what you have spent, your favourite destination and your busiest month.

#### 13. Notifications

<p align="center"><a href="docs/images/passenger-13-notifications.png"><img src="docs/images/passenger-13-notifications.png" alt="Notifications: a list of messages about a bus being on time, a delay and an approved refund" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-13-notifications-phone.png"><img src="docs/images/passenger-13-notifications-phone.png" alt="Notifications on a phone" width="31%"></a>
<a href="docs/images/passenger-14-notification-settings-phone.png"><img src="docs/images/passenger-14-notification-settings-phone.png" alt="Notification settings on a phone" width="31%"></a>
</p>

You hear about delays, cancellations, refunds and reminders. The bell shows how many are new. Press **Mark all as read**, or open the settings to choose what you want to hear about. The first time, the app asks if it may send notifications. Answer once: **Allow** is remembered for good, and **Later** waits a week.

#### 14. Profile and settings

<p align="center"><a href="docs/images/passenger-14-profile.png"><img src="docs/images/passenger-14-profile.png" alt="The profile page: name, email and a list of Account Settings, Notification Settings, Language, Dark Mode, My Favourites, Support and Send Feedback" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-14-profile-phone.png"><img src="docs/images/passenger-14-profile-phone.png" alt="The profile page on a phone" width="31%"></a>
<a href="docs/images/passenger-14-settings-phone.png"><img src="docs/images/passenger-14-settings-phone.png" alt="Account settings on a phone" width="31%"></a>
<a href="docs/images/passenger-14-feedback-phone.png"><img src="docs/images/passenger-14-feedback-phone.png" alt="The feedback form on a phone" width="31%"></a>
</p>

Change your name and phone number, link your Google account, switch the language or dark mode, and tell us what you think with **Send Feedback**.

#### 15. Help and support

<p align="center"><a href="docs/images/passenger-15-support.png"><img src="docs/images/passenger-15-support.png" alt="Help and support: common questions, a message form, emergency hotlines and a Call Support button" width="100%"></a></p>

<p align="center">
<a href="docs/images/passenger-15-support-phone.png"><img src="docs/images/passenger-15-support-phone.png" alt="Help and support on a phone" width="31%"></a>
</p>

Answers to the questions people ask most, a message form that opens your email app, the emergency numbers for Sri Lanka, and one-tap buttons to call or email support.

That is the passenger's whole journey. More detail is in the [Passenger guide](docs/Passenger%20guide.md). Now the other person in the story: the conductor, at the door of the bus.

### Part 2: The conductor

The passenger walks up with a phone. The conductor has about five seconds.

#### 16. The conductor's home

<p align="center"><a href="docs/images/conductor-1-home.png"><img src="docs/images/conductor-1-home.png" alt="The conductor's home: Scan Ticket with a box for a ticket code, and Find Trips" width="100%"></a></p>

<p align="center">
<a href="docs/images/conductor-1-home-phone.png"><img src="docs/images/conductor-1-home-phone.png" alt="The conductor's home on a phone" width="31%"></a>
</p>

Two big jobs, one under the other: **Scan Ticket** (use the camera, or type the code and press **Verify**) and **Find Trips**. The app asks to use the phone's location so passengers can see where their bus is. Saying no is fine, and nothing else changes.

#### 17. Check a ticket

<p align="center"><a href="docs/images/conductor-2-verified.png"><img src="docs/images/conductor-2-verified.png" alt="A valid ticket: the passenger's name, their seats, the 4-character code and the seat map, with an Approve Boarding button" width="100%"></a></p>

<p align="center">
<a href="docs/images/conductor-2-verified-phone.png"><img src="docs/images/conductor-2-verified-phone.png" alt="A valid ticket on a phone" width="31%"></a>
</p>

The answer is a big green "Ticket is valid" with the passenger's name, their seats, and the code to compare with the passenger's own screen. The same works for the long ticket number in the QR code and for the short code on the ticket. When they match, press **Approve Boarding**.

<img src="docs/images/conductor-verified.png" alt="A valid ticket: passenger name, seats, the 4-character code and the seat map" width="360">

Approving saves the time and the conductor on the ticket. If there is no signal, the app says so and keeps the card open. It never shows a boarding as saved when it was not.

#### 18. Once only

<p align="center"><a href="docs/images/conductor-3-boarded.png"><img src="docs/images/conductor-3-boarded.png" alt="After approving: back at the conductor's home, ready for the next passenger" width="100%"></a></p>

<p align="center">
<a href="docs/images/conductor-3-boarded-phone.png"><img src="docs/images/conductor-3-boarded-phone.png" alt="Back at the conductor's home on a phone" width="31%"></a>
</p>

A ticket boards once. If someone shows the same ticket again, even to a different conductor a moment later, the conductor sees this instead:

<img src="docs/images/conductor-already-boarded.png" alt="Already boarded: this ticket was already checked in at 6:31 AM. Each ticket can board only once." width="360">

The check and the stamp happen together on the server, and the database rules enforce it too, so it holds even if someone tries to get around the app.

#### 19. Find a trip and report a delay

<p align="center"><a href="docs/images/conductor-4-results.png"><img src="docs/images/conductor-4-results.png" alt="Finding a trip: choose the origin, the destination and the day, then pick the trip" width="100%"></a></p>

<p align="center">
<a href="docs/images/conductor-4-find-trips-phone.png"><img src="docs/images/conductor-4-find-trips-phone.png" alt="Find a trip on a phone" width="31%"></a>
<a href="docs/images/conductor-4-results-phone.png"><img src="docs/images/conductor-4-results-phone.png" alt="The trips that match, on a phone" width="31%"></a>
</p>

Choose where from, where to and the day, then pick the trip. If the bus is late, press the delay button and choose 15, 30, 45, 60 or 90 minutes, or type your own. Passengers with a ticket are told straight away, and their bus card says "Running 30 minutes late".

<img src="docs/images/delay-dialog.png" alt="Report Delay dialog with quick minute choices" width="300">

More in the [Conductor guide](docs/Conductor%20guide.md). The last person in the story never sees a bus at all, but makes the whole thing possible.

### Part 3: The admin

Before any passenger can book, someone has to have planned the trips. On a computer, the admin has a dark red menu down the left side. On a phone, the same pages are tiles, with a bar at the bottom.

#### 20. Upcoming trips

<p align="center"><a href="docs/images/admin-1-trips.png"><img src="docs/images/admin-1-trips.png" alt="Upcoming trips: a table of the next trips with the route, time, bus, seats taken, status and Edit, Seats and Delete buttons" width="100%"></a></p>

<p align="center">
<a href="docs/images/admin-1-trips-phone.png"><img src="docs/images/admin-1-trips-phone.png" alt="The admin home on a phone: tiles for Add New Trip, Add Route, Manage Routes, Bookings, Refunds, Analytics and App Feedback" width="31%"></a>
</p>

The next 30 days of trips, with how many seats are taken and whether each is on time. Deleting a trip tells you how many seats are already booked before it asks you to confirm.

#### 21. Add a trip

<p align="center"><a href="docs/images/admin-2-trip-form.png"><img src="docs/images/admin-2-trip-form.png" alt="The Add New Trip form, step 1 of 3: choose or type the route" width="100%"></a></p>

<p align="center">
<a href="docs/images/admin-2-trip-form-phone.png"><img src="docs/images/admin-2-trip-form-phone.png" alt="The Add New Trip form on a phone" width="31%"></a>
</p>

The trip form has three short steps: Route, then Schedule, then Fare and bus. You can fill in the **platform** (optional) so passengers know where to wait. **Next** checks only what you can see, and **Back** keeps what you typed. Nothing is saved until the last step.

<img src="docs/images/trip-form-steps.png" alt="The three-step indicator on the trip form" width="360">

#### 22. Routes and schedules

<p align="center"><a href="docs/images/admin-3-routes.png"><img src="docs/images/admin-3-routes.png" alt="Route and schedule management: two tabs, and a table of routes with Edit and Delete" width="100%"></a></p>

<p align="center">
<a href="docs/images/admin-3-routes-phone.png"><img src="docs/images/admin-3-routes-phone.png" alt="Routes on a phone: the table slides sideways" width="31%"></a>
</p>

A **route** is the path. A **schedule** says which bus runs it and when, and can carry a default platform. **Generate Trips** makes the trips for the coming days from a schedule.

#### 23. Bookings

<p align="center"><a href="docs/images/admin-4-bookings.png"><img src="docs/images/admin-4-bookings.png" alt="Booking management: a search box, filters and a card for each booking with its status" width="100%"></a></p>

<p align="center">
<a href="docs/images/admin-4-bookings-phone.png"><img src="docs/images/admin-4-bookings-phone.png" alt="Bookings on a phone" width="31%"></a>
</p>

Every booking has a status you can read at a glance. Each is an icon, a word and a colour together, so it works for everyone, including people who cannot tell red from green. A checked-in ticket shows **Boarded**.

Open a booking to see the trip, the passenger and what was paid.

<p align="center"><a href="docs/images/admin-4-booking-details.png"><img src="docs/images/admin-4-booking-details.png" alt="Booking details: the route, date, bus and seats, the passenger, and the payment summary" width="100%"></a></p>

<p align="center">
<a href="docs/images/admin-4-booking-details-phone.png"><img src="docs/images/admin-4-booking-details-phone.png" alt="Booking details on a phone" width="31%"></a>
</p>

<img src="docs/images/status-chips.png" alt="Status chips: Confirmed, Boarded, Cancelled, Refund requested, Refunded, Pending, Approved, Rejected and Delayed" width="360">

#### 24. Refunds

<p align="center"><a href="docs/images/admin-5-refunds.png"><img src="docs/images/admin-5-refunds.png" alt="Refund management: three tabs, Pending, Approved and Rejected, and a card for each request with a Review button" width="100%"></a></p>

<p align="center">
<a href="docs/images/admin-5-refunds-phone.png"><img src="docs/images/admin-5-refunds-phone.png" alt="Refunds on a phone" width="31%"></a>
<a href="docs/images/admin-5-refund-details-phone.png"><img src="docs/images/admin-5-refund-details-phone.png" alt="Refund details on a phone" width="31%"></a>
</p>

Refund requests arrive in a list with three tabs, Pending, Approved and Rejected. Open one to see why the passenger asked and how much they get back. Approving one returns the money to the passenger's card through Stripe. Rejecting asks for a reason from a short list.

<p align="center"><a href="docs/images/admin-5-refund-details.png"><img src="docs/images/admin-5-refund-details.png" alt="Refund details: the passenger, the trip price, the cancellation rule, the amount to refund and the reason, with Reject and Approve Refund buttons" width="100%"></a></p>

#### 25. Feedback and analytics

<p align="center"><a href="docs/images/admin-6-feedback.png"><img src="docs/images/admin-6-feedback.png" alt="Customer feedback: a card for each message with the star rating and the comment" width="100%"></a></p>

<p align="center">
<a href="docs/images/admin-6-feedback-phone.png"><img src="docs/images/admin-6-feedback-phone.png" alt="Feedback on a phone" width="31%"></a>
<a href="docs/images/admin-7-analytics-phone.png"><img src="docs/images/admin-7-analytics-phone.png" alt="Analytics on a phone: net revenue and top routes" width="31%"></a>
</p>

Read what passengers wrote and how many stars they gave. **Analytics** shows net revenue over time and the top routes, with a second tab for late departures.

<p align="center"><a href="docs/images/admin-7-late.png"><img src="docs/images/admin-7-late.png" alt="Late departures: how many trips ran and what share left late" width="100%"></a></p>

<p align="center"><a href="docs/images/admin-7-analytics.png"><img src="docs/images/admin-7-analytics.png" alt="Analytics: net revenue for the last 30 days and today, a chart, and the top routes" width="100%"></a></p>

#### 26. Users and roles

<p align="center"><a href="docs/images/admin-8-users.png"><img src="docs/images/admin-8-users.png" alt="User management: a search box and a table of people with their role and Edit and Delete buttons" width="100%"></a></p>

<p align="center">
<a href="docs/images/admin-8-users-phone.png"><img src="docs/images/admin-8-users-phone.png" alt="Users and roles on a phone" width="31%"></a>
</p>

A new account is a passenger. Only an admin can make someone a conductor or admin, here. The app notices a role change at once, with no sign-out. This is enforced by the database rules, not just the screens, and the rules have their own tests.

That closes the loop: the admin's trips are what the passenger searched for in step 2. More in the [Admin guide](docs/Admin%20guide.md).

## Every screen in one place

The design boards, one for each screen on a phone and on a computer, are listed in [Every screen](docs/Every%20screen.md) next to the picture of the finished screen. Start there to find a screen by name.

## What keeps it safe

Three checks run on the server in a single step each, so they cannot be skipped by a slow phone or a clever one.

* **No double booking.** Seats are checked and reserved together.
* **One boarding per ticket.** The ticket is checked and stamped together, and the rules only let a conductor stamp it once, as themselves.
* **No self-promotion.** Nobody can create or change their own role. A passenger cannot rewrite their own ticket's owner, price or seats, or mark it boarded.

These are proven by 43 automatic cases that run on every change. The honest list of what still needs doing before real money is in [Security](SECURITY.md).

## Run it yourself

You need [Flutter](https://docs.flutter.dev/get-started/install) 3.38 or newer, a free [Firebase](https://console.firebase.google.com/) project (with Email/Password, Google and Phone sign-in turned on, and a Firestore database), a [Stripe](https://stripe.com) account in **test mode**, and Node.js 18 or newer for the data scripts.

```bash
git clone https://github.com/Hikki-dev/Buslink.git
cd Buslink
flutter pub get
```

Then, once:

1. Create `lib/firebase_options.dart` for **your** Firebase project (`flutterfire configure`).
2. Create a `.env` file in the project folder. The build fails without it.
3. Deploy the database rules, exactly as they are in the repository, and add some trips.

```bash
flutter run             # Android or iOS
flutter run -d chrome   # Web
```

Every step is explained, with the exact keys and commands, in [Installing](docs/Installing.md). Putting the web version online for free is in [Deploying](docs/Deploying.md).

## Tests

```bash
flutter analyze
flutter test
python3 tool/check_docs.py   # links and pictures in the docs
```

The same checks run on every pull request (the **Checks** badge above), together with 43 cases that test the database rules in the Firebase emulator.

The tests cover the parts that are easy to get wrong: the boarding rule, the arrival-time maths, the refund progress, the three-step trip form, the bus and ticket cards, and the status chips. See [Testing](docs/Testing.md), which also shows how to remake the pictures in this README.

## Your privacy and safety

* A passenger can only see their own tickets and profile.
* **Nobody can choose their own role.** A new account is always a passenger.
* Two people cannot book the same seat, and one ticket cannot board twice. Both are checked on the server, not just on the screen.
* Card details go straight to Stripe. BusLink never sees or stores them.
* The hidden debug login only exists in developer builds. It is not in the live app.

Some parts were built as coursework and need hardening before real money is involved. They are listed honestly in [Security](SECURITY.md).

## Help and more reading

| If you want to | Read |
|---|---|
| Follow the app from the first screen to a boarded ticket | [Getting started](docs/Getting%20started.md) |
| Find a screen by its design name, with its picture | [Every screen](docs/Every%20screen.md) |
| Try every role on your own computer, with test accounts | [Try it on your computer](docs/Try%20it%20on%20your%20computer.md) |
| Run your own copy | [Installing](docs/Installing.md) |
| Put it online | [Deploying](docs/Deploying.md) |
| See what happens while it opens, and why it is fast | [Starting up](docs/Starting%20up.md) |
| Learn each passenger screen | [Passenger guide](docs/Passenger%20guide.md) |
| Learn the conductor screens | [Conductor guide](docs/Conductor%20guide.md) |
| Learn the admin screens | [Admin guide](docs/Admin%20guide.md) |
| Understand how it works for people | [How everything fits](docs/How%20everything%20fits.md) |
| See what is stored and who can change it | [Data and rules](docs/Data%20and%20rules.md) |
| Read or change the code | [How it works](docs/How%20it%20works.md) |
| See the look and the rules it follows | [Design](docs/Design.md) |
| Fix a problem | [Fixing problems](docs/Fixing%20problems.md) |
| Find a quick answer | [Questions and answers](docs/FAQ.md) |
| Set up Stripe | [Stripe setup](STRIPE_SETUP.md) |
| Run or write tests | [Testing](docs/Testing.md) |
| Report a security problem | [Security](SECURITY.md) |
| Contribute a change | [Contributing](CONTRIBUTING.md) |
| See what changed | [Changes](CHANGELOG.md) |

## Legal and responsibility

* BusLink is a portfolio and learning project. It is not a licensed ticketing service.
* The code is released under the [MIT licence](LICENSE). It is provided as it is, with no promises. You are responsible for how you use it, especially with real payments (see [Security](SECURITY.md)).
* Use Stripe in test mode unless you have made the changes listed in [Security](SECURITY.md) first.
* Brand names and logos (Flutter, Dart, Firebase, Google, Stripe and Vercel) belong to their owners and are used only to say what BusLink is built with.
* Photos in the design mockups are from Wikimedia Commons, with credit to the photographers in the [Design](docs/Design.md#photo-credits) page.
* Built by [Yusuf (Hikki-dev)](https://github.com/Hikki-dev).
