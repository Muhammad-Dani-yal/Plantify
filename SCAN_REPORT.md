# Plantify implementation and verification

Updated 9 October 2026.

## Delivered

- Integrated Firebase initialization using the actual Android configuration and a registered web app in project `plantify-00`.
- Connected real email/password signup and login, reset email requests, verification requests, auth session restoration, profile changes, and sign-out. Removed demo/guest account bypass and demo wording from the product.
- Connected user-owned favourites, garden entries, notes, watering dates, and preferences to Cloud Firestore. Added sync status, retryable failures, independent field updates, and clearing of account data on sign-out/account switch.
- Backed up the original public test rules locally and deployed owner-only Firestore rules.
- Expanded the catalogue to 100 unique plant entries. All images are bundled; 94 Wikimedia photos include credits and licence/source links.
- Added collections, plant matching, random discovery, care-term search, filters, sorting, progressive catalogue loading, and plant comparison.
- Added an auto-advancing welcome slideshow with pause/manual controls; richer sage, peach, lavender and forest colours; and animated gradient buttons with hover, focus, press, and loading states.
- Preserved search state between tabs. Fixed mobile keyboard and desktop navigation layout issues.
- Matched the Android application ID to the supplied Firebase app and updated Gradle/AGP/Kotlin for the installed Flutter SDK. Added Android internet permission and Plantify branding.

## Verified

- 25 Flutter regression tests pass, including catalogue assets, auth success/failure, no unauthenticated local bypass, reset failure/success, cloud restoration, account isolation, cloud retry, slideshow pause/advance, comparison limits, garden actions, and mobile/desktop layouts.
- Live Firebase REST checks passed for temporary-account signup/sign-in, user data write/read, and denial of unauthenticated/cross-account data access. QA accounts/documents were deleted.
- Web release compilation passed.
- Local Chrome verified real Firebase sign-in, a favourite written to Firestore, and session/favourite restoration after reload. Temporary accounts and documents were removed. Desktop discovery and the mobile profile rendered correctly.
- Final Flutter analyzer reports no issues; formatting and Git whitespace checks pass.
- Cleared stale generated build files from the original computer and regenerated Firebase web plugin registration.

- Final Android debug APK compilation passed with Java 17, Kotlin 2.3.10, and the Kotlin-compatible D8/R8 8.13.19 override. The previous cross-drive Kotlin cache failures and D8 metadata errors are resolved. Build evidence is in `build/android-debug-build.log`; APK is `build/app/outputs/flutter-apk/app-debug.apk`.
- Android runtime behaviour is not verified on a physical device. The connected CPH2449 failed ADB installation and subsequent status commands stalled; the task's installation attempt was stopped. Dependency deprecation and SDK XML-version warnings remain non-fatal.

## Java 25 fix and cleanup

- Confirmed Flutter was choosing Android Studio's bundled Java 25.0.3, causing `flutter-plugin-loader > 25.0.3` to fail before app compilation. Set Flutter's persistent `jdk-dir` to the installed Microsoft JDK 17; `flutter doctor -v` confirms Java 17.0.20.
- Standard `flutter build apk --debug --no-pub` now succeeds without manually setting `JAVA_HOME`. Evidence is in `build/android-flutter-build.log`.
- Removed unused `CustomFonts`, `AppColors`, the `authAvailable` getter, 63 legacy images (13,738,647 bytes), and the unused Firebase Realtime Database dependency and its transitive packages.
- Simplified the package manifest, removed an obsolete inspection script and unused catalogue source entry, and retained Cupertino Icons because adaptive Flutter widgets reference its font indirectly.
- Added a Windows directory-junction helper so `flutter pub get` succeeds without requiring a Developer Mode change. Regenerated stale web plugin registration after dependency removal.
- Cleanup verification: all 25 tests pass and Flutter analyzer reports no issues.

## Worldwide botanical catalogue

- Added live GBIF Plantae/backbone search beyond the 100 curated care profiles. Live count check returned 446,842 accepted species records; coverage includes taxonomic/fossil records and is not a guarantee of every plant worldwide.
- Added rank and synonym filters, debounced common/scientific-name search, pagination, botanical identity profiles and source links. Provider paging depth is disclosed with guidance to narrow queries.
- Added account-specific global plant bookmarks under `users/{uid}/worldPlants/{key}` and links from Discover, Search and Favorites. Global bookmarks use documents rather than the capped curated favourites array.
- Deployed owner-only validation rules and verified real read/write persistence, unauthenticated/cross-account denial and rejection of invalid fields. All QA accounts/documents were removed.
- 31 Flutter tests pass, including narrow global layout, asynchronous stale-result protection, API failures, pagination, save/remove and account isolation. Updated Android APK and web builds pass.
- Rendered Chrome verified live GBIF search for Welwitschia mirabilis, cloud bookmark persistence, the saved world collection and its mobile layout. Browser QA bookmarks, documents and account were removed.

## AI gardening guidance and collections

