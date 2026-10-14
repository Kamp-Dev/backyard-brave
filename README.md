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

XP stays on the ground for manual collection until final preparation. The run cap is level 10, with XP steps 12, 26, 44, 66, 92, 120, 150, 180 and 210. A fresh scout can earn nine level choices, two miniboss rewards and one final-prep choice, for twelve total. Garden merits can add their advertised bonuses. Healing drops are less frequent per kill to account for the larger hordes. Guardians have 30% more health to match the expanded skill budget. The five-minute format stores separate best-clear times while retaining old records and progression.

Bosses shuffle five attacks without immediate repeats: wide volleys, a ring with a safe gap, charges, an expanding shockwave, and marked ground eruptions. Eruptions lock their marks during the warning. Later phases have double charges with fresh warnings, faster pursuit and shorter recovery. Recovery grants 35% bonus damage; phase transitions clear bullets. Finales retain at most two berries and one guard pickup.

## Character kits (v0.10.0-test)

Scout's field kit has Bank Shot, Acorn Decoy, Snapline, Trail Mark, Scatter Satchel, Quickdraw Roll, Bark Guard, Counterseed and Forager Route. Poppy's seed basket has Seed Turn, Pollen Stamp, Mothball Pouch, Dew Step, Bee Companion, Pocket Fan, Catch Guard, Petal Wake and Thirsty Roots. These are separate nine-skill pools, with three ranks that add behaviors instead of shared stat increases. Cards show the next rank, compatible partner and the bonus's effect.

Two matching rank-two skills activate a bonus automatically. Scout can build Marked Ricochet, Acorn Ambush, Tripwire Volley, Bark Reprisal and Trail Network. Poppy can build Bloom Patch, Pollinator Loop, Scent Sweep, Petal Parry and Root Garden. Offers guarantee an owned upgrade when an eligible one exists, favor missing partners and never include duplicates or capped skills. Two rerolls are available per run (tap the button, keyboard R or controller X). Final preparation excludes Scout's XP-dependent Forager Route. Pause shows the current loadout and active bonuses; timed tools show readiness beneath the HUD.

Mobile limits bound secondary shots, zones and damage pulses. Secondary blasts cannot recursively trigger more blasts. Menus pause cooldowns; ready timed skills hold one charge until an enemy is present. Bosses resist displacement and repeated slowing. Skill descriptions and combinations are in `game/character_skills.json`.

## One character art and animation style

Scout has been repainted to match Poppy. Both use `game/character_art.gd` for travel-driven alternating steps, independent attack poses, retreat and rolls. Camp and results portraits use the same assets. New characters must follow `game/ART_STYLE.md`: soft painted garden colors, warm contours, common proportions, scale and animation. Old unused Scout textures are excluded from exports.

## Validation

GitHub Actions runs the smoke suite, skill/combination behavior checks, spawn/XP checks, Poppy movement/return tests, boss pressure comparisons and 120 complete chapter simulations (two characters, five stages, four builds, three seeds) before publishing. Each build must win at least two of its three seeds in each stage. Both the damage and survival tradeoffs remain visible; victories are not guaranteed. Caps, skill choice counts, final warning, arena bounds and victory delay are checked.

The scripted pilot and desktop render checks do not replace mobile playtesting. Both characters share existing camp progression; this update preserves saves, package identity and the established Android test signing key.
