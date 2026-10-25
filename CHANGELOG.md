# Changes

What changed in each step, newest first. Each heading names the pull request it came from. The redesign was built as pull requests on top of each other (#2 to #7) and merged in that order on 22 October 2026.

## 25 October 2026

* **Conductor can verify the 4 character code.** Passengers are shown a 4 character code (and the confirmation screen's QR can hold it), but the conductor lookup only searched by the long ticket id, so a typed code said "Ticket not found". It now tries the id first, then the code (ignoring cancelled tickets). The verified-ticket box also read old field names and showed N/A for origin and destination; it now shows the real cities.

* **Text weights now work.** The fonts were variable files that start at weight 100, so every bold and medium style drew as thin text. Outfit, Montserrat and Cormorant are now static files with real weights (300 to 800), so headings are bold and body text is regular, as in the mockups. `Inter-Variable.ttf` was not a font at all (a saved web page from a failed download), so Inter is gone and those styles use Outfit.

* **"Stay Updated" prompt** is remembered on the device. After **Allow** it never comes back; after **Later** it waits a week. Before, it came back on every start.

## 24 October 2026 (checked while signed in)

The app was run against the local Firebase emulators (`scripts/seed_emulator.py` makes test accounts and a little data; build with `--dart-define=USE_EMULATOR=true`) and clicked through as a customer and as an admin. It found three things the tests could not:

* The admin side menu had yellow double underlines under every label (it sat outside any `Material`). Fixed.
* The "Stay Updated" notification prompt could appear twice, and came back after tapping Later, because two screens asked. It now asks once per run.
* The values in the My Trips detail card (time, bus, platform, seats) did not line up on the right. Fixed.

## 23 October 2026 (the designs, screen by screen)

The first redesign pass kept most of the old screens and only dressed some of them. This pass builds each screen from its mockup board, on phone and on desktop, one batch at a time.

### Platform number, "Next stop" and polish

* **Platform number** is real now and optional. Admins can type it on the trip form and on the schedule dialog (schedules pass it to the trips they generate). It is saved on the trip and copied onto the ticket. The confirmation, ticket, PDF, My Trips and bus details show it only when it is set, so nobody sees a made-up number. The old "TBD" value counts as not set.
* **Next stop** on the tracking sheet is a timetable estimate: the route's stops spread evenly along the journey, so it says "Next stop: X, about N min". It is not a live GPS reading.
* Buttons and cards that set their own text style lost the Outfit font and fell back to the system font; they keep Outfit again. The swap button on the search card has a cleaner ring, and the failed-payment card's button reads "Get help" so it no longer wraps.

### Admin page bodies and the "almost here" tracking state

* **Trips** (`Desktop-Admin`): a real table of the next 30 days of trips (route with photo, leaves, bus, seats taken, status chip, Edit, Seats, Delete). Deleting says how many seats are already booked before it asks you to confirm. The old trip search stays below it. The three-step trip form already matched `Desktop-AdminTripForm`.
* **Routes and schedules** (`Desktop-AdminRoutes`): two pill tabs and tables, with Add Route, Add Schedule, Edit, Generate Trips and Delete. **Users and roles** (`Desktop-AdminUsers`): a search box, a table with a role chip, Edit User and Delete, and Add User.
* **Bookings** (`Desktop-AdminBookings`, `Desktop-AdminBookingDetails`), **Refunds** (`Desktop-AdminRefunds`, `Desktop-AdminRefundDetails`), **Feedback** (`Desktop-AdminFeedback`) and **Analytics** (`Desktop-Analytics`, `Desktop-AdminLate`) follow their boards: red page headers on phones, big titles on desktop, bordered cards, pill tabs and status chips with words. The reject-refund box now has its title and question back (they had been commented out) and a reason menu that must be chosen.
* **Tracking**: within five minutes of arriving the page shows "Your bus is almost here", "4 min away" in red and a **Show my ticket** button.

### Conductor and admin

* **Conductor** screens (`Conductor`, `ConductorStatus`, `ConductorVerify`, `ConductorDelay`) were already built from their boards in the first redesign pass and are unchanged here.
* **Admin on a wide screen** now has the dark red side menu from `Desktop-Admin`: Dashboard, Trips, Routes, Bookings, Refunds, Feedback, Analytics, Users and roles, plus Passenger view, Conductor view and Log out. Every admin page sits inside it (`AdminShell`); the old top bar only shows on phones. The Trips page header is now "Upcoming trips" with one **Add new trip** button, and the row of seven duplicate buttons is gone. The phone's admin bottom bar matches the passenger one.
* Pictures in `docs/images/` were regenerated from the real widgets.

### Account, sign-in, support and bulk booking

* **Favourites** (`Favourites`, `Desktop-Favourites`): photo cards with a big remove heart and BOOK AGAIN; a kind empty state. **Notifications** (`Notifications`): round coloured icons, plain words, a red dot and blush background for new ones. The old filter that hid booking and trip updates is gone, because the design shows them.
* **Profile** (`Profile`, `Desktop-Profile`), **Account Settings**, **Notification Settings**, **Travel Trends** and **Feedback** follow their boards. The feedback box now has "Send as Anonymous" (it really sends without your name) and the ticket page uses the same box. Linked accounts shows the real Google logo.
* **Sign in, sign up, phone and code** (`Login`, `Desktop-Login`, `SignUp`, `PhoneLogin`, `Otp`): the Ella train photo, three big language buttons, one form for both sign in and sign up, and a wrong-code message under the six boxes. The old rotating web photos are gone. **Forgot Password?** now works: it emails a reset link to the address you typed (the button used to do nothing).
* **Support** (`Support`, `Desktop-Support`): FAQ, call and email buttons, hotlines, and a message form. The form now opens your email app with the message ready (it used to say "Message Sent Successfully" without sending anything). Two old, unused support screens were removed.
* **Bulk booking** (`BulkPassengers`, `BulkSummary`): the passenger picker and the summary follow the boards. The date picker already matched `BulkDates`.

### My Trips, refunds and tracking

* **My Trips** (`MyTickets`, `Desktop-MyTickets`): a red header with three numbers (Trips taken, Coming up, Top place) and the four tabs; each trip is a card with the destination photo, a status chip (icon and word), **VIEW TICKET** and **TRACK NOW**, and the quiet Refund link. On desktop it is a list on the left (the picked trip has a red outline) and the full ticket with its QR code on the right. Empty tabs now say something kind ("No cancelled trips. Good news.").
* **Refund** (`Refund`, `RefundStatus`, `RefundRejected`): a trip summary, the policy in plain words, a reason menu, a big "YOU RECEIVE" amount and Submit Request. The status page shows Sent, In review, Decision inside a coloured card (amber, green or red), the money breakdown, and for a rejected refund the reason, your ticket ID and a Contact support button.
* **Tracking** keeps its map and ETA card; on wide screens the card now floats on the left of the map. Not built: the "bus almost here" state (needs the passenger's boarding stop, which the app does not store) and "Next stop" (the app does not store stops per trip).

### Booking screens: results, bus details, seats, payment, confirmation, ticket

* **Results** (`Results`, `Desktop-Results`): a photo banner for the destination, a "Narrow it down" panel (time of day, type of bus, hide full buses), and cards with Leaves, Arrives, price, seats left and one **Book Now** button. Delayed buses say "Running 30 minutes late"; full or cancelled buses become a quiet grey card that says so and sink to the bottom. The map, weather and clock header are gone (they are not in the designs).
* **Bus details** (`BusDetails`) is now a real screen, reached from "Stops and what is on the bus" on a result card. It lists the stops and what is on the bus. The old screen was never opened from anywhere. The mockup's platform number is left out because the app has no real platform data.
* **Seats** (`Seats`, `Desktop-Seats`): plain Free / Yours / Taken key, each with a shape as well as a colour, a flat seat map, "You can pick up to 6" (now enforced), and on desktop a summary card with the photo, your seats and the total.
* **Payment** (`Payment`, `Desktop-Payment`, `PaymentStates`): booking summary with the destination photo, one card-payment choice, "Proceed to Pay · LKR 2,400", and the three states from the mockup: Verifying, Verification Failed ("Your seats are not lost") and Session Expired.
* **Confirmation and ticket** (`Ticket`, `Desktop-Confirmed`): the red page with the white ticket, a big QR code, the 4-digit code, and Download PDF, Share via SMS and Go to My Trips. The same face is used when you open a ticket from My Trips. Saving the route to Favourites is still one tap.
* 3 new tests, and the older ones updated to the new words.

### Home, top bar, footer and bottom bar

* **Home** follows the boards "Main" and "Desktop-Home": the Ella train photo with the crimson wash, "Where would you like to go?" on phones and "Travel Sri Lanka by bus, the easy way" on desktop, and a white search card with named fields (Leaving from, Going to, Day of travel), a swap button between the cities and one big Search Buses button. Choosing the same city twice now says "Pick two different places" instead of a raw key.
* **Popular journeys** are four photo cards (Kandy, Galle, Nuwara Eliya, Polonnaruwa). The price and time on each card are the cheapest fare and the journey time from the real routes and schedules; a place with no bus yet shows no price. The old cards used stock photos from the internet and a made-up "buses daily" number from a random generator. Tapping a card searches Colombo to that place. "How it works" (three steps) is on desktop.
* **The desktop top bar** is the white bar from the mockups: BusLink, Home, My Trips, Favourites, Support, the traveller's initials (with the account menu) and a plain Log out button. **The footer** is dark red with the photo credits the licences require (the old footer had links to pages that did not exist). **The phone's bottom bar** is 80 px high with a blush pill behind the current page.
* Removed: the home screen's rotating web photos, the old features strip, the unused round-trip leftovers, the unused `MobileBottomNav`, and lower-case city names (`nuwara_eliya`) in the suggestion list.
* Five photos (about 0.9 MB) are bundled in `assets/images/home/`. New file `lib/utils/bl_colors.dart` holds the mockup colours. 6 new tests.

## 24 October 2026 (hosting)

* **Netlify is switched off for this repository.** It had been building a deploy preview on every pull request with no Flutter build set up, so every preview was a blank "Page not found". `netlify.toml` now tells it to skip builds. Vercel stays the only host (the live site and the previews). To remove the Netlify checks completely, delete the `neon-cocada-9d5a9e` site in the Netlify dashboard.
* **Vercel skips builds that cannot change the app** (changes to documentation, tests or CI only): `ignoreCommand` in `vercel.json` compares `lib`, `web`, `assets`, the pubspec files, the build script and `api`. Faster, and less build time used.

## 23 October 2026 (rules, cleanup, licence, project structure, the README story and starting up)

### Starting up (#13)

* **An animated start-up screen** replaces the spinner: the logo pops in, then a bus drives from Colombo to Kandy to Ella while the app gets ready. It is on the design canvas (boards 35 and 36), drawn by the web page from the first paint and by Flutter on phones and desktop. After 8 seconds it says "Still getting ready"; if the app cannot start it shows "We couldn't start BusLink" with a Try again button. It holds still if the phone is set to reduce motion.
* **Start-up runs in parallel** (`AppStartup`). Only Firebase can stop the app. Push notifications, Stripe and Google sign-in now start after the first screen. Signed-in people no longer see the sign-in page flash up, and a returning person's home screen shows at once from the role remembered on the device (it was never actually saved before).
* **A lighter first load:** the unused Noto Sans font (1.1 MB compressed) and an unused 895 KB image are gone; the sign-in slideshow loads only the photo on screen, at web size; Firebase's scripts start downloading with the app; Stripe's script no longer holds the page up; fonts and images are reused for a day.
* **Measured** cold, on a slowed-down phone profile, on the preview and on the live app: the first readable screen at 2.5 s instead of 6.0 s, the sign-in photo at about 7.5 s instead of 9 to 11 s, and 0.5 to 0.7 MB downloaded instead of 3.2 MB. The app's own first frame and the sign-in screen did **not** get measurably faster: that wait is the app and its graphics engine downloading, which this change does not shrink. See [Starting up](docs/Starting%20up.md).
* `main.dart` went from 532 lines to about 15. The rest is in `lib/app/`. 22 new tests.
* New page: [Starting up](docs/Starting%20up.md).

### The README tells the story

* The README now reads as one story in twelve numbered steps: the passenger (sign in, find a bus, seats, pay, My Trips, refunds), the conductor (check a ticket, once only, running late) and the admin (add a trip, bookings and refunds, roles). Each part leads into the next, and every step has a picture.
* A hero animation (`docs/images/journey.gif`) opens the README, and a real screenshot of the live sign-in page is step 1. The real Flutter, Dart, Firebase, Google, Stripe and Vercel logos are in a "What it is built with" table.
* A social preview image (`docs/images/social-preview.png`) for the repository.
* `tool/make_story_images.py` makes the animation and the social image from the pictures.

### Database rules fixed, tested and deployed (#9)

* **The rules that were live had real holes, and the rules in the repository would have broken the app.** The live rules let anyone write their own `role` (so any signed-in person could make themselves an admin), edit the price, seats and owner of their own ticket, and mark it boarded. The repository's rules fixed that but refused the ticket update that confirms a payment, so deploying them would have stopped every booking.
* New `firestore.rules`: roles can only be set by an admin, a passenger can confirm payment and request a refund on their own ticket but not change its owner, price, seats or boarding, a conductor can stamp a boarding once as themselves, and conductors can create the notifications that tell passengers about a delay (the live rules refused those). `firestore.rules.proposed` is folded in and removed.
* **`tool/rules-test`:** 43 cases in the Firebase emulator, run on every pull request as the `rules` job.
* **Deployed to the BusLink Firebase project and checked:** the live rules equal the repository file.
* The three demo accounts whose password (`123456`) was public in the git history had their passwords changed.
* The Firebase web API key is now restricted to this project's web addresses.
* Docs: the Stripe minimum is about 50 US cents (around LKR 165), not LKR 150; SECURITY.md lists the open items, including that payment is confirmed by the app.

### Repository cleanup (#10)

* Removed ten one-off Python scripts from the top level (`final_fix.py`, `fix_*.py`, `repair_*.py`, `restore_ui_text.py`) that were used once to rewrite source files, and 90 Xcode build cache files under `scripts/build/`. Nothing used them, and git history still has them. `scripts/build/` is now git-ignored.

### Licence (#11)

* Added the MIT licence (`LICENSE`), the same one as the media-server-setup repository, and a licence badge in the README.

### Project structure (#8)

* **Checks on every pull request** (`.github/workflows/checks.yml`): the docs check, `flutter analyze` and `flutter test`, with the **Checks** badge in the README.
* `tool/check_docs.py` checks every link, picture and heading link in the docs, and that the README links to every page in `docs/`.
* Issue forms (**Something is not working**, **An idea**) and a pull request checklist.
* New pages: [Getting started](docs/Getting%20started.md), [How it works](docs/How%20it%20works.md) (for people changing the code) and [Data and rules](docs/Data%20and%20rules.md).
* `.gitattributes` so line endings stay consistent.

## 22 October 2026: the redesign (#2 to #7, live)

### Documentation and polish (#7)

* A full rewrite of the README and a set of guides in `docs/`: [Passenger](docs/Passenger%20guide.md), [Conductor](docs/Conductor%20guide.md), [Admin](docs/Admin%20guide.md), [Installing](docs/Installing.md), [Deploying](docs/Deploying.md), [How everything fits](docs/How%20everything%20fits.md), [Design](docs/Design.md), [Testing](docs/Testing.md), [Fixing problems](docs/Fixing%20problems.md) and [Questions and answers](docs/FAQ.md), plus [SECURITY.md](SECURITY.md) and [CONTRIBUTING.md](CONTRIBUTING.md).
* Pictures in the docs are drawn by the real widgets (`tool/doc_screenshots_test.dart`).
* **Real Google "G"** on the sign-in button. It was loaded from another website and could silently disappear. It is now bundled with the app.
* **Fix:** on a 390 px phone, a bus card with long city names (for example "Nuwara Eliya") overflowed by a few pixels in the time line. City names now shorten with "..." and the bus line keeps its width. A test covers it.

### Admin: status chips and a three-step trip form (#6)

* Every status in booking rows and refund cards is an icon, a word and a colour. A checked-in ticket shows **Boarded**.
* The trip form is split into Route, Schedule and Fare and bus, with a step indicator. Saving, validation and the saved data are unchanged.

### Conductor: boarding is recorded, and can happen only once (#5)

* **Approve Boarding** stamps the ticket with `boardedAt` and `boardedBy` in a single Firestore transaction.
* A ticket that was already boarded is refused with "Already boarded" and the time. This is checked when the ticket is looked up and again when it is approved, so two conductors cannot both succeed.
* The button shows a spinner while saving. If there is no connection, the card stays open with a retry message instead of pretending it worked.
* `firestore.rules.proposed` held an optional rule so a boarding can be stamped only once. It has since been folded into `firestore.rules` and removed (see the 23 October entry above).

### Conductor screens (#4)

* A much bigger verify card: the passenger's name, seat chips, the 4-digit code in very large type, and the seat map.
* A clear "Ticket not accepted" card with **Try again**.
* The scanner can take a typed ticket code, gives friendly camera errors and buzzes on a scan.

### Passenger screens (#3)

* **Bus cards:** real city names, 12-hour times, trip length, a status banner (late, cancelled, full) in words, "N seats left". The invented "Highly Rated" badge was removed.
* **Seat map:** bigger seats, a tick on yours, taken seats grey with a cross, spoken labels for every seat.
* **My Trips:** one big **View** button, **Track bus** only when useful, a quiet **Refund** link, icon badges.
* **Home:** on phones, a greeting and your trips come first.

### Accessibility pass (#2)

* Tooltips on 24 icon buttons. Nothing is smaller than 12 px.
* A friendlier delay dialog (quick choices of 15, 30, 45, 60 and 90 minutes, 1 to 600 typed).
* A three-step refund progress line (Sent, In review, Decision) and an error state.

## Before the redesign

### Demo, tracking and security fixes (#1)

* **Live demo** on Vercel at https://buslink-eta.vercel.app, built with a pinned Flutter 3.38.9. The build stops on any error so a failed build cannot replace a working site. A health check runs every six hours.
* **Tracking** redesigned: a full-screen map, one calm card with the time left, a pulsing bus marker, Share and re-centre.
* **Sign-in page:** English, Sinhala and Tamil buttons at the top, and a red Log In button.
* **Security:**
  * Admin credentials were removed from the README.
  * The hidden debug login now exists only in developer builds.
  * Rules in the repository no longer let a user choose or change their own role (they must be deployed to take effect).
* Faster start-up: the app draws early from a cached profile, and Google Sign-In is set up lazily.
