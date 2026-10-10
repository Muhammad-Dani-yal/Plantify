# Build and engineering notes

This document preserves the detailed verification and toolchain notes from version 1.0.1. Historical APK sizes and deployment status below describe that build. For current deployment/security status, see [README](../README.md) and [Release setup](RELEASE.md). The current distributed APK is `Plantify.apk` at the repository root.

## Earlier engineering notes

A Flutter plant discovery and care app connected to Firebase Authentication and Cloud Firestore. Android and Web use the `plantify-00` project.

## What works

- Real email/password signup, sign-in, session restoration, sign-out, verification email requests, and password reset requests.
- 100 searchable plant profiles with bundled images, descriptions, light/soil/watering guidance, and care guides.
- Discover shows matching downloaded plants first in a lazy grid, then online botanical records, without duplicate bundled species. Both sections respect the collection and name filters; online results continue loading automatically as you scroll.
- Online photo cards have rounded, clipped frames and themed backgrounds. Full plant profiles preserve the whole photograph rather than cropping it.
- A live worldwide botanical catalogue powered by the GBIF Taxonomic Backbone, with species/subspecies/variety/all-name filters, optional synonyms, paginated search and account-specific saved world plants.
- Search by common name, botanical name, care terms, or collection; combined filters and sorting.
- Curated collections, a plant matching quiz, random discovery, related plants, and comparison of up to three plants.
- Account-specific favourites and a personal garden, editable notes, watering records, and soil-check suggestions.
- Firestore sync across devices, visible sync errors with retry, and account isolation when signing out.
- A welcome slideshow with pause/manual controls, animated gradient buttons, responsive navigation, richer botanical colours, and dark mode.

There is no local account bypass. Authentication must succeed before an account session opens. Passwords are handled by Firebase Auth and never written to Firestore or SharedPreferences.

## Run and verify

### Compact Android build

Bundled images use WebP: all 100 plant images and the welcome image total 5,053,774 bytes, down from 24,864,301 bytes. Catalogue photos retain up to 640 pixels on their longest side, matching the card decoder size; featured illustrations retain 1024 pixels and the welcome hero 1280 pixels. Photo credits and licences are preserved.

Measured version 1.0.1 build 2 APK sizes (decimal MB):

| APK | Download size | Use |
| --- | ---: | --- |
| Previous universal debug | 242.96 MB | Development only |
| Standard ARM64 release | 25.27 MB | Lower installed storage; installed on the connected phone |
| Compact ARM64 release | 15.42 MB | Smallest download; native libraries are extracted on installation |
| ARM32 release | 22.59 MB | Older ARM32 phones |
| x86-64 release | 26.44 MB | x86-64 devices/emulators |

The compact APK is 93.7% smaller than the previous debug APK. The standard and compact ARM64 APKs contain byte-identical Dart AOT code, Flutter engine and Java/Kotlin bytecode. Both include all 101 images, verified against their source hashes. Installed storage includes app data and differs from APK download size.

