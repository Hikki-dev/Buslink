# Changes

What changed in each step, newest first. The pull requests were built on top of each other, so they are listed in the order they should be merged (oldest at the bottom).

## Unreleased

Everything below is in pull requests that are open until they are merged. Merge them oldest first.

### Documentation and polish (this change)

* A full rewrite of the README and a set of guides in `docs/`: [Passenger](docs/Passenger%20guide.md), [Conductor](docs/Conductor%20guide.md), [Admin](docs/Admin%20guide.md), [Installing](docs/Installing.md), [Deploying](docs/Deploying.md), [How everything fits](docs/How%20everything%20fits.md), [Design](docs/Design.md), [Testing](docs/Testing.md), [Fixing problems](docs/Fixing%20problems.md) and [Questions and answers](docs/FAQ.md), plus [SECURITY.md](SECURITY.md) and [CONTRIBUTING.md](CONTRIBUTING.md).
* Pictures in the docs are drawn by the real widgets (`tool/doc_screenshots_test.dart`).
* **Real Google "G"** on the sign-in button. It was loaded from another website and could silently disappear. It is now bundled with the app.
* **Fix:** on a 390 px phone, a bus card with long city names (for example "Nuwara Eliya") overflowed by a few pixels in the time line. City names now shorten with "..." and the bus line keeps its width. A test covers it.

### Admin: status chips and a three-step trip form

* Every status in booking rows and refund cards is an icon, a word and a colour. A checked-in ticket shows **Boarded**.
* The trip form is split into Route, Schedule and Fare and bus, with a step indicator. Saving, validation and the saved data are unchanged.

### Conductor: boarding is recorded, and can happen only once

* **Approve Boarding** stamps the ticket with `boardedAt` and `boardedBy` in a single Firestore transaction.
* A ticket that was already boarded is refused with "Already boarded" and the time. This is checked when the ticket is looked up and again when it is approved, so two conductors cannot both succeed.
* The button shows a spinner while saving. If there is no connection, the card stays open with a retry message instead of pretending it worked.
* `firestore.rules.proposed`: an optional, reviewable tightening so a boarding can only be stamped once. `firestore.rules` itself is not changed. See [Security](SECURITY.md#the-proposed-boarding-rule).

### Conductor screens

* A much bigger verify card: the passenger's name, seat chips, the 4-digit code in very large type, and the seat map.
* A clear "Ticket not accepted" card with **Try again**.
* The scanner can take a typed ticket code, gives friendly camera errors and buzzes on a scan.

### Passenger screens

* **Bus cards:** real city names, 12-hour times, trip length, a status banner (late, cancelled, full) in words, "N seats left". The invented "Highly Rated" badge was removed.
* **Seat map:** bigger seats, a tick on yours, taken seats grey with a cross, spoken labels for every seat.
* **My Trips:** one big **View** button, **Track bus** only when useful, a quiet **Refund** link, icon badges.
* **Home:** on phones, a greeting and your trips come first.

### Accessibility pass

* Tooltips on 24 icon buttons. Nothing is smaller than 12 px.
* A friendlier delay dialog (quick choices of 15, 30, 45, 60 and 90 minutes, 1 to 600 typed).
* A three-step refund progress line (Sent, In review, Decision) and an error state.

## Already live

### Demo, tracking and security fixes

* **Live demo** on Vercel at https://buslink-eta.vercel.app, built with a pinned Flutter 3.38.9. The build stops on any error so a failed build cannot replace a working site. A health check runs every six hours.
* **Tracking** redesigned: a full-screen map, one calm card with the time left, a pulsing bus marker, Share and re-centre.
* **Sign-in page:** English, Sinhala and Tamil buttons at the top, and a red Log In button.
* **Security:**
  * Admin credentials were removed from the README.
  * The hidden debug login now exists only in developer builds.
  * Rules in the repository no longer let a user choose or change their own role (they must be deployed to take effect).
* Faster start-up: the app draws early from a cached profile, and Google Sign-In is set up lazily.