- Added a dedicated conversational AI guide with beginner steps, fruit gardening, unusual species, care troubleshooting, English/Urdu/Roman Urdu replies, and botanical context from curated/global profiles.
- Activated Firebase AI and Gemini Developer API after the owner accepted Google's terms. Configured the existing project's Gemini backend without changing billing. Real authenticated Roman Urdu AI responses pass.
- Uses the official Firebase AI proxy REST endpoint with Firebase app identity and user authentication. No Gemini secret is bundled. This avoids a newer SDK compilation incompatibility with the installed Flutter version while retaining the current authentication/database plugins.
- Added fruit, everyday, and unique discovery shortcuts and genus collections backed by real GBIF searches, rather than claiming an exhaustive horticultural classification.
- All 34 Flutter tests pass, including multi-turn context, failed-question retry without duplication, and ignoring old answers after conversation reset. Analyzer is clean; Android debug and web builds pass.
- Rendered Chrome verifies two real AI replies with preserved conversation context, mobile chat layout, existing Firebase sign-in/favourite restoration, live world search and private bookmark persistence. Temporary QA accounts/documents were removed.
- AI conversations are held only in the open screen, clear on account changes or leaving, and disclose provider processing. AI care advice is distinguished from verified catalogue care. Firebase App Check production attestation/enforcement remains part of public-release setup.

## Photos, motion icons and dark palette

- Added taxon-matched GBIF occurrence photographs to global species cards/profiles, with bundled-photo reuse, credit/source/licence display, explicit reusable-media checks, bounded caching, and non-blocking missing-photo placeholders.
- Verified live licensed images for Welwitschia mirabilis, Citrus limon and Mangifera indica. Web uses HTML image rendering to avoid the image service's byte-fetch CORS restriction; native downloads are serialized.
- Added animated icons to collection/search chips, sidebar/bottom navigation and world catalogue tabs. AI uses a live orbiting sparkle icon; motion pauses off-screen/background and respects reduced-motion settings.
- Rebalanced dark mode to charcoal surfaces with muted mint, warm neutral accents, readable text and theme-aware branding.
- 40 Flutter tests pass; analyzer is clean; Android and web builds pass. Rendered Chrome verifies the live world photo, bookmarking, real AI follow-up replies, and dark desktop/mobile layouts. Temporary QA accounts/data were removed.
- Found stale Android build output during APK content verification despite a successful Gradle exit. Cleared generated native caches, rebuilt, and verified the packaged kernel contains current photo, motion and AI code. Added explicit project source inputs to Flutter Gradle tasks to prevent recurrence in paths containing spaces.

## Unified discovery, scrolling and profiles

- Discover and Search now browse the worldwide catalogue directly, including records without photos. The bundled care collection remains available separately and is featured on Discover.
- Added All plants, Fruit plants, Everyday plants and Unique plants filters backed by multiple selected genera. Collections include botanical relatives and do not claim exhaustive usage or edibility classification.
- Replaced load-more buttons with automatic pagination near the scroll end. The responsive lazy grid requests photos for visible/cached cards, deduplicates identities, ignores stale searches and retains loaded results when a later page fails.
- Curated and online profiles share a responsive photo/details component. Exact bundled-name matches open verified care profiles; other world records show botanical facts, bookmarks, source observations and AI context without invented care schedules.
- Prioritized search/open-profile photos, cancelled unused queued requests and inactive-tab requests, paced provider calls and added bounded 429/503 retry. Licensed legacy HTTP media is served only through the HTTPS GBIF image proxy.
- Preserved search/filter/saved-view state across desktop/mobile layout changes. The desktop sidebar scrolls on shorter windows.
- All 47 Flutter tests pass, including automatic paging/retry/deduplication, multi-genus filters, unbundled discovery, responsive search preservation, photo priority/cancellation, rate-limit retry and secure legacy media. Analyzer is clean; final web and Android debug builds pass.
- Rendered Chrome verified automatic worldwide paging, live Fruit/Unique filters, a real online photograph, private Firebase bookmark persistence, matching desktop/mobile profile layouts and dark mode. QA accounts/documents were removed. APK kernel checks verify the packaged source rather than relying only on Gradle success.

## Public release configuration

## Downloaded-first discovery and photo framing

- Discover renders all 100 bundled plants before online records in lazy sliver grids. Query, collection and rank filters apply to the downloaded section; bundled botanical matches are excluded from the online section to avoid duplicates. Saved world plants remain account-specific.
- Online card images are clipped to rounded card edges. Full profiles use contain sizing on a themed background so landscape and portrait photographs remain visible without distortion or losing plant details.
- The 47-test regression suite passed; the nine catalogue tests were rerun after adding explicit ordering and duplicate-species assertions. Analyzer, Android debug build and web build passed. APK kernel checks include both downloaded and online section labels.
- Rendered Chrome verified downloaded favourites, automatic online pagination, live filters, online photo rendering, private cloud bookmarks, shared desktop/mobile profiles and dark mode. Temporary QA accounts and data were removed.

## Release configuration details

Hosting has not been published. Android store signing needs the owner's release keystore. Firebase configuration currently supports Android and Web; Apple platforms need their own Firebase registrations and Mac validation.

Care timings are soil-check suggestions. Email request handling is implemented; no real user's verification/reset email was sent during QA. Camera identification, payments, shopping, and push notifications are not implemented.
