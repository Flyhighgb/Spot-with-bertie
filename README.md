# Spot with Bertie

A kids' spotting app for iOS and Android: find things at the airport, the park and the train station with Bertie the plane.

No ads and no accounts. The Airport pack is free; the Park and Train station packs are 99p each, or £5.99 for a family pass that includes every pack. Seaside is coming soon.

## What's in the app

- **Island map** with a stop for each pack. Bertie flies beside the pack you're playing.
- **Pack screen** with all 24 things to spot, their points (5, 10, 25 or 50) and a fun fact for each. One thing a day is the golden spot, worth double.
- **Badges**: bronze at 50 points, silver at 125 and gold at 200, with a certificate for gold.
- **Sticker album** showing everything spotted and the date.
- **Grown-ups only** question (a times-table sum) before buying, restoring purchases or clearing progress.

Purchases are pretend for now (`PretendPurchases` in `lib/services/purchases.dart`): they unlock straight away and charge nothing. Real App Store and Google Play billing replaces that one class.

## Trying it

Every push runs the checks and makes test builds on GitHub (Actions tab, then the latest run, then Artifacts):

- `spot-with-bertie-android`: an APK to install on an Android phone.
- The web version, published to GitHub Pages from `main` once Pages is set to "GitHub Actions" in the repo settings.

To run it yourself, install [Flutter](https://docs.flutter.dev/get-started/install) and run:

```sh
flutter pub get
flutter run
flutter test
```

## Where things live

- `lib/data/items.dart`: every item, its points and fact.
- `lib/data/packs.dart`: the packs, prices and where they sit on the map.
- `lib/data/progress.dart`: points, badges and saving (on the device only).
- `lib/ui/screens/`: the map, pack, album and badges screens.
- `assets/images/`: the art, made with Canva AI.
- `assets/fonts/`: Outfit and Nunito, under the SIL Open Font License.
