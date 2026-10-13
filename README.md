# Backyard Brave

A portrait garden survival game. Mobile test builds:

- Browser: https://kamp-dev.github.io/backyard-brave/
- Android APK: https://github.com/Kamp-Dev/backyard-brave/releases/download/mobile-test/Backyard-Brave.apk

Open `game/project.godot` in Godot 4.7.2. GitHub Actions imports the project, exports a single-threaded Web build and a debug-signed Android APK, then publishes GitHub Pages and a test release. The APK supports ARMv7 and ARM64 phones. Audio starts after interaction with the page. Saves are local to each browser/device; clearing browser storage removes that browser's progress.

Android builds use a repository-secret development signing key, not a production store key. Assets include AI-generated illustrations. Source art and native labels remain separate. No player save files or private signing credentials are included.

## Chapter One: The Garden Gate

The first five stages use authored enemy pools, three pacing sections, distinct rock routes, and named finales. Existing saves and later stages remain compatible.

| Stage | Focus | Finale |
| --- | --- | --- |
| First Clearing | Movement and gathering seeds; ants and weevils before spiders | Clover Captain |
| Pebble Crossing | Armored bugs and warned charges | Pebbleback |
| Clover Corner | Flanking spiders, hopping grasshoppers, burrowing crickets | Briar Captain |
| Potting Patch | Ranged volleys and cover | Goldenwing |
| Daisy Patch | Combine the chapter's lessons | Bramble Broodmother |

The Broodmother changes phases at 65% and 30% health. Attacks lock their direction during visible windups: a volley cone, a charge lane, and a ring with a green escape gap. Recovery and phase transitions give the scout room to attack. Ordinary spawns ease during the finale; all enemy spawns stop at three minutes, and victory still requires clearing survivors.

Enemies spawn near the scout rather than at the distant edges of tall screens: regular bugs at 260–320 world units, special encounters at 320–360, and finales at 340–380. Spawn placement checks rock clearance. Regular bugs fade in for 0.55 seconds before moving or dealing contact damage. Spawn rates and XP pickup reach are unchanged.

Validation: run `godot --headless --path game -- --smoke-test` and `godot --headless --path game --script res://tests/chapter_checks.gd`. The chapter suite checks spawn pools, finale uniqueness, cutoff/victory, phase transitions, telegraphs, and 21 complete fresh-progression reference-pilot runs, including three boss builds. These scripted checks do not substitute for mobile playtesting.
