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

## Five-minute runs (v0.8.0)

The elapsed timer counts up. Regular reinforcements continue for five minutes instead of exhausting a finite wave budget. Nine pressure phases begin at 0:00, 0:30, 1:00, 1:35, 2:10, 2:45, 3:20, 3:55 and 4:30. Later phases increase group size, arrival frequency, health and champion pressure. Minibosses arrive at 1:00 and 2:45 and must be defeated before the final boss can begin.

At 5:00 regular spawning stops. Once both minibosses are defeated, remaining XP is collected and final skill choices are offered. Wave 10 then opens with the three-second warning and fading regular enemies, followed by the solid dirt arena. The elapsed timer continues during the guardian fight. Victory follows one second after the guardian dies. Pause and skill decisions do not count toward elapsed time.

Regular enemies arrive in varied opposite pairs covering eight approach sectors. Safe positions remain 260-320 units from the scout, with arrival grace. A fully obstructed approach retries safely. The normal limit is 68, reserving two slots under the 70-enemy mobile cap for minibosses. At the cap, offscreen ordinary stragglers can re-enter from new approaches; they retain identity and health and award no kills or XP. Visible enemies and minibosses never relocate this way.

XP stays on the ground for manual collection until final preparation. The run cap is level 10, with XP steps 12, 28, 50, 80, 115, 150, 180, 210 and 240. A fresh scout can earn nine level choices, two miniboss rewards and one final-prep choice, for twelve total. Garden merits can add their advertised bonuses. Healing drops are less frequent per kill to account for the larger hordes. Guardians have 30% more health to match the expanded skill budget. The five-minute format stores separate best-clear times while retaining old records and progression.

Bosses shuffle five attacks without immediate repeats: wide volleys, a ring with a safe gap, charges, an expanding shockwave, and marked ground eruptions. Eruptions lock their marks during the warning. Later phases have double charges with fresh warnings, faster pursuit and shorter recovery. Recovery grants 35% bonus damage; phase transitions clear bullets. Finales retain at most two berries and one guard pickup.

## Skills that change how you fight

Burst Seeds adds a delayed follow-up, Scatter Seeds trades range for a wide fan and close-range damage, and Acorn Cannon charges every fourth volley. Forager Pouch turns collected XP into seed rings. Rolling Acorn leaves a delayed bomb; Bramble Boots lays damaging ground while moving; Dew Counter retaliates on blocked hits. Needle Seeds builds a temporary repeat-hit mark as well as piercing. Thump Shot detonates one seed every third volley.

Ranks strengthen these mechanics. Secondary explosions cannot trigger recursive chains. Ground patches share a damage cooldown so stacking them does not multiply damage. Mobile effect limits cap ground zones and blasts. Final-prep offers exclude Forager because no further XP is needed.

## Validation

GitHub Actions runs the smoke suite and `tests/chapter_checks.gd`, `tests/boss_pressure_checks.gd`, `tests/skill_behavior_checks.gd` and `tests/spawn_xp_checks.gd` before publishing. Chapter checks cover sustained reinforcements during retreat, the elite gate, preparation before boss arrival, arena bounds, warning timing, skill fairness and 60 full-stage simulations across five stages, four builds and three seeds. Spawn/XP checks include 100 seeds, opposing approaches, rocks, identity-preserving re-entry, visible-enemy protection, manual collection and the single pre-boss sweep. These scripted tests do not replace real-device playtesting.

## Poppy (v0.9.0)

Tap the camp scout portrait to switch between your original scout and Poppy. Both are available immediately and share camp progression. Selection is saved on this device. Poppy throws a boomerang that pierces once outward and once on its return toward her current position. Roll into the returning main disc to bank 50% more damage for the next throw. Extra scatter discs and Burst echoes cannot stack catch charges. Her card descriptions reflect boomerang behavior; movement, pickup and guard skills remain compatible. This release includes her base gardening outfit.

Poppy checks run before publishing and cover two-pass damage, steering, catch consumption, skill compatibility, rock blocking, 30/60/120 FPS and touch/controller selection. The reproducible `tests/poppy_balance.gd` script covers five stages and four builds; initial seed-42 calibration finished 20/20 runs with wins. Real-device movement and comfort still need player testing.
