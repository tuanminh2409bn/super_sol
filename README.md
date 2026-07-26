# Super SOL Flutter

Flutter recreation of mockups `1`, `2`, `3.1`, `3.2`, and `3.3`, built on
the original 589×1280 design canvas and scaled proportionally at runtime.

## Implemented flow

- Splash screen (`mockup/1.jpg`), tap or wait 1.35 seconds.
- Six-digit certificate PIN screen (`mockup/2.jpg`).
- One continuous vertical Home screen: `3.1` is the top, `3.2` continues
  directly below it, and `3.3` is the same page after further scrolling.
- Tap the top-right search icon to jump to the `3.2` continuation, or scroll
  down normally through all three mockup checkpoints.
- Tap the first Asset card to open the continuous account-detail page:
  `4.1` is the top summary and `4.2` is its scrolled transaction state.
- The account-detail Back and Home buttons both return to Home.
- Tap the profile name/badge for account actions.
- Email/password registration, sign-in, and sign-out with Firebase
  Authentication.

The PIN keypad accepts the six digits shown in any order for this prototype.
The account sheet is also available through `로그인 방법 다시 선택` on the
PIN screen.

## Firebase

- Project: `super-sol-app-2026`
- Console:
  <https://console.firebase.google.com/project/super-sol-app-2026/overview>
- Android package: `com.supersol.super_sol`
- iOS bundle ID: `com.supersol.superSol`

Native Firebase files are already installed:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

The Firebase project is on the paid plan. These Authentication providers were
verified through the Firebase API on 2026-07-24:

- Email/Password: enabled, password required.
- Google: enabled, OAuth client configured in Firebase.

When native Firebase configuration is unavailable, `AuthService` supplies a
local development fallback so UI work remains testable. It stores only a small
non-cryptographic digest and must not be treated as production authentication.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
```

Golden renders live in `test/goldens/` at the exact 589×1280 mockup size.

## iOS TestFlight with Xcode Cloud

The repository includes `ci_scripts/ci_post_clone.sh` for Xcode Cloud. It
pins Flutter `3.32.8`, restores Dart and CocoaPods dependencies, and assigns
the Cloud build number to the iOS archive so every TestFlight upload is unique.

In Xcode (15 or newer), open `ios/Runner.xcworkspace`, then configure Xcode
Cloud with the shared `Runner` scheme and the `com.supersol.superSol` product.
Choose an Xcode 26 build environment, enable Archive, and choose TestFlight as
the post-action distribution. Keep automatic signing enabled and select the
Apple Developer team that owns the App Store Connect record.

The Xcode Cloud workflow must have access to this Git repository. Never commit
signing certificates, provisioning profiles, keystores, or Apple credentials;
Xcode Cloud manages signing through the selected Apple Developer team.
