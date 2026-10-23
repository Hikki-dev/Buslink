# Changes

What changed in each step, newest first. Each heading names the pull request it came from. The redesign was built as pull requests on top of each other (#2 to #7) and merged in that order on 22 October 2026.

## 23 October 2026 (rules, cleanup, licence, project structure and the README story; all live)

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
