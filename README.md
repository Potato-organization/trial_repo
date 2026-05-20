# Chaos

Chaos is a playful Flutter soundboard for recording short sounds, playing built-in sound packs, and triggering clips with gestures or prank tools.

## Release Checks

Run these before uploading a build:

```sh
flutter analyze
flutter test
flutter build appbundle --release
```

The Play Store upload artifact is:

```text
build/app/outputs/bundle/release/app-release.aab
```

Keep `android/key.properties` and Android keystore files private. They are ignored by git and are required only for signing release bundles.
