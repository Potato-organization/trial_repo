# Codex task: force-aware Slap Mode impact pipeline

Repo: `/Users/krishnabahadurbasnet/Projects/Chaos`

## Goal
Implement the next highest-priority SlapFX MVP gap: the slap detector should return impact metadata with a normalized force score, and slap playback should scale volume based on that force.

## Scope rules
- Keep changes focused on force-aware slap detection/playback only.
- Do not delete the repo, rewrite history, force-push, publish, spend money, use sudo, or create/update cron jobs.
- Preserve existing UI style and current behavior where possible.
- Do not implement unrelated MVP items such as share cards, spicy packs, store release, or big redesigns.

## Required implementation
1. Update `lib/services/slap_impact_detector.dart`:
   - Add an immutable `SlapImpact` result object with at least: `DateTime timestamp`, `double force`, `double magnitude`, `double jerk`.
   - Add a nullable/object-returning API such as `addSample(...) -> SlapImpact?`.
   - Keep or provide a compatibility helper only if needed by callers/tests.
   - Normalize `force` to `0.0..1.0` using impact/jerk strength over threshold; clamp safely.
   - Keep cooldown enforcement.

2. Update `lib/services/slap_service.dart`:
   - Emit `SlapImpact` instead of `void` for slap events.
   - Pass through detector force/magnitude/jerk metadata.
   - Keep sensitivity updates working.

3. Update playback path:
   - In `lib/screens/home_screen.dart`, consume `SlapImpact` from `SlapService`.
   - Slap-triggered sound should scale volume from quieter soft hits to full volume on hard hits.
   - Add a `volume` parameter to `AudioPlayerService.play(...)` if needed and apply it with `just_audio`.
   - Shake playback should remain at normal volume.
   - Keep haptics.

4. Tests:
   - Update `test/slap_impact_detector_test.dart` to cover returned metadata, force clamping/range, and cooldown.
   - Keep existing smooth-movement/no-false-positive coverage.

5. Documentation:
   - Write a short summary of what changed, verification commands run, and any remaining next item to `docs/AUTOPILOT_LAST_RUN.md`.

## Verification to run
Use this environment before Flutter commands:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=/Users/krishnabahadurbasnet/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export FLUTTER_ROOT=/Users/krishnabahadurbasnet/Documents/flutter/flutter
export PUB_CACHE=/Users/krishnabahadurbasnet/.pub-cache
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:/Users/krishnabahadurbasnet/.n/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
flutter analyze
flutter test
```

If time permits after those pass, run:

```bash
flutter build apk --release
```

## Commit expectation
Do not commit unless all verification you ran passes. If something is blocked, leave a clear note in `docs/AUTOPILOT_LAST_RUN.md`.
