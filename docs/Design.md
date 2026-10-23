# Design

The look of BusLink, and the rules every screen follows. The app is for people of every age and comfort with technology, so the rules are simple on purpose.

## On this page

* [Colours](#colours)
* [Type](#type)
* [The rules](#the-rules)
* [Shared pieces](#shared-pieces)
* [Languages](#languages)
* [Photo credits](#photo-credits)

## Colours

Bright red and clean white. Everything lives in `lib/utils/app_theme.dart`.

| Name | Value | Used for |
|---|---|---|
| Primary | `#BA181B` | Main buttons, prices, the logo |
| Primary dark | `#660708` | Headings on tinted panels |
| Primary light | `#E5383B` | Accents |
| Surface | `#F5F3F4` | Input fields and quiet panels |
| Background | `#FFFFFF` | Screens |
| Text | Black | All body text, for the strongest contrast |

Green is used only for good news (valid ticket, confirmed, seats available), amber for warnings (late, few seats), and red for problems. Colour is never the only signal. See the rules below.

## Type

* **Outfit** for headings, prices and big numbers.
* **Inter** for body text.

Nothing is set smaller than 12 pixels. Body text is 14 to 17.

## The rules

1. **Big targets.** Buttons and tappable rows aim for at least 48 pixels tall. The main action on a screen is one big red button.
2. **Words, not just colour.** Every status has an icon and a word as well as a colour. "Running 30 minutes late", not just an amber dot.
3. **Say what happened, and what to do.** Errors explain themselves in plain language ("Could not record boarding. Check your connection and try again."), not codes.
4. **Real names.** Show "Nuwara Eliya", never `nuwara_eliya`. Show times as "6:30 AM".
5. **One main thing per screen.** The ticket has one View button. Refund is a small link so it cannot be pressed by accident.
6. **Nothing pretends.** No fake ratings, no fake badges. If the app has not saved something, it says so.
7. **Everything can be read aloud.** Icon buttons have tooltips and labels. Seats announce themselves ("Seat 9, selected"). The big ticket code reads as one thing ("Verified code 4821").
8. **Works small.** Every screen is checked on a 390 pixel phone, with long names such as Nuwara Eliya.

## Shared pieces

| Piece | Where | What it is |
|---|---|---|
| `HomeHero`, `PopularJourneys`, `HowItWorks` | `lib/views/home/home_hero.dart`, `home_sections.dart` | The photo header with the search form, the journey cards (real prices and times) and the three steps |
| `DesktopNavBar`, `AppFooter`, `BlBottomBar` | `lib/views/layout/` | The white desktop top bar, the dark red footer with photo credits, the phone's bottom bar |
| `BL` | `lib/utils/bl_colors.dart` | The colours of the mockups, for new screens |
| `StatusChip` | `lib/views/admin/widgets/status_chip.dart` | Icon, word and colour for any status |
| `TripFormSteps` | same file | The 1, 2, 3 progress strip on the trip form |
| `BusTicketCard` | `lib/views/results/bus_list_screen.dart` | The result card in search |
| `BoardingPassCard` | `lib/views/booking/my_trips_screen.dart` | The trip card in My Trips |
| `TicketVerifiedCard`, `TicketRejectedCard` | `lib/views/conductor/conductor_dashboard.dart` | The conductor's answers |
| `DelayDialog` | `lib/views/conductor/conductor_trip_management_screen.dart` | Report a delay |
| `RefundProgress` | `lib/views/booking/refund_status_screen.dart` | Sent, In review, Decision |
| `LanguagePills` | `lib/views/widgets/language_selector.dart` | The three language buttons |
| `SplashScreen`, `StartupFailedScreen` | `lib/views/splash/splash_screen.dart` | The start-up screens. The web page draws the same picture in `web/index.html` |

The Google button uses the real four-colour Google "G" (`assets/images/google_g.png`, drawn from `google_g.svg`), bundled with the app so it does not depend on another website.

## The start-up screen

A short scene instead of a spinner: the logo, the name, and a bus driving from Colombo through Kandy to Ella while the app gets ready. It is on the design canvas as boards 35 and 36.

* It says what is happening in words ("Getting things ready"), says so when it is slow, and has a real error screen with one big button if the app cannot start.
* If the phone is set to reduce motion, nothing moves.
* It is always light, because the app always opens in light mode.
* It uses only movement that is cheap to draw (position and fade), so it does not slow down the start it is covering for.

See [Starting up](Starting%20up.md).

## Languages

English, Sinhala and Tamil. Words live in `lib/l10n/app_en.arb`, `app_si.arb` and `app_ta.arb`. `l10n.yaml` turns them into the `AppLocalizations` class. The language buttons are on the sign-in page and in the profile.

## Photo credits

The home screen and the design mockups use photographs of Sri Lanka from Wikimedia Commons. Five are bundled in `assets/images/home/` (the Ella train, Kandy, Galle, Nuwara Eliya and Sigiriya), resized for the web. The credit line below is shown in the footer of the desktop pages (`AppFooter.credits`).

| Photographer | Licence |
|---|---|
| A. Savin | Free Art Licence |
| Argenberg | CC BY 4.0 |
| calflier001 | CC BY-SA 2.0 |
| Bergentroll | CC0 |
| Prasanna Tharaka | CC BY-SA 4.0 |
| Alagiyawanna | CC0 |

Which photo is whose: Nine Arches Bridge near Ella (A. Savin), Temple of the Tooth in Kandy (Argenberg), Galle Fort (calflier001), tea hills near Nuwara Eliya (Bergentroll), Sigiriya (Prasanna Tharaka).

The repository does not record where the other photos in `assets/images/` (outside `home/`) came from. Check the origin and licence of any photo before reusing it.
