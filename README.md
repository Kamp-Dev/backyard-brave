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

## Ten-wave runs (v0.7.0)

Waves clear through combat rather than a timer. Waves 1–9 contain 14, 20, 24, 30, 34, 38, 44, 50 and 56 regular enemies before stage scaling. Minibosses appear at 3 and 6; marked champions join later waves. Wave 10 is a final boss inside a solid rising dirt arena. Pauses and skill decisions do not count toward clear times. This balance uses a separate best-time key while retaining previous records and progression.

Bosses shuffle five attacks without immediate repeats: wide volleys, a dense ring with a safe gap, charges, an expanding shockwave, and three marked ground eruptions. Eruptions forecast current travel but lock their marks during the warning. Later phases have double charges with a fresh warning for the second rush, faster pursuit and shorter recovery. Recovery grants 35% bonus damage. Phase transitions clear bullets. The three-second intro and one-second victory beat remain. Finales retain at most two berries and one guard pickup.

Fresh scouts still receive nine selections: six XP levels, two miniboss rewards and final preparation. XP steps are 10, 24, 42, 60, 82 and 118. XP stays on the ground between waves; only the wave-nine clear gathers leftovers before the final boss. Initial weapon offers improve direct damage/rate; final preparation excludes Forager Pouch, while Needle marks and Thump explosions are useful against the boss. Rank caps and family coverage remain. Existing merits may add their advertised bonuses.

Validation: run `godot --headless --path game -- --smoke-test`, `godot --headless --path game --script res://tests/chapter_checks.gd`, and `godot --headless --path game --script res://tests/boss_pressure_checks.gd`. Sixty full runs across five stages, four builds and three seeds passed. Chapter 5 attack builds averaged 239.2s. In matched boss-only tests the reactive pilot won 3/3; constant circling without rolls lost 2/3 and survived once with one heart. Tests also check warning lock, AoE grace/invulnerability, chained-charge warnings, attack bag coverage, arena bounds and skill fairness. These scripted results do not substitute for mobile playtesting.

## Skills that change how you fight

Each of the nine skills gains a combat behavior at rank one. Burst Seeds adds a delayed follow-up, Scatter Seeds trades range for a wide fan and close-range damage, and Acorn Cannon charges every fourth volley. Forager Pouch turns collected XP into seed rings. Rolling Acorn leaves a delayed bomb; Bramble Boots lays damaging ground while moving; Dew Counter retaliates on blocked hits. Needle Seeds builds a temporary repeat-hit mark as well as piercing. Thump Shot detonates one seed every third volley.

Ranks strengthen these mechanics. Charged volleys, piercing, spread and burst fire combine, but secondary explosions cannot trigger recursive chains. Ground patches share a damage cooldown so stacking them does not multiply damage. Mobile effect limits cap ground zones and blast effects. Final-prep offers exclude Forager because no further XP is needed. The new balance keeps the nine baseline selections and existing XP thresholds, with a separate skill-era clear-time record.

Additional validation: `godot --headless --path game --script res://tests/skill_behavior_checks.gd` tests delayed fire, close-range bonuses, charge cadence, banked pickup attacks, bomb timing, non-stacking brambles, shield counters, mark expiry, nonrecursive splash, boss arrival protection and reset. Skill effects are rendered by the game and stay visible in battery mode.

## Spawn and XP correction (v0.7.1)

Regular enemies arrive in varied opposite pairs, covering eight approach sectors before reusing one. Each group follows the player's recent movement heading. Spawn points retain the 260-320-unit safety ring and arrival grace; blocked sectors search nearby alternatives without clamping enemies into unsafe positions. A completely obstructed ring retries without spending the wave budget.

Seeds remain for manual collection through waves one to eight. The final pre-boss sweep grants any remaining XP and skill choices before wave ten begins. Added `tests/spawn_xp_checks.gd` covers 100 seeds, moving-player direction coverage, paired approaches, rocks, failed-spawn budgets, persistent XP, ordinary pickup and the one-time final sweep.
