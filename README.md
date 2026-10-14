# Backyard Brave

A portrait garden survival game. Mobile test builds:

- Browser: https://kamp-dev.github.io/backyard-brave/
- Android APK: https://github.com/Kamp-Dev/backyard-brave/releases/download/mobile-test/Backyard-Brave.apk

Open `game/project.godot` in Godot 4.7.2. GitHub Actions imports the project, exports a single-threaded Web build and a debug-signed Android APK, then publishes GitHub Pages and a test release. The APK supports ARMv7 and ARM64 phones. Audio starts after interaction with the page. Saves are local to each browser/device; clearing browser storage removes that browser's progress.

Android builds use a repository-secret development signing key, not a production store key. Assets include AI-generated illustrations. Source art and native labels remain separate. No player save files or private signing credentials are included.

## Chapter One: The Garden Gate

The first five stages use authored enemy pools, three pacing sections, sparse terrain, and named finales. Existing saves and later stages remain compatible.

| Stage | Focus | Finale |
| --- | --- | --- |
| First Clearing | Movement and gathering seeds; ants and weevils before spiders | Clover Captain |
| Pebble Crossing | Armored bugs and warned charges | Pebbleback |
| Clover Corner | Flanking spiders, hopping grasshoppers, burrowing crickets | Briar Captain |
| Potting Patch | Ranged volleys and cover | Goldenwing |
| Daisy Patch | Combine the chapter's lessons | Bramble Broodmother |

Final bosses change phases at 65% and 30% health. Species use different sequences of locked-direction volleys, charges, and rings with a green escape gap. Their recovery windows grant 35% bonus damage. Boss health is approximately three times the v0.3.0 value, scaling with stage difficulty. In 21 reference-pilot runs, the chapter finale lasts roughly 45–70 seconds after its entrance; phone playtesting remains necessary.

Every finale starts with a three-second flashing, borderless warning. The old swarm becomes harmless and retreats while fading away, then vanishes without kill or XP rewards. Spawning stops and rock cover clears. Reduced Flashes keeps the warning steady. The boss death animation plays for one second before results; combat cannot hurt the player during this victory beat.

After the first 20 seconds, regular spawn ticks introduce two bugs instead of one, subject to the existing 70-enemy cap. Additional swarm bugs have 65% normal health and count toward the bug total, but do not add XP or advance item-drop milestones. The original enemies retain their normal rewards, level thresholds remain unchanged, and no extra skills or characters are introduced.

Enemies spawn near the scout: regular bugs at 260–320 world units, special encounters at 320–360, and finales at 340–380. Spawn placement checks rock clearance. Regular bugs fade in for 0.55 seconds before moving or dealing contact damage.

Validation: run `godot --headless --path game -- --smoke-test` and `godot --headless --path game --script res://tests/chapter_checks.gd`. The chapter suite checks spawn pools, finale uniqueness, cutoff/victory, phase transitions, telegraphs, and 21 complete fresh-progression reference-pilot runs, including three boss builds. These scripted checks do not substitute for mobile playtesting.
