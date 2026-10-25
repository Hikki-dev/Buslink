# Conductor guide

What a conductor does with the app: find the trip, check each ticket as people board, and tell passengers when the bus is late.

An account becomes a conductor when an admin sets its role (see [Roles](Installing.md#7-roles)). On sign-in a conductor lands on the conductor dashboard instead of the passenger screens.

## On this page

* [Find your trip](#find-your-trip)
* [Check a ticket](#check-a-ticket)
* [Approve boarding](#approve-boarding)
* [When a ticket is refused](#when-a-ticket-is-refused)
* [Report a delay](#report-a-delay)
* [Change the trip status](#change-the-trip-status)
* [Passengers without the app](#passengers-without-the-app)
* [The rules the app follows](#the-rules-the-app-follows)

## Find your trip

<p align="center"><a href="images/conductor-4-results.png"><img src="images/conductor-4-results.png" alt="Finding a trip on a computer" width="100%"></a></p>

<p align="center">
<a href="images/conductor-1-home-phone.png"><img src="images/conductor-1-home-phone.png" alt="The conductor's home on a phone" width="31%"></a>
<a href="images/conductor-4-find-trips-phone.png"><img src="images/conductor-4-find-trips-phone.png" alt="Finding a trip on a phone" width="31%"></a>
</p>

On the dashboard, use **Find Trip** to search for your bus. The results list the trips that match. If nothing matches, the screen says "No active trips found" and offers **Search Again**. **Back to Search** returns to the search from a result.

Open a trip to manage it: status, delays and platform.

## Check a ticket

<p align="center"><a href="images/conductor-2-verified.png"><img src="images/conductor-2-verified.png" alt="A valid ticket on a computer" width="100%"></a></p>

<p align="center">
<a href="images/conductor-2-verified-phone.png"><img src="images/conductor-2-verified-phone.png" alt="A valid ticket on a phone" width="31%"></a>
</p>

You have two ways to check a ticket:

1. **Scan.** Open the scanner and point the camera at the passenger's QR code. The phone buzzes when it reads one.
2. **Type the code.** If the screen is cracked, the light is bad or the passenger has no data, type the ticket code in the box and press the arrow (or the keyboard's Go key).

If the camera cannot start, the scanner says why in plain words, for example that camera permission is off, and the typing box still works.

A good ticket opens a green card:

<img src="images/conductor-verified.png" alt="A valid ticket: Ticket is valid, the passenger's name, seat chips, a large 4-character code, bus number, origin, destination and the seat map" width="360">

Check these three things:

1. **The name** matches the person in front of you.
2. **The seats** are the ones they are sitting in. The seat map below highlights them.
3. **The 4-character code** matches the code on the passenger's own screen. Ask them to read it out. It is shown very large on purpose.

## Approve boarding

When all three match, press the big green **Approve Boarding** button.

* The button shows a spinner while it saves, and cannot be pressed twice.
* A short message says "Boarding recorded".
* The ticket is now stamped with the time and your account. It can never board again.

If the phone has no signal, nothing is recorded. The card stays open with the message "Could not record boarding. Check your connection and try again." Press the button again when you are back online. It never pretends to have saved.

## When a ticket is refused

The app stops a ticket and tells you why:

| You see | It means |
|---|---|
| **Already boarded** | This ticket was already checked in. The message gives the time. Each ticket can board only once. |
| **Ticket not accepted: Trip expired** | The trip left more than 12 hours ago. |
| **Ticket not found** | The code is wrong, or the ticket was cancelled. |

<img src="images/conductor-already-boarded.png" alt="Already boarded: This ticket was already checked in at 6:31 AM. Each ticket can board only once." width="360">

Every refusal has a **Try again** button.

Two conductors cannot both approve the same ticket. The check and the stamp happen in one step on the server, so if you both press at the same moment, one of you gets "Already boarded".

## Report a delay

On the trip screen press the delay button.

<img src="images/delay-dialog.png" alt="Report Delay: quick choices of 15, 30, 45, 60 and 90 minutes, a box to type the minutes, and Cancel and Confirm buttons" width="300">

* Tap a quick choice (15, 30, 45, 60 or 90 minutes), or type a number from 1 to 600.
* Press **Confirm**. Passengers with a ticket are notified straight away, and the bus card in search shows "Running N minutes late".
* The arrival time shown in tracking moves by the same amount.

## Change the trip status

The trip screen also has buttons for the stages of the journey. Passengers see the status on their bus card and trip card, and **Track bus** appears for them while the bus is on its way.

## Passengers without the app

For someone walking up with cash or no phone, a conductor can create an **offline booking** for them. It makes a normal ticket for the seats chosen, so it can be scanned and checked like any other.

## The rules the app follows

* A ticket boards **once**. A second try is refused with the time of the first.
* A cancelled ticket is not found.
* A trip that departed more than 12 hours ago is refused.
* Approving needs a signed-in conductor or admin account.
* The record shows who approved each boarding (`boardedBy`) and when (`boardedAt`) on the ticket.

The database rules enforce this too, not just the app: a conductor can set `boardedAt` and `boardedBy` only once, and `boardedBy` must be their own account. See [Data and rules](Data%20and%20rules.md#who-can-do-what).
