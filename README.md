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

## Ten-wave runs (v0.5.0)

Time is a record to beat, not a survival countdown. Waves 1–9 contain finite, increasing enemy budgets and advance only after every enemy is defeated. Minibosses appear on waves 3 and 6; compact, gold-marked champions join later waves. Wave 10 is the final boss. Chapter enemy pools now advance with waves, so slow builds cannot wait for a new pool or boss.

A continuous dirt bank rises around the scout during the three-second boss warning. Player rolls and boss charges stay inside the arena. Bosses use phased volleys, charge lanes and seed rings with an escape gap. Recovery grants 35% bonus damage. Results appear one second after the final hit. The finale retains at most two berry pickups and one guard pickup; unused healing cannot form a stockpile. Reduced Flashes keeps the warning steady.

Fresh scouts receive six level choices, two miniboss rewards and a final preparation: nine selections. XP requirements are 8, 20, 35, 50, 70 and 100, spreading levels through later waves. Uncollected XP is gathered after a true wave clear. The first weapon offer improves direct damage/rate, and the final prep excludes pickup, piercing and knockback upgrades. Rank caps and three-family offers remain. Permanent merits can add their stated bonuses.

The HUD shows wave / 10, enemies left, and elapsed active-play time. Stage records keep a separate ten-wave best clear, preserving old progress. Skill decisions and pause time do not count. Regular bugs spawn nearby, fade in before contact damage, and remain subject to the 70-enemy cap.

Validation: `godot --headless --path game -- --smoke-test` and `godot --headless --path game --script res://tests/chapter_checks.gd`. The chapter suite checks finite-wave progression, waiting exploits, both minibosses, arena collision in 16 directions, victory delay, 100 skill-offer seeds, rank caps and clear records. It also runs 60 fresh-progression reference scenarios across five stages, four builds and three seeds. All completed with nine choices; peak active enemies was 48. Chapter 5 averages: attack 195.6s, crowd control 210.8s, mixed survivor 275.2s, pure defense 364.4s. These are scripted comparisons, not human difficulty or phone-performance measurements.
