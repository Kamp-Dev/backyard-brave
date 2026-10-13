extends RefCounted
## Gameplay knobs. Keep art changes out of these values.
const RUN_SECONDS = 180.0
const BOSS_ARRIVAL = 150.0
const CHARGE_WARNING = 0.8
const CHARGE_SECONDS = 0.48
const CHARGE_RECOVERY = 0.9
const CHARGE_SPEED = 650.0
const SHOT_WARNING = 0.65
const BOSS_HEALTH = 240
const ENEMY_NAMES = ["Garden Ant", "Wolf Spider", "Pill Bug", "Stag Beetle", "Spitter Beetle", "Broodmother", "Rhino Beetle", "Earwig Captain", "Yellowjacket", "Garden Weevil", "Grasshopper", "Mole Cricket"]
const ENEMY_COLORS = [Color("ee4e9c"), Color("ee4e9c"), Color("b885ef"), Color("ffb45e"), Color("8ce58f"), Color("ff776d"), Color("ffb45e"), Color("dbaf79"), Color("f3d66f"), Color("b3bd63"), Color("b6d66a"), Color("dab279")]
const START_WAVES = [1, 3, 5, 2, 4]

# Fixed per-stage challenge, independent of owned talents or deaths.
static func stage_health(stage: int, boss: bool = false) -> float:
 var progress = clampi(stage,1,30)-1
 return 1.0 + progress*(0.070 if boss else 0.110) + (progress/10)*0.15

static func stage_density(stage: int) -> float:
 return 1.0 + (clampi(stage,1,30)-1)*0.024

static func stage_speed(stage: int) -> float:
 return 1.0 + (clampi(stage,1,30)-1)*0.022

# Lightweight regular enemies never count as elite reward encounters.
static func is_elite(kind: int) -> bool:
 return kind in [6,7,8]
static func is_major(kind: int) -> bool:
 return kind in [5,6,7,8]
static func closing_spawn_delay(seconds: float) -> float:
 return 1.0+3.0*smoothstep(135.0,RUN_SECONDS,seconds)
