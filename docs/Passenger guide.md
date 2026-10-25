# Passenger guide

Everything a passenger can do, screen by screen, in the order they usually do it.

## On this page

* [Sign in](#sign-in)
* [Find a bus](#find-a-bus)
* [Choose your seats](#choose-your-seats)
* [Pay](#pay)
* [Your ticket](#your-ticket)
* [My Trips](#my-trips)
* [Track the bus](#track-the-bus)
* [Ask for a refund](#ask-for-a-refund)
* [Favourites, notifications and settings](#favourites-notifications-and-settings)
* [Book several dates at once](#book-several-dates-at-once)

## Sign in

<p align="center"><a href="images/passenger-1-sign-in.jpg"><img src="images/passenger-1-sign-in.jpg" alt="The sign-in page on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-1-sign-in-phone.png"><img src="images/passenger-1-sign-in-phone.png" alt="Sign in on a phone" width="31%"></a>
<a href="images/passenger-1-sign-up-phone.png"><img src="images/passenger-1-sign-up-phone.png" alt="Sign up on a phone" width="31%"></a>
<a href="images/passenger-1-phone-phone.png"><img src="images/passenger-1-phone-phone.png" alt="Phone login on a phone" width="31%"></a>
</p>

You can sign in three ways: email and password, a Google account (the button uses the real Google "G"), or a phone number with a code sent by text.

Choose English, Sinhala (සිංහල) or Tamil (தமிழ்) with the three buttons at the top of the sign-in page. Your choice is remembered, and can be changed later in your profile.

A new account is always a passenger. Nobody can pick a higher role for themselves.

## Find a bus

<p align="center"><a href="images/passenger-2-search.jpg"><img src="images/passenger-2-search.jpg" alt="The home page with the search card, on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-2-search-phone.png"><img src="images/passenger-2-search-phone.png" alt="The search card on a phone" width="31%"></a>
<a href="images/passenger-4-results-phone.png"><img src="images/passenger-4-results-phone.png" alt="Search results on a phone" width="31%"></a>
<a href="images/passenger-5-bus-details-phone.png"><img src="images/passenger-5-bus-details-phone.png" alt="Bus details on a phone" width="31%"></a>
</p>

On the home screen choose where you are leaving from, where you are going and the date, then press **Search**. The small swap button in the middle turns the two cities around.

Each result is a bus card:

<img src="images/bus-card.png" alt="A bus card showing the operator, the bus type, departure and arrival times, trip length and price" width="360">

* The top line is who runs the bus. Under it are the bus type and number, and the road it takes (for example "via Kandy").
* The times are in 12-hour format, with how long the trip takes in between.
* The price is per person.
* The line under the button says how many seats are left: green when there are plenty, red when only a few remain.

If something is wrong, the card says so in words:

<img src="images/bus-card-delayed.png" alt="A bus card with a banner saying the bus is running 30 minutes late and only 4 seats left" width="360">

A **cancelled** bus and a **full** bus have a grey button that cannot be used. Pressing it explains why.

## Choose your seats

<p align="center"><a href="images/passenger-6-seats-chosen.png"><img src="images/passenger-6-seats-chosen.png" alt="Choosing seats on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-6-seats-phone.png"><img src="images/passenger-6-seats-phone.png" alt="The seat map on a phone" width="31%"></a>
<a href="images/passenger-6-seats-chosen-phone.png"><img src="images/passenger-6-seats-chosen-phone.png" alt="Two seats chosen on a phone" width="31%"></a>
</p>

<img src="images/seat-map.png" alt="The seat map: free seats are white, taken seats are grey with a cross, selected seats are red with a tick" width="360">

* White seats are free. Tap to choose.
* Grey seats with a cross are taken. They cannot be chosen.
* Red seats with a tick are the ones you chose.

The map updates live. If someone takes a seat while you are choosing, it turns grey.

Seats are held for you only at the moment you continue. If two people try for the same seat at the same moment, one of them is told it is gone and can pick another. See [How everything fits](How%20everything%20fits.md#booking-and-payment-flow).

## Pay

<p align="center"><a href="images/passenger-7-payment.png"><img src="images/passenger-7-payment.png" alt="The payment page on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-7-payment-phone.png"><img src="images/passenger-7-payment-phone.png" alt="Payment on a phone" width="31%"></a>
</p>

Pay by card. Card details go straight to Stripe. BusLink never sees them.

* On the **phone app** a payment sheet opens.
* On the **web** you are taken to Stripe's secure page and sent back when you finish.

Prices are in Sri Lankan rupees (LKR). The app asks for at least LKR 150, and Stripe itself needs about 50 US cents (around LKR 165), so a very small amount is refused on the card page.

## Your ticket

<p align="center"><a href="images/passenger-8-ticket.png"><img src="images/passenger-8-ticket.png" alt="The ticket on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-8-ticket-phone.png"><img src="images/passenger-8-ticket-phone.png" alt="The ticket on a phone" width="31%"></a>
</p>

After paying you see "Payment Confirmed" and your ticket:

* a **QR code** the conductor scans, and
* a **4-character code** to say out loud or type, if scanning does not work.

The ticket can be saved as a PDF. It is also always in **My Trips**.

## My Trips

<p align="center"><a href="images/passenger-10-my-trips.png"><img src="images/passenger-10-my-trips.png" alt="My Trips on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-10-my-trips-phone.png"><img src="images/passenger-10-my-trips-phone.png" alt="My Trips on a phone" width="31%"></a>
</p>

<img src="images/my-trips-card.png" alt="A trip card with a green Scheduled badge, the route, date, seats, price, a View button, a Track bus button and a Refund link" width="360">

Each trip is one card.

* **View** opens the ticket. It is the main button.
* **Track bus** only appears when it is useful: the bus is on its way, is running late, or leaves within three hours.
* **Refund** is a small link, kept quiet on purpose so it is not pressed by accident. It does not appear on cancelled trips.

The badge at the top uses an icon and a word, never colour alone.

## Track the bus

<p align="center"><a href="images/passenger-9-tracking.jpg"><img src="images/passenger-9-tracking.jpg" alt="Tracking on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-9-tracking-phone.jpg"><img src="images/passenger-9-tracking-phone.jpg" alt="Tracking on a phone" width="31%"></a>
</p>

**Track bus** opens a full-screen map with one card at the bottom.

* The bus appears on the map as a pulsing red dot, using the location the conductor's phone reports for that trip.
* The card shows how long is left ("42 min" or "1 h 05 min"). This is worked out from the timetable plus any delay the conductor reported.
* **Share** copies a short message you can send to the person meeting you.
* The target button centres the map on the bus again.

## Ask for a refund

<p align="center"><a href="images/passenger-11-refund.png"><img src="images/passenger-11-refund.png" alt="Request a refund on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-11-refund-phone.png"><img src="images/passenger-11-refund-phone.png" alt="Request a refund on a phone" width="31%"></a>
</p>

Press **Refund** on a trip, choose a reason and send it. Then open the refund to see where it is:

<img src="images/refund-progress.png" alt="Three steps: Sent, In review and Decision, shown while pending, approved and rejected" width="360">

1. **Sent**: BusLink has your request.
2. **In review**: an admin is looking at it.
3. **Approved** or **Rejected**.

An approved refund is sent back to your card through Stripe. If it fails, the screen says so, and you can contact support.

## Favourites, notifications and settings

<p align="center"><a href="images/passenger-3-favourites.png"><img src="images/passenger-3-favourites.png" alt="Favourites on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-3-favourites-phone.png"><img src="images/passenger-3-favourites-phone.png" alt="Favourites on a phone" width="31%"></a>
<a href="images/passenger-13-notifications-phone.png"><img src="images/passenger-13-notifications-phone.png" alt="Notifications on a phone" width="31%"></a>
<a href="images/passenger-14-profile-phone.png"><img src="images/passenger-14-profile-phone.png" alt="Profile on a phone" width="31%"></a>
</p>

<p align="center"><a href="images/passenger-14-profile.png"><img src="images/passenger-14-profile.png" alt="Profile on a computer" width="100%"></a></p>

<p align="center">
<a href="images/passenger-14-settings-phone.png"><img src="images/passenger-14-settings-phone.png" alt="Account settings on a phone" width="31%"></a>
<a href="images/passenger-15-support-phone.png"><img src="images/passenger-15-support-phone.png" alt="Help and support on a phone" width="31%"></a>
<a href="images/passenger-12-travel-numbers-phone.png"><img src="images/passenger-12-travel-numbers-phone.png" alt="Your travel numbers on a phone" width="31%"></a>
</p>

* **Favourites** keep routes you travel often. Press **Book again** on one to search that route.
* **Notifications** tell you about delays, cancellations and refund updates. You can choose which in **Notification Settings**.
* **Profile** has Account Settings (name and phone), language, dark mode, feedback and Log Out.
* **Support** has answers to common questions and emergency hotlines: Police 119, Suwa Seriya ambulance 1990, Fire and Rescue 110 and the NTC hotline 1955.

## Book several dates at once

For a regular journey, use bulk booking on the home screen: pick the dates on a calendar and the number of seats, check the summary, and pay once. Each date gets its own ticket.
