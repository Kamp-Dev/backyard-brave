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

## Ten-wave runs (v0.6.0)

Waves clear through combat rather than a timer. Waves 1–9 contain 14, 20, 24, 30, 34, 38, 44, 50 and 56 regular enemies before stage scaling. Minibosses appear at 3 and 6; marked champions join later waves. Wave 10 is a final boss inside a solid rising dirt arena. Pauses and skill decisions do not count toward clear times. This balance uses a separate best-time key while retaining previous records and progression.

Bosses shuffle five attacks without immediate repeats: wide volleys, a dense ring with a safe gap, charges, an expanding shockwave, and three marked ground eruptions. Eruptions forecast current travel but lock their marks during the warning. Later phases have double charges with a fresh warning for the second rush, faster pursuit and shorter recovery. Recovery grants 35% bonus damage. Phase transitions clear bullets. The three-second intro and one-second victory beat remain. Finales retain at most two berries and one guard pickup.

Fresh scouts still receive nine selections: six XP levels, two miniboss rewards and final preparation. XP steps are 10, 24, 42, 60, 82 and 118. Clears gather remaining seeds. Initial weapon offers improve direct damage/rate; final preparation excludes pickup reach, piercing and knockback. Rank caps and family coverage remain. Existing merits may add their advertised bonuses.

Validation: run `godot --headless --path game -- --smoke-test`, `godot --headless --path game --script res://tests/chapter_checks.gd`, and `godot --headless --path game --script res://tests/boss_pressure_checks.gd`. Sixty full runs across five stages, four builds and three seeds passed. Chapter 5 attack builds averaged 225s. In matched boss-only tests the reactive pilot won 3/3; constant circling without rolls lost 2/3 and survived once with one heart. Tests also check warning lock, AoE grace/invulnerability, chained-charge warnings, attack bag coverage, arena bounds and skill fairness. These scripted results do not substitute for mobile playtesting.
