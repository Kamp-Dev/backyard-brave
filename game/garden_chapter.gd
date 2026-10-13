extends RefCounted
## Chapter one teaches one encounter pattern per stage, then combines them.
const TITLES = ["FIRST CLEARING", "PEBBLE CROSSING", "CLOVER CORNER", "POTTING PATCH", "DAISY PATCH"]
const BRIEFS = ["Keep moving / Gather fallen seeds", "Watch the charge / Roll to the side", "Keep an escape route / Watch the flanks", "Dodge the volley / Use the rocks", "Bramble Broodmother / Watch, dodge, strike"]
const FINALES = [7, 6, 7, 8, 5]
const GUARDIANS = ["Clover Captain", "Pebbleback", "Briar Captain", "Goldenwing", "Bramble Broodmother"]
const ELITES = [[7,7,7], [7,6,6], [7,7,6], [7,8,8], [7,6,8]]
const POOLS = [
	[[0,0,0,9], [0,0,9,1], [0,0,9,1]],
	[[0,0,2,9], [0,2,3,9], [0,2,3,3,9]],
	[[0,1,1,9], [0,1,10,9], [0,1,1,10,11]],
	[[0,0,4,9], [0,4,4,2,10], [0,4,2,10,11]],
	[[0,1,9,10], [0,2,3,4,11], [0,1,2,3,4,9,10,11]]
]

static func active(stage: int) -> bool:
	return stage >= 1 and stage <= 5

static func pool(stage: int, seconds: float) -> Array:
	return POOLS[stage-1][mini(2, int(seconds / 60.0))]

static func spawn_pace(stage: int, seconds: float) -> float:
	# Short breathing spaces before checkpoint encounters and the finale.
	var pause = 1.7 if fmod(seconds,45.0) > 38.0 else 1.0
	return [1.45,1.3,1.2,1.15,1.1][stage-1] * pause

static func finale_health(stage: int) -> float:
	return [48.0,85.0,85.0,100.0,225.0][stage-1]

static func rock_offsets(stage: int) -> Array[Vector2]:
	match stage:
		2: return [Vector2(170,140),Vector2(430,380)]
		3: return [Vector2(130,170),Vector2(445,170),Vector2(300,460)]
		4: return [Vector2(130,170),Vector2(270,170),Vector2(430,430),Vector2(290,430)]
		5: return [Vector2(130,130),Vector2(470,130),Vector2(130,470),Vector2(470,470)]
	return []

static func update_boss(host, e: Dictionary, dt: float) -> void:
	var phase = 3 if e.hp / e.max_hp <= 0.3 else 2 if e.hp / e.max_hp <= 0.65 else 1
	if phase > e.get("phase",1):
		e.phase = phase
		e.cycle = 2 if phase == 2 else 0
		e.mode = "recover"
		e.timer = 1.5
		host.banner = "BROODMOTHER / PHASE %d" % phase
		host.banner_timer = 2.0
		host.hostile_bullets.clear()
	e.timer -= dt
	if e.mode == "windup":
		if e.timer > 0: return
		if e.attack == "lunge":
			e.mode = "rush"
			e.timer = 0.55
		else:
			if e.attack == "fan":
				for i in range(5 + phase * 2):
					var angle = -0.6 + 1.2 * i / float(4 + phase * 2)
					host.add_hostile_shot(e.p,e.aim.rotated(angle),165 + phase * 15,6)
			else:
				# The mint wedge points to a genuine escape gap in the ring.
				for i in range(16):
					var angle = TAU * i / 16.0
					if absf(wrapf(angle,-PI,PI)) < 0.5: continue
					host.add_hostile_shot(e.p,e.aim.rotated(angle),155,6)
			e.mode = "recover"
			e.timer = 1.35
		return
	if e.mode == "rush":
		var destination: Vector2 = e.p + e.aim * 360 * dt
		e.p = host.move_actor(e.p,e.aim * 360 * dt,e.radius)
		if e.timer <= 0 or e.p.distance_to(destination) > 2:
			e.mode = "recover"
			e.timer = 1.6
		return
	if e.mode == "recover":
		if e.timer <= 0:
			e.mode = "seek"
			e.timer = 1.1 if phase < 3 else 0.65
		return
	var direction: Vector2 = (host.player-e.p).normalized()
	if e.timer <= 0 and e.p.distance_to(host.player) < 340:
		var patterns = ["fan","lunge"] if phase == 1 else ["fan","lunge","ring"] if phase == 2 else ["lunge","fan","ring","lunge"]
		e.attack = patterns[e.get("cycle",0) % patterns.size()]
		e.cycle = e.get("cycle",0) + 1
		e.aim = direction
		e.mode = "windup"
		e.timer = 1.15 if e.attack == "lunge" else 1.0
		return
	host.walk_enemy(e,direction,e.speed if e.p.distance_to(host.player) < 230 else 185.0,dt)