Use optimized, architecture-specific release APKs for installation, rather than the large universal debug APK. R8 code shrinking, Android resource shrinking and Flutter icon tree shaking remain enabled. This follows [Flutter's Android build guidance](https://docs.flutter.dev/deployment/android#build-an-apk).

```sh
flutter build apk --release --split-per-abi
```

`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` is for modern ARM64 phones, including the connected CPH2449. `app-armeabi-v7a-release.apk` supports older ARM32 phones; `app-x86_64-release.apk` is for x86-64 devices/emulators. Do not merge these APKs into one universal package when minimizing download size. Store signing still requires the owner's keystore.

Run `powershell -File tool/verify_release_apk.ps1` to verify release libraries, a single architecture, and hashes of all 101 packaged images against the project. Image decoding is covered by the Flutter regression suite.

For an even smaller ARM64 download, run `powershell -File tool/build_compact_apk.ps1`. This passes the opt-in `plantifyCompactApk` Gradle property explicitly and creates `app-compact-arm64-release.apk` with compressed native libraries. Android extracts those libraries during installation, so this variant uses more installed storage than the standard ARM64 APK, while running the same app code. The default build keeps direct native-library loading for lower installed storage; see [Android's packaging guidance](https://developer.android.com/guide/practices/page-sizes). Verify the compact variant with `powershell -File tool/verify_release_apk.ps1 -Apk build/app/outputs/flutter-apk/app-compact-arm64-release.apk`.

To optimize newly added PNG/JPEG assets, install the encoder with `npm install --prefix build/asset-optimizer sharp`, then run `node tool/optimize_images.cjs`. Original images are backed up under the ignored `build/asset-originals` directory; `--from-originals` re-encodes from those originals rather than recompressing a previous WebP. The catalogue generator recognizes existing WebP assets.

### Development checks

```sh
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
flutter build web
```

Firebase configuration is in `lib/firebase_options.dart` and `android/app/google-services.json`. The web app was registered in the same Firebase project; Email/Password auth is enabled, and owner-only Firestore rules have been deployed.

For Android, use JDK 17. Flutter on this machine is now configured to use `C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot`, which fixes the `flutter-plugin-loader > 25.0.3` failure. This Flutter setting applies to all Flutter projects on this machine. Restart an already-open editor so its Flutter process reads the new configuration. To reproduce the setup on this computer:

```powershell
flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot"
flutter doctor -v
flutter pub get
flutter run
```

On another computer, pass its installed JDK 17 directory instead. For a direct Gradle build:

```powershell
$env:JAVA_HOME='C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot'
Set-Location android
.\gradlew.bat :app:assembleDebug --no-daemon
```

Android uses Gradle 8.12, AGP 8.7.3, Kotlin 2.3.10, Java 17, minSdk 23, and application ID `com.muhammaddaniyal.plantify`. Kotlin was updated to match the current Firebase Auth Android library metadata; the versions fit the [Kotlin Gradle compatibility table](https://kotlinlang.org/docs/gradle-configure-project.html).

Flutter's Android Gradle tasks explicitly track the project's Dart sources, assets, and package manifests. This prevents stale APK contents when dependency parsing encounters escaped spaces in this workspace path. APK verification checks the packaged Dart kernel for the current photo, motion-icon, and AI-guide code; a successful Gradle exit alone is insufficient.

D8/R8 is pinned to 8.13.19 through the [official R8 override mechanism](https://r8.googlesource.com/r8/+/main#Replacing-R8-in-Android-Gradle-plugin) in `android/settings.gradle`. This supports Firebase's Kotlin 2.3 metadata while retaining the AGP version used by this Flutter SDK; see [Android's compiler compatibility table](https://developer.android.com/build/kotlin-support).

After moving the project between computers, run `flutter clean` and `flutter pub get` before building. Generated plugin registration and build stamps must belong to the current workspace. Kotlin incremental compilation is disabled because this Windows workspace and the Pub cache are on different drives.

If `pub get` reports that desktop plugins need symlink support on Windows, run `powershell -ExecutionPolicy Bypass -File tool/repair_plugin_links.ps1` and then `flutter pub get` again. The helper creates local directory junctions from generated plugin metadata; it does not change Windows Developer Mode. After `flutter clean`, generated links may need to be recreated.

Unused legacy theme classes, 63 old images, and the unused Realtime Database dependency have been removed. Cupertino Icons is retained because Flutter's adaptive widgets reference its font indirectly. Authentication uses Firebase Auth; account data uses Cloud Firestore.

## Firebase data

Each authenticated account owns `users/{uid}`:

| Field | Data |
| --- | --- |
| name, email | Profile identity |
| favourites (stored as favorites) | Plant ID list |
| garden | Map keyed by plant ID, containing notes and last-watered ISO date |
| dark, hints | Account preferences |

Firestore rules allow access only when the authenticated UID matches the document owner. No public test-mode rule remains. Favourite changes use atomic array operations; note and watering updates merge individual fields so they do not overwrite each other.

Device preferences store only onboarding/theme/hint settings. The old local demo collection/session is not treated as an authenticated account. Web sync uses the Firebase SDK cache; persistent browser storage is not explicitly enabled. Android also uses the SDK's default offline cache.

## Catalogue and credits

### World catalogue

Discover and Search now open the worldwide catalogue directly. **All plants** includes records even when no photograph is available; **Browse care profiles** opens the 100 bundled care profiles. Search common/scientific names, genera and families, choose a taxonomic rank, and include synonyms/older names when needed. **My world plants** contains cloud bookmarks; the Favorites page also links to this collection.

The [GBIF Species API](https://techdocs.gbif.org/en/openapi/v1/species) is queried under Plantae using its taxonomic backbone dataset. A live check on 9 October 2026 returned 446,842 accepted species records. These are taxonomic records, may include fossil species, and do not constitute a guaranteed complete inventory of every living plant or cultivar. Internet access is required for worldwide search. Results load automatically near the end of the scroll; only visible grid cards request photos. Paging errors retain existing results and offer retry for the failed batch. Provider paging allows browsing up to 10,000 matching records per query; narrow the name/family/genus to explore further results.

World records provide botanical identity, family, genus, rank, taxonomic status and links to supporting GBIF datasets/observations. Species cards and profiles now resolve available, taxon-matched photographs from GBIF occurrence media, reuse the 100 bundled images when names match, and show photo credits/source/licence links. Only explicitly reusable CC BY, CC BY-SA and CC0 media are displayed. Higher taxonomic groups are not given a descendant's species photograph. Missing/unavailable images retain a labelled placeholder; no fixed photograph-coverage count is claimed. Search remains available while photos load. Photo requests are serialized, paced, cancelled when queued cards leave the viewport or a tab becomes inactive, and cached in memory (128 records). Searches and open profiles take priority; temporary 429/503 responses retry with bounded backoff. Native images download on demand; Web uses HTML images because GBIF's image responses do not allow cross-origin byte fetching. Verified care requirements are not available for every world record; the original 100 care profiles remain the curated collection.

World bookmarks are separate owner-only documents at `users/{uid}/worldPlants/{gbifKey}`. They are not limited by the 100-item curated favourites array. Query responses are debounced and protected against late responses replacing newer searches; errors offer retry, and account changes clear the visible saved collection.

### Curated care collection

All 100 images are bundled for reliable display. The original six botanical assets are retained; 94 species photos were downloaded with Wikimedia author, licence, and source metadata. Individual plant details link to the original photo source. Full metadata is in `assets/catalogue/credits.json`.

`tool/catalogue.json` and `tool/build_catalogue.cjs` maintain the expanded catalogue. The generated Dart file is checked in, so downloads are unnecessary to run the app. Run the generator from the project root only when updating the catalogue.

Care profiles provide starting guidance, not automated watering instructions. Seasons, pot size, and local climate change a plant's needs. Reference material includes [RHS houseplant guidance](https://www.rhs.org.uk/plants/types/houseplants/growing-guide), [RHS orchids](https://www.rhs.org.uk/plants/types/orchids/indoor), and the [NC State container-growing handbook](https://content.ces.ncsu.edu/extension-gardener-handbook/18-plants-grown-in-containers).

## Deployment and limits

Navigation, discovery collections, search chips and the AI guide use subtle animated botanical icons. AI uses an orbiting live indicator. Animations pause off-screen/background and respect the operating system's reduced-motion preference. Dark mode uses charcoal surfaces, muted mint accents and warm neutral secondary colours rather than green-tinted backgrounds throughout.

### AI gardening guide

The **AI guide** button opens a real Firebase AI Logic conversation. Beginner shortcuts cover choosing a plant, light, pots/soil, watering, the first week, fruit gardening, unusual plants, and troubleshooting. Curated and world plant profiles pass botanical context to the guide. It supports multi-turn questions in the user's language, including Roman Urdu, preserves failed questions for retry, and clears conversations on account changes or leaving the screen. Questions are sent to the provider; chat history is not saved to Firestore.

Both Firebase AI and the Gemini service are enabled, and the project owner has accepted the Gemini API terms. The Gemini backend is configured without changing billing. A real authenticated request returned a Roman Urdu gardening answer. `node tool/configure_ai.cjs` can reapply this configuration using the authenticated Firebase CLI account; `node tool/verify_ai.cjs` creates a temporary test account, checks a live answer, then deletes the account.

The guide uses the official Firebase AI proxy REST endpoint with the existing Firebase application key, app ID, and signed-in user's Firebase token. No Gemini API secret is shipped. The newer Flutter AI SDK references a foundation annotation unavailable in Flutter 3.32, so the small HTTP adapter keeps the existing Flutter/Firebase toolchain compatible without patching SDK caches or downgrading authentication/database plugins.

The model defaults to `gemini-3.5-flash-lite`, listed by [Firebase's supported model documentation](https://firebase.google.com/docs/ai-logic/models) as available without billing. Override with `--dart-define=PLANTIFY_AI_MODEL=...` when building if provider availability changes. Quotas and regional availability still apply. Before public deployment, configure Firebase App Check for Android/Web and enable AI enforcement; no production attestation credentials have been supplied.

Discover and Search have All plants, Fruit plants, Everyday plants and Unique plants filters. Collections browse multiple selected genera in rotating batches, rather than only one genus. A text search within a collection filters matching records to those genera. These are exploration collections and include botanical relatives; they are not exhaustive usage or edibility classifications. Worldwide and bundled profiles share the same responsive photo/details layout. A world record that matches a bundled botanical name opens its full care profile; other records offer botanical facts, private bookmarking, source observations and AI guidance without invented care schedules.

`firebase.json` contains a Hosting configuration for the compiled web app. Hosting has not been published as part of this change. Add any custom hosting domain to Firebase Auth's authorized domains before using it.

Android store release signing still needs the owner's release keystore; the current release build type retains debug signing. Firebase is configured for Android and Web only. iOS/macOS require their own registered Firebase app/configuration and a Mac build environment.

Shopping, payments, push notifications, and camera-based plant identification are outside the implemented discovery/care features.

The QA scripts under `tool/` create and clean up temporary test accounts. They do not send emails or touch existing users. `tool/verify_web.cjs` checks real login, curated favourite restoration, live worldwide search and Firestore world bookmarks, using a temporary Playwright installation under `build/qa-runner` and a local server started by `node tool/preview.cjs`.

Install the browser checker with `npm install --prefix build/qa-runner --no-save playwright`. QA Firebase REST scripts read the local ignored `firebase-web-config.json` file exported by `firebase apps:sdkconfig WEB 1:525947588461:web:a17f9b1620d1cb67f0d464 --project plantify-00 --json`.
