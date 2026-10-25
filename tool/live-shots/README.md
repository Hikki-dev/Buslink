# Live shots

Takes the whole-screen pictures in `docs/images` from a running web build of the app, signed in as each test person. The steps are in [Testing](../../docs/Testing.md#remake-the-pictures-in-the-docs), and the test people are in [Try it on your computer](../../docs/Try%20it%20on%20your%20computer.md).

You need Node.js 18 or newer, Google Chrome (the scripts use the one that is installed, so nothing is downloaded), and the pretend Firebase with the seed data.

## How it works

* `lib.js` opens one headless Chrome at a fixed size and sharpness, then switches on Flutter's accessibility tree. The tree gives every button its label and place, so the script can say "tap **Search Buses**" instead of using pixel positions. This also checks that every control can be used without seeing it.
* `capture.js` is a list of scenes. Run one with `node capture.js <desktop|phone> <scene>`. Each scene signs in as a person and saves a picture at every screen, and writes the names on screen to `labels-*.txt` so a failing step is easy to fix.
* `finish.py` renames the pictures for the docs and saves them as PNG (or a very high quality JPEG when a photo makes the PNG too big).

The computer size is 1600 by 1000 at twice the sharpness (3200 by 2000 pixels). The phone size is 390 by 844 at three times (1170 by 2532 pixels).

## Scenes

| Scene | Who | Pictures |
|---|---|---|
| `passenger` | Customer | sign in, search, favourites, results, bus details, seats, payment |
| `account` | Customer | My Trips, ticket, tracking, refund, travel numbers, notifications, account menu |
| `profile` | Customer | profile, settings, support (computer) |
| `phoneAccount`, `phoneProfile` | Customer | the same screens at phone size |
| `admin`, `adminPhone`, `adminMore` | Admin | every admin page |
| `conductor` | Conductor | scan, verified, boarded, find a trip |
| `otp` | Nobody | phone sign-in: the code boxes, empty and filled (the code is read from the pretend Firebase) |
| `boardTwice` | Conductor | approve a boarding, then try the same ticket again |
| `refundSubmit` | Customer | the list of refund reasons |
| `empty` | Newcomer | My Trips, Favourites and Notifications with nothing in them |
| `bulk` | Customer | booking several days: calendar, passengers, summary |
| `confirmed` | Customer | Booking Confirmed, reached the way Stripe's return link reaches it |
| `adminPhoneMore` | Admin | a booking's details on a phone |
| `extras` | Nobody | sign up, phone login |

## Things to know

* Run `python3 scripts/seed_emulator.py` before each scene, so every scene starts from the same data.
* The card form is Stripe's own page, so the scenes stop at the page before it. The page Stripe sends people back to (Booking Confirmed) is reached by going straight to its address, using a waiting ticket from the seed script.
* The picture of a map may be grey when the computer is offline.
