# Release setup

## Hosting

The configured Firebase project is `plantify-00`. Publish only the compiled web application:

```sh
flutter build web
firebase deploy --only hosting --project plantify-00
```

The default URL is https://plantify-00.web.app. Firebase Auth must authorize any custom domain before it is used.

If the CLI cannot reach its startup/OAuth host, `node tool/deploy_hosting.cjs` publishes the same compiled directory through the Firebase Hosting REST API using the existing CLI login. It keeps credentials in memory and prints only file progress and the published URL. `node tool/set_repo_website.cjs` updates this repository's Website field.

## Android signing

The portfolio APK preserves its previous debug signature so existing installations can update without losing data. Production store signing requires the owner's private keystore; no production key has been generated or committed.

1. Create or supply the owner's upload keystore and back it up privately.
2. Copy `android/key.properties.example` to `android/key.properties` and fill in the real local values. Keystores and `key.properties` are ignored by Git.
3. Build with the strict signing gate:

```sh
flutter build appbundle --release --android-project-arg=plantifyProductionSigning=true
```

The gate fails if signing configuration is missing, rather than silently creating a debug-signed store build. A malformed supplied configuration also fails immediately. Keep the same signing key for subsequent updates.

## App Check

Client integration is implemented but disabled by default while registered providers and real attestation are unavailable. This is not production enforcement.

1. Register the Android Firebase app with Play Integrity and the production signing certificate SHA-256. Configure verdict requirements appropriate to Play Store distribution; a sideloaded portfolio APK must not be assumed to pass Play recognition/licensing requirements.
2. Register the Web app with reCAPTCHA v3; authorize the live domain and retain its site key and secret according to the provider setup. Never put the secret in Dart defines or Git.
3. Build Android with `--dart-define=PLANTIFY_APP_CHECK=true`. Build Web with both `--dart-define=PLANTIFY_APP_CHECK=true` and `--dart-define=PLANTIFY_RECAPTCHA_SITE_KEY=YOUR_PUBLIC_SITE_KEY`.
4. Verify valid attestations on real production clients in Firebase Console metrics. Only then enable enforcement for Firestore, supported Authentication protection, and Firebase AI Logic. Deploy the attestation-enabled builds before enforcement to avoid denying existing clients.

`AppAttestation` activates Play Integrity/reCAPTCHA and attaches `X-Firebase-AppCheck` to the custom Firebase AI REST request. Firebase SDKs handle their own attestation headers. No debug provider or allowlisted debug token is shipped in release builds. When enabled, missing Web configuration and missing AI attestation fail explicitly.

Official references: [Flutter App Check](https://firebase.google.com/docs/app-check/flutter/default-providers), [Firebase AI protection](https://firebase.google.com/docs/ai-logic/app-check), [Android signing](https://docs.flutter.dev/deployment/android#sign-the-app).

## Final inbox check

Automated QA uses isolated temporary accounts and verifies authentication, private data persistence, account isolation and real AI responses. It cannot confirm real inbox delivery or clicking verification/reset links.

On an account with an inbox you control, complete signup → verification email/link → logout/login → favourite → garden → note → watering → logout/login → restored data. Then request a password reset and complete its link. Confirm AI answers and session restoration after restarting the app. No delivery success should be claimed until these checks pass.
