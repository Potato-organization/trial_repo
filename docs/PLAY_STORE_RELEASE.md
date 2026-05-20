# Play Store Release Checklist

## Build Artifact

- Package name: `com.potato.chaos`
- App name: `Chaos`
- Version: `1.1.0+2`
- Release artifact: `build/app/outputs/bundle/release/app-release.aab`
- Upload key SHA-256: `b2d9cdd4b827cf7e6e492399c955a763dbd6baf03875f4549391b70801f4702b`

## Signing Files

These files are local-only and ignored by git:

- `android/key.properties`
- `android/app/chaos-upload-keystore.jks`

Back up both securely before uploading the first release. Losing the upload key can block future updates unless Google Play support resets it.

## Required Local Commands

```sh
flutter analyze
flutter test
flutter build appbundle --release
```

## Play Console Setup

- Enroll in Play App Signing.
- Upload the signed Android App Bundle.
- Complete App Content:
  - Privacy policy URL
  - Data Safety form
  - App category: Entertainment
  - Ads: No, unless ads are added later
  - App access: No restricted login
  - Content rating questionnaire
  - Target audience and content
  - Foreground service declaration for background trigger notification

## Data Safety Draft

Chaos stores recordings, favorites, settings, play stats, and premium status on the device using local app storage. The app does not send those records to a developer server.

Declare third-party SDK behavior in Play Console for:

- Google Play Billing / in-app purchase
- Share sheet integration
- Android system permissions for microphone, notifications, sensors, and foreground service

## Privacy Policy Hosting

Host `docs/PRIVACY_POLICY.md` as a public HTTPS page and paste that URL into Play Console. Google Play requires the privacy policy URL even when an app does not collect user data on a developer server.

## Store Listing Draft

Short description:

```text
Record, play, and trigger funny sounds with shake, slap, clap, timer, and prank tools.
```

Full description:

```text
Chaos is a playful soundboard for quick laughs. Record short clips, play built-in meme and animal sounds, favorite your best sounds, and trigger them with shake, slap, clap, light, timer, or random chaos mode.

Features:
- Record short custom sounds
- Built-in meme, animal, and human sound packs
- Shake and slap trigger modes
- Clap, light, timer, and random prank tools
- Favorites and play statistics
- Optional Chaos Pro upgrade for expanded limits and background triggers
```
