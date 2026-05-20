# Chaos Slap Trigger Strategy

## Why this is worth building

SlapMac proved the hook: a device reacts with embarrassing/funny sounds when physically hit. The concept is simple, demo-friendly, and viral because the whole product is understandable in one short clip.

Chaos already has most of the mobile foundation:

- Flutter app
- Android release pipeline
- local recording/import flow
- sound library/categories
- shake trigger
- slap trigger service
- slap impact detector tests
- sensitivity settings
- prank triggers: timer, clap, light
- background service plumbing

The opportunity is to position Chaos as the free, mobile-first version: “slap your phone and it talks back.”

## SlapMac reference points

Observed SlapMac positioning/features:

- macOS menu bar app
- paid product, listed at $9.99
- requires supported Apple Silicon MacBook hardware
- detects slaps/taps/shakes from device sensors
- sound volume scales with slap force
- sensitivity control
- cooldown control
- slap counter
- sound/voice packs, reportedly 150+ clips / 9 packs
- launch at login
- USB plug/unplug trigger
- lid creak trigger
- anti-theft mode roadmap/current feature
- custom sound packs planned

What to copy conceptually, not literally:

- instant funny demo
- force-based reactions
- sensitivity + cooldown controls
- counters/combos
- sound packs
- public-space warning / safe mode
- custom user sounds

## Product framing

Avoid making the public brand only “moaning app.” Better positioning:

- “Your phone reacts when slapped.”
- “A chaotic soundboard powered by motion.”
- “Slap, shake, clap, or trigger your sounds.”

Moan sounds can be one optional pack. This is safer for app stores and easier to share publicly.

Possible names if spun out:

- SlapFX
- SmackPack
- BonkBox
- Slappy
- PhoneMoan

For the current app, keep it under Chaos and add a dedicated “Slap Mode” flow.

## MVP feature plan

### Phase 1: Make slap mode obvious

Current code has slap detection, but it should be first-class in UI.

Add:

- Big Slap Mode card on home/chaos lab
- enable/disable toggle
- sensitivity slider
- cooldown slider
- test calibration screen: “tap/slap now”
- visual impact meter
- slap count
- last detected force

### Phase 2: Better detector

Current detector uses magnitude + jerk threshold. Improve it with:

- rolling baseline gravity compensation
- peak impact magnitude
- jerk score
- directional spike score
- cooldown
- force score normalized 0.0–1.0

Return a SlapImpact object instead of bool:

- timestamp
- force
- magnitude
- jerk

Then sound volume/pitch can scale with force.

### Phase 3: Sound packs

Seed packs:

- Human: burp, snore, fart, scream/moan-safe variants
- Animals: goat, cat, chicken
- Memes: bruh, airhorn, oh no
- Impact/combo: bonk, punch, slap, cartoon hit

Needed app-store-safe structure:

- Safe Mode default on first launch
- Explicit/awkward packs are opt-in
- headphone warning before enabling spicy packs

### Phase 4: Viral mechanics

Add:

- combo counter
- “hardest slap today”
- lifetime slap count
- shareable stat card
- screen flash on hard slap
- haptic response
- random roast/commentator lines

### Phase 5: Multi-platform

Flutter is correct for mobile:

- Android first: easiest APK distribution and sensor behavior
- iOS next: same Flutter UI, CoreMotion via sensors_plus usually enough
- macOS later: Flutter UI possible, but real MacBook motion sensors likely need native Swift/IOKit/CoreMotion-style plugin work depending hardware access
- web only as non-sensor soundboard/demo

## Recommended technical architecture

Keep services separate:

- SlapService: sensor stream lifecycle
- SlapImpactDetector: pure detection algorithm, fully unit-tested
- SoundTriggerService: chooses sound, volume, pitch, effects
- SoundPackManager: bundled/custom packs
- SettingsProvider: sensitivity, cooldown, safe mode, selected packs
- StatsService: slap count, combos, hardest slap

Current code already has SlapService and SlapImpactDetector. Next refactor should make the detector return force metadata.

## Near-term tasks

1. Add dedicated Slap Mode UI in Chaos Lab.
2. Add cooldown setting; currently cooldown is constant at 700ms.
3. Change SlapImpactDetector from bool to impact result with force score.
4. Scale playback volume by force.
5. Add slap count + hardest slap stat.
6. Add public-space warning/safe mode for spicy packs.
7. Add more bundled sound packs.
8. Run Flutter tests and Android release build.

## Success criteria

MVP is good when a demo video is this simple:

1. Open Chaos.
2. Enable Slap Mode.
3. Slap phone.
4. Phone reacts instantly with a funny sound.
5. Slap harder, it reacts louder/more dramatically.
6. Show counter/combo increasing.
