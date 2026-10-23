# Contributing

Thank you for helping. This is a small project, so the rules are short.

## Set up

```bash
git clone https://github.com/Hikki-dev/Buslink.git
cd Buslink
flutter pub get
```

Follow [Installing](docs/Installing.md) to connect your own Firebase project and make a `.env` file. Use **Stripe test keys** only.

## Make a change

1. Create a branch: `git checkout -b my-change`.
2. Make the change. Keep it small and about one thing.
3. Run these. They must pass, and the same three run on every pull request:

   ```bash
   flutter analyze
   flutter test
   python3 tool/check_docs.py
   ```

   `test/widget_test.dart` was already failing before the redesign work and is not expected to pass. See [Testing](docs/Testing.md).
4. Open a pull request. The template asks what changed, how you tested it and a short checklist. Fill it in.

Found a problem or have an idea but not a fix? Open an issue. There are two short forms: **Something is not working** and **An idea**.

## Rules for the code

* **Add a test** for anything with a rule in it: a decision, a calculation, a state a person can reach. Put the rule in a small function that does not need a database, as `decideBoarding` does, and test that.
* **Follow the design rules** in [Design](docs/Design.md): big targets, words and icons as well as colour, plain error messages, real city names, nothing smaller than 12 pixels.
* **Check the screen on a 390 pixel phone** with a long city name such as Nuwara Eliya.
* **Do not put secrets in the app.** Anything in `.env` is bundled into mobile and desktop builds. See [Security](SECURITY.md).
* **Do not change behaviour in a visual change.** If a screen is being restyled, the saved data, the rules and the flows stay the same. Put behaviour changes in their own pull request.
* **Keep words in the language files** (`lib/l10n/*.arb`) when a screen already uses them.

## Pull requests that build on each other

Large changes are split into small pull requests that sit on top of each other (each one is opened against the one before). Merge them in order, oldest first. After the first one is merged, GitHub moves the next one onto `main` by itself.

## Changing the database rules

Any change to `firestore.rules` should come with the reason, and should be checked with the rules validator or the Firebase emulator before it is deployed. If a rule change is optional, put it in a separate file for review, as `firestore.rules.proposed` does.

## Documentation

If a change alters something a person sees, update the page that describes it and add a line to [CHANGELOG.md](CHANGELOG.md). Read [How it works](docs/How%20it%20works.md) for where things live. `python3 tool/check_docs.py` checks every link and that the README links to every page in `docs/`, so add a new page to the README's help table.

## Pictures in the docs

Do not edit the PNG files in `docs/images/` by hand. Redraw them with the command in [Testing](docs/Testing.md#remake-the-pictures-in-the-docs).

## Licence

The project has no licence file yet, so by default all rights are reserved by the author. If you plan to contribute code, ask the owner to choose a licence first.
